## Global Script CutsceneManager
## Interface for discovering and playing CutsceneScript nodes that exist inside the current FieldScene.
##
## Responsibilities
## 1) Cache CutsceneScript and CutsceneMarker nodes from the active field scene.
## 2) Play a cutscene by id, executing acts and actions with await based sequencing.
## 3) Temporarily lock referenced actors so their AI state machines do not fight the cutscene.
extends Node

signal cutscene_start(cutscene_id : StringName)
signal cutscene_end(cutscene_id : StringName)

## The currently active FieldScene that owns cutscene nodes and actors.
var current_field_scene : FieldScene = null

## Direct references to scene objects.
## Lookup is done by linear scan using each node's exported id (or node name fallback).
var _cutscenes_by_id : Array[CutsceneScript] = []
var _markers_by_id : Array[CutsceneMarker] = []

## Cutscene execution gate.
## This prevents overlapping cutscenes until a future feature adds explicit queuing or cancellation.
var _is_playing : bool = false

## Used to restore game state after cutscene ends.
var _previous_gamestate : int = GameState.State.FIELD

## Stores previous State per actor so we can restore exactly after cutscene ends.
## Each entry contains:
## 1) actor : FieldActor
## 2) sm : StateMachine
## 3) prev_state : State
var _cutscene_state_entries : Array[Dictionary] = []

## Camera rigs touched by camera actions during the current cutscene.
## Used so we can restore follow to the controlled character when the cutscene ends.
var _camera_override_entries : Array[Dictionary] = []

## Small helper used to await completion of parallel actions.
## Each parallel action decrements the counter when done, and the manager awaits all_done.
class ParallelCounter:
	extends RefCounted
	signal all_done
	var remaining : int = 0

	## Initialize the counter to the number of tasks that must finish.
	func start(count : int) -> void:
		remaining = count
		if remaining <= 0:
			all_done.emit()

	## Mark one task as complete.
	func done_one() -> void:
		remaining -= 1
		if remaining <= 0:
			all_done.emit()


## Called by SceneManager when a FieldScene becomes active.
## This is the point where the manager discovers CutsceneScript and CutsceneMarker nodes.
func register_field_scene(fscene : FieldScene) -> void:
	current_field_scene = fscene
	_cutscenes_by_id.clear()
	_markers_by_id.clear()

	if current_field_scene == null:
		return

	_cache_cutscene_scripts()
	_cache_cutscene_markers()


## Public entry point used by triggers such as CutsceneArea and dialogue.
## Validates scene registration, finds the script by id, then starts async execution.
func play_cutscene(cutscene_id : StringName) -> void:
	if _is_playing:
		return
	if current_field_scene == null:
		return

	var script : CutsceneScript = _find_cutscene_script(cutscene_id)
	if script == null:
		push_error("CutsceneManager: cutscene id missing in scene: " + String(cutscene_id))
		return

	_is_playing = true
	_play_cutscene_async(cutscene_id, script)


## Runs the cutscene lifecycle.
## 1) One shot gate
## 2) Switch GameState to CUTSCENE
## 3) Lock referenced actors
## 4) Execute all acts
## 5) Unlock actors and restore GameState
func _play_cutscene_async(cutscene_id : StringName, script : CutsceneScript) -> void:
	if script.one_shot:
		if script.has_been_played:
			_finish_cutscene()
			return

	script.has_been_played = true

	_previous_gamestate = GameState.gamestate
	GameState.gamestate = GameState.State.CUTSCENE
	cutscene_start.emit(cutscene_id)

	_camera_override_entries.clear()
	_enter_cutscene_states(script)
	await _run_cutscene_script(script)
	_exit_cutscene_states()


	# If the cutscene was launched during dialogue, the dialogue_ended signal can fire while
	# GameState is CUTSCENE, which prevents SceneManager from restoring FIELD.
	# Yield one frame so the balloon can process its shutdown, then decide what to restore to.
	var restore_state : int = _previous_gamestate

	if _previous_gamestate == GameState.State.DIALOGUE:
		# DialogueManager.dialogue_ended can emit before the balloon applies the null line and queues itself.
		# One frame gives the balloon time to close.
		await get_tree().process_frame

		if _has_active_dialogue_balloon():
			restore_state = GameState.State.DIALOGUE
		else:
			restore_state = GameState.State.FIELD

	if GameState.gamestate == GameState.State.CUTSCENE:
		GameState.gamestate = restore_state
	await _restore_camera_overrides_async()
	cutscene_end.emit(cutscene_id)
	_finish_cutscene()

## Clears the playing gate so future cutscenes can run.
func _finish_cutscene() -> void:
	_is_playing = false


## Walks the current field scene tree and caches any CutsceneScript nodes found.
## Duplicate ids are treated as authoring errors and reported.
func _cache_cutscene_scripts() -> void:
	var stack : Array[Node] = [current_field_scene]

	while stack.size() > 0:
		var n : Node = stack.pop_back()

		if n is CutsceneScript:
			var cs : CutsceneScript = n
			var id : StringName = _get_cutscene_id(cs)

			if _has_cutscene_id(id):
				push_error("CutsceneManager: duplicate cutscene id: " + String(id))
			else:
				_cutscenes_by_id.append(cs)

		for child in n.get_children():
			stack.append(child)


## Walks the current field scene tree and caches any CutsceneMarker nodes found.
## Duplicate ids are treated as authoring errors and reported.
func _cache_cutscene_markers() -> void:
	var stack : Array[Node] = [current_field_scene]

	while stack.size() > 0:
		var n : Node = stack.pop_back()

		if n is CutsceneMarker:
			var m : CutsceneMarker = n
			var id : StringName = _get_marker_id(m)

			if _has_marker_id(id):
				push_error("CutsceneManager: duplicate marker id: " + String(id))
			else:
				_markers_by_id.append(m)

		for child in n.get_children():
			stack.append(child)


## Returns the cutscene id used for lookups.
## Uses the exported cutscene_id when set, otherwise falls back to the node name.
func _get_cutscene_id(cs : CutsceneScript) -> StringName:
	var id : StringName = cs.cutscene_id
	if id == &"":
		id = StringName(cs.name)
	return id


## Returns the marker id used for lookups.
## Uses the exported marker_id when set, otherwise falls back to the node name.
func _get_marker_id(m : CutsceneMarker) -> StringName:
	var id : StringName = m.marker_id
	if id == &"":
		id = StringName(m.name)
	return id


## Checks whether a cutscene id is already present in the cached array.
## Used during caching to detect duplicates.
func _has_cutscene_id(cutscene_id : StringName) -> bool:
	for cs in _cutscenes_by_id:
		if _get_cutscene_id(cs) == cutscene_id:
			return true
	return false


## Checks whether a marker id is already present in the cached array.
## Used during caching to detect duplicates.
func _has_marker_id(marker_id : StringName) -> bool:
	for m in _markers_by_id:
		if _get_marker_id(m) == marker_id:
			return true
	return false


## Finds a CutsceneScript by id via linear scan.
## This is used at runtime when a trigger asks to play a cutscene.
func _find_cutscene_script(cutscene_id : StringName) -> CutsceneScript:
	for cs in _cutscenes_by_id:
		if _get_cutscene_id(cs) == cutscene_id:
			return cs
	return null


## Finds a CutsceneMarker by id via linear scan.
## This is used by actions such as CutsceneActorMove to resolve target locations.
func _find_marker(marker_id : StringName) -> CutsceneMarker:
	for m in _markers_by_id:
		if _get_marker_id(m) == marker_id:
			return m
	return null


## Executes a CutsceneScript by running each CutsceneAct in order.
func _run_cutscene_script(script : CutsceneScript) -> void:
	for act in script.acts:
		if act == null:
			continue
		await _run_act(act)


## Executes a CutsceneAct.
## If the act is SEQUENCE, actions are awaited one by one.
## Otherwise, actions are launched and awaited as a group.
func _run_act(act : CutsceneAct) -> void:
	if act.playtype == CutsceneAct.Playtype.SEQUENCE:
		for action in act.cutscene_actions:
			if action == null:
				continue
			await _run_action(action)
		return

	await _run_actions_parallel(act.cutscene_actions)


## Runs a set of actions in parallel and awaits completion of all of them.
## Each action is executed in its own async flow and signals the counter on completion.
func _run_actions_parallel(actions : Array[CutsceneAction]) -> void:
	var valid : Array[CutsceneAction] = []
	for a in actions:
		if a != null:
			valid.append(a)

	var counter : ParallelCounter = ParallelCounter.new()
	counter.start(valid.size())

	for a in valid:
		_run_action_and_notify(a, counter)

	await counter.all_done


## Helper wrapper used by parallel execution.
## Awaits a single action, then decrements the counter.
func _run_action_and_notify(action : CutsceneAction, counter : ParallelCounter) -> void:
	await _run_action(action)
	counter.done_one()


## Dispatches a CutsceneAction to a concrete handler based on its class.
func _run_action(action : CutsceneAction) -> void:
	if action is CutsceneActorMove:
		await _run_actor_move(action)
		return

	if action is CutsceneCameraMove:
		await _run_camera_move(action)
		return

	if action is CutsceneDialogue:
		await _run_dialogue(action)
		return

	if action is CutsceneWait:
		await _run_wait(action)
		return

	push_warning("CutsceneManager: action class missing implementation: " + action.get_class())
	## Executes a CutsceneActorMove.
## 1) Resolve actor (controlled character if requested, otherwise by field_actor_id)
## 2) Resolve each marker id into a CutsceneMarker
## 3) Move actor to each marker in order
func _run_actor_move(action : CutsceneActorMove) -> void:
	var actor : FieldActor = null

	if action.move_controlled_character:
		if CharDataKeeper.controlled_character == null:
			push_error("CutsceneManager: CutsceneActorMove move_controlled_character is true, but controlled_character is null")
			return
		if not is_instance_valid(CharDataKeeper.controlled_character):
			push_error("CutsceneManager: CutsceneActorMove move_controlled_character is true, but controlled_character is an invalid instance")
			return

		actor = CharDataKeeper.controlled_character
	else:
		var actor_id_sn : StringName = StringName(action.actor_id)
		if actor_id_sn == &"":
			push_error("CutsceneManager: CutsceneActorMove actor_id is empty")
			return

		actor = _find_field_actor(actor_id_sn)
		if actor == null:
			push_error("CutsceneManager: actor id missing in scene: " + String(actor_id_sn))
			return

	for marker_id in action.move_location_ids:
		var marker : CutsceneMarker = _find_marker(marker_id)
		if marker == null:
			push_error("CutsceneManager: marker id missing in scene: " + String(marker_id))
			continue

		await _move_actor_to(actor, marker.global_position, action)

func _run_dialogue(action : CutsceneDialogue) -> void:
	if action.dialogue_resource == null:
		push_error("CutsceneManager: CutsceneDialogue dialogue_resource is null")
		return

	var start_title : String = action.dialogue_start
	if start_title.is_empty():
		start_title = "start"

	DialogueManager._set_resources(action.speakers.duplicate())
	DialogueManager.show_dialogue_balloon(action.dialogue_resource, start_title)

	while true:
		var ended_resource : Resource = await DialogueManager.dialogue_ended
		if ended_resource == action.dialogue_resource:
			break

## Moves an actor to a target position.
## INSTANT updates position immediately.
## Other path types currently use a simple tween based on move_speed.
func _move_actor_to(actor : FieldActor, target_pos : Vector2, action : CutsceneActorMove) -> void:
	actor.force_face_direction(target_pos - actor.global_position)
	actor.velocity = Vector2.ZERO

	if action.path_type == CutsceneActorMove.PathType.INSTANT:
		actor.global_position = target_pos
		await get_tree().process_frame
		return

	var speed : float = action.move_speed
	if speed <= 0.0:
		actor.global_position = target_pos
		await get_tree().process_frame
		return

	var dist : float = actor.global_position.distance_to(target_pos)
	var duration : float = dist / speed

	if duration <= 0.0:
		actor.global_position = target_pos
		await get_tree().process_frame
		return

	var tween : Tween = get_tree().create_tween()
	tween.tween_property(actor, "global_position", target_pos, duration)
	await tween.finished


## Finds a FieldActor by its field_actor_id by scanning the scene tree.
## This keeps authoring simple because actors do not have to be pre registered.
func _find_field_actor(actor_id : StringName) -> FieldActor:
	if current_field_scene == null:
		return null

	var stack : Array[Node] = [current_field_scene]
	while stack.size() > 0:
		var n : Node = stack.pop_back()

		if n is FieldActor:
			var a : FieldActor = n
			if a.field_actor_id == actor_id:
				return a

		for child in n.get_children():
			stack.append(child)

	return null




## Collects a unique list of actor ids that appear in actions within this cutscene.
## This is used so only referenced actors are locked.
func _collect_actor_ids(script : CutsceneScript) -> Array[StringName]:
	var ids : Array[StringName] = []

	for act in script.acts:
		if act == null:
			continue
		for action in act.cutscene_actions:
			if action is CutsceneActorMove:
				var move : CutsceneActorMove = action

				if move.move_controlled_character:
					continue

				var id : StringName = StringName(move.actor_id)
				if id == &"":
					continue
				if not ids.has(id):
					ids.append(id)

	return ids

func _enter_cutscene_states(script : CutsceneScript) -> void:
	_cutscene_state_entries.clear()

	var ids : Array[StringName] = _collect_actor_ids(script)

	## Always suppress manual input for the controlled party member during cutscenes.
	if CharDataKeeper.controlled_character != null:
		var controlled : FieldActor = CharDataKeeper.controlled_character
		var cid : StringName = controlled.field_actor_id
		if cid != &"" and not ids.has(cid):
			ids.append(cid)

	for id in ids:
		var actor : FieldActor = _find_field_actor(id)
		if actor == null:
			continue
		_enter_cutscene_state_for_actor(actor)


func _enter_cutscene_state_for_actor(actor : FieldActor) -> void:
	for entry in _cutscene_state_entries:
		if entry["actor"] == actor:
			return

	var sm : StateMachine = actor.get_node_or_null("StateMachine") as StateMachine
	if sm == null:
		push_error("CutsceneManager: actor missing StateMachine: " + String(actor.field_actor_id))
		return

	var prev : State = sm.current_state
	if prev == null:
		push_error("CutsceneManager: StateMachine has no current_state: " + String(actor.field_actor_id))
		return

	actor.velocity = Vector2.ZERO
	sm.force_state_by_name("CutScene")

	var entry : Dictionary = {}
	entry["actor"] = actor
	entry["sm"] = sm
	entry["prev_state"] = prev
	_cutscene_state_entries.append(entry)


func _exit_cutscene_states() -> void:
	for entry in _cutscene_state_entries:
		var sm : StateMachine = entry["sm"]
		var prev : State = entry["prev_state"]
		var actor : FieldActor = entry["actor"]

		if sm != null and prev != null:
			sm.change_state(prev)

		if actor != null:
			actor.velocity = Vector2.ZERO

	_cutscene_state_entries.clear()


func _has_active_dialogue_balloon() -> bool:
	var scene = DialogueManager.get_current_scene.call()
	if scene == null:
		return false

	var stack : Array[Node] = [scene]
	while stack.size() > 0:
		var n : Node = stack.pop_back()

		if n is DialogBalloon:
			if not n.is_queued_for_deletion():
				return true

		for child in n.get_children():
			stack.append(child)

	return false

func _run_camera_move(action : CutsceneCameraMove) -> void:
	var rig : Node2D = _resolve_camera_rig(action.camera_rig_id)
	if rig == null:
		push_error("CutsceneManager: camera rig missing: " + String(action.camera_rig_id))
		return

	if action.move_location_ids.is_empty():
		push_warning("CutsceneManager: CutsceneCameraMove has no move_location_ids")
		return

	var entry : Dictionary = _begin_camera_override_for_rig(rig)

	# The last camera move action that runs for this rig decides the cutscene end behavior.
	entry["smooth_return_to_player"] = action.smooth_return_to_player
	if action.smooth_return_to_player:
		entry["return_path_type"] = action.path_type
		entry["return_transition_type"] = action.transition_type
		entry["return_easing_method"] = action.easing_method
		entry["return_move_speed"] = action.move_speed

	for marker_id in action.move_location_ids:
		var marker : CutsceneMarker = _find_marker(marker_id)
		if marker == null:
			push_error("CutsceneManager: marker id missing in scene: " + String(marker_id))
			continue

		await _move_camera_rig_to(rig, marker.global_position, action)


func _move_camera_rig_to(rig : Node2D, target_pos : Vector2, action : CutsceneCameraMove) -> void:
	if action.path_type == CutsceneCameraMove.PathType.INSTANT:
		rig.global_position = target_pos
		await get_tree().process_frame
		return

	if action.path_type == CutsceneCameraMove.PathType.NAVIGATION:
		# Camera navigation is not implemented yet.
		# For now, treat it as straight line so authoring does not break.
		push_warning("CutsceneManager: CutsceneCameraMove NAVIGATION treated as STRAIGHT_LINE")

	var speed : float = action.move_speed
	if speed <= 0.0:
		rig.global_position = target_pos
		await get_tree().process_frame
		return

	var dist : float = rig.global_position.distance_to(target_pos)
	var duration : float = dist / speed

	if duration <= 0.0:
		rig.global_position = target_pos
		await get_tree().process_frame
		return

	var tween : Tween = get_tree().create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(action.transition_type)
	tween.set_ease(action.easing_method)
	tween.tween_property(rig, "global_position", target_pos, duration)
	await tween.finished


func _resolve_camera_rig(rig_id : StringName) -> Node2D:
	if SceneManager.main_scene == null:
		return null

	# Common default path
	if rig_id == &"" or rig_id == &"FieldCameraRig":
		return SceneManager.main_scene.field_camera_rig

	# Primary lookup by node name inside Main
	var found : Node = SceneManager.main_scene.find_child(String(rig_id), true, false)
	if found is Node2D:
		return found

	# Secondary lookup by camera_rig_id property (future proofing)
	var stack : Array[Node] = [SceneManager.main_scene]
	while stack.size() > 0:
		var n : Node = stack.pop_back()
		if n is Node2D:
			if n.has_method("get"):
				# Safe property probe pattern: only check if the property exists in the list
				for p in n.get_property_list():
					if p.name == "camera_rig_id":
						var v = n.get("camera_rig_id")
						if v is StringName and v == rig_id:
							return n
						break

		for child in n.get_children():
			stack.append(child)

	return null

func _begin_camera_override_for_rig(rig : Node2D) -> Dictionary:
	# Avoid duplicate entries per cutscene
	for entry in _camera_override_entries:
		if entry["rig"] == rig:
			# Ensure follow remains suppressed if a later action runs
			if rig is FieldCameraRig:
				var fr : FieldCameraRig = rig
				fr.clear_target()
				fr.activate()
			return entry

	var entry : Dictionary = {}
	entry["rig"] = rig
	entry["process_mode"] = rig.process_mode

	# FieldCameraRig supports explicit follow suppression and restoration.
	if rig is FieldCameraRig:
		var fr : FieldCameraRig = rig
		entry["prev_follow_speed"] = fr.follow_speed
		entry["prev_snap"] = fr.snap
		fr.clear_target()
		fr.activate()

	# Ensure the rig keeps updating even if something else is disabling processing.
	rig.process_mode = Node.PROCESS_MODE_ALWAYS

	_camera_override_entries.append(entry)
	return entry
func _restore_camera_overrides_async() -> void:
	if _camera_override_entries.is_empty():
		return

	for entry in _camera_override_entries:
		var rig = entry["rig"]
		if not is_instance_valid(rig):
			continue

		if rig is FieldCameraRig:
			var fr : FieldCameraRig = rig

			var prev_follow_speed : float = fr.follow_speed
			var prev_snap : bool = fr.snap

			if entry.has("prev_follow_speed"):
				prev_follow_speed = entry["prev_follow_speed"]
			if entry.has("prev_snap"):
				prev_snap = entry["prev_snap"]

			var do_smooth_return : bool = false
			if entry.has("smooth_return_to_player"):
				do_smooth_return = entry["smooth_return_to_player"]

			if do_smooth_return:
				var player : FieldActor = CharDataKeeper.controlled_character
				if player != null:
					fr.clear_target()
					fr.activate()

					var tmp : CutsceneCameraMove = CutsceneCameraMove.new()
					if entry.has("return_path_type"):
						tmp.path_type = entry["return_path_type"]
					if entry.has("return_transition_type"):
						tmp.transition_type = entry["return_transition_type"]
					if entry.has("return_easing_method"):
						tmp.easing_method = entry["return_easing_method"]
					if entry.has("return_move_speed"):
						tmp.move_speed = entry["return_move_speed"]

					await _move_camera_rig_to(fr, player.global_position, tmp)

			# Restore rig settings and resume follow.
			fr.follow_speed = prev_follow_speed
			fr.snap = prev_snap

			# Snap is fine here because we are already at the player position after the tween.
			fr.follow_player(true)

		# Restore process mode after all camera work is done for this entry.
		if entry.has("process_mode"):
			rig.process_mode = entry["process_mode"]

	_camera_override_entries.clear()


func _run_wait(action : CutsceneWait) -> void:
	var t : float = action.wait_time

	# Data validity: negative values behave like a one frame yield.
	if t <= 0.0:
		await get_tree().process_frame
		return

	# process_always = true so the timer still advances even if the tree is paused elsewhere.
	var timer := get_tree().create_timer(t, true)
	await timer.timeout
