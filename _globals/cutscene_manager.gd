## Global Script CutsceneManager
## Interface for discovering and playing CutsceneScript nodes that exist inside the current FieldScene.
##
## Responsibilities
## 1) Cache CutsceneScript and CutsceneMarker nodes from the active field scene.
## 2) Play a cutscene by id, executing acts and actions with await based sequencing.
## 3) Temporarily lock referenced actors so their AI state machines do not fight the cutscene.
extends Node

#region Signals
signal cutscene_start(cutscene_id : StringName)
signal cutscene_end(cutscene_id : StringName)
#endregion


#region Scene references and caches
## The currently active FieldScene that owns cutscene nodes and actors.
var current_field_scene : FieldScene = null

## Direct references to scene objects.
## Lookup is done by linear scan using each node's exported id (or node name fallback).
var _cutscenes_by_id : Array[CutsceneScript] = []
var _markers_by_id : Array[CutsceneMarker] = []
#endregion


#region Execution state
## Cutscene execution gate.
## This prevents overlapping cutscenes until a future feature adds explicit queuing or cancellation.
var _is_playing : bool = false


## Set to true by an action when the remaining acts should not execute.
## Used by CutsceneChangeScene to prevent continuing to run actions that were authored
## in the previous scene.
var _abort_requested : bool = false


## Used to restore game state after cutscene ends.
var _previous_gamestate : int = GameState.State.FIELD


## Active pause mode for the currently running cutscene.
## Copied from CutsceneScript.pause_entities at play time.
var _active_pause_entities : int = CutsceneScript.PENTITIES.ALL

## Stores previous State per actor so we can restore exactly after cutscene ends.
## Each entry contains:
## 1) actor : FieldActor
## 2) sm : StateMachine
## 3) prev_state : State
var _cutscene_state_entries : Array[Dictionary] = []

## Camera rigs touched by camera actions during the current cutscene.
## Used so we can restore follow to the controlled character when the cutscene ends.
var _camera_override_entries : Array[Dictionary] = []
#endregion


#region Helper types
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


#endregion

#region Public API
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

	_abort_requested = false
	_is_playing = true
	_play_cutscene_async(cutscene_id, script)


#endregion

#region Cutscene lifecycle
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

	_active_pause_entities = int(script.pause_entities)

	_previous_gamestate = GameState.gamestate
	var did_set_cutscene_gamestate : bool = false
	if _active_pause_entities != CutsceneScript.PENTITIES.NONE:
		GameState.gamestate = GameState.State.CUTSCENE
		did_set_cutscene_gamestate = true
		SceneManager.set_field_enemies_paused(true)
	cutscene_start.emit(cutscene_id)

	_camera_override_entries.clear()
	_enter_cutscene_states(script)
	await _run_cutscene_script(script)
	_exit_cutscene_states()

	# If the cutscene was launched during dialogue, the dialogue_ended signal can fire while
	# GameState is CUTSCENE, which prevents SceneManager from restoring FIELD.
	# Yield one frame so the balloon can process its shutdown, then decide what to restore to.
	if did_set_cutscene_gamestate:
		var restore_state : int = _previous_gamestate

		if _previous_gamestate == GameState.State.DIALOGUE:
			# DialogueManager.dialogue_ended can emit before the balloon applies the null line and queues itself.
			# One frame gives the balloon time to close.
			await get_tree().process_frame

			if DM.has_active_balloon():
				restore_state = GameState.State.DIALOGUE
			else:
				restore_state = GameState.State.FIELD

		if GameState.gamestate == GameState.State.CUTSCENE:
			GameState.gamestate = restore_state
			
		if GameState.gamestate == GameState.State.FIELD:
			SceneManager.set_field_enemies_paused(false)
		elif GameState.gamestate == GameState.State.DIALOGUE:
			SceneManager.set_field_enemies_paused(true)
			
	await _restore_camera_overrides_async()
	cutscene_end.emit(cutscene_id)
	_finish_cutscene()

## Clears the playing gate so future cutscenes can run.
func _finish_cutscene() -> void:
	_is_playing = false
	_abort_requested = false
	_active_pause_entities = CutsceneScript.PENTITIES.ALL

#endregion

#region Discovery and caching
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


#endregion

#region Id helpers and lookups
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


#endregion

#region Script execution
## Executes a CutsceneScript by running each CutsceneAct in order.
func _run_cutscene_script(script : CutsceneScript) -> void:
	for act in script.acts:
		if _abort_requested:
			return
		if act == null:
			continue
		await _run_act(act)

## Executes a CutsceneAct.
## If the act is SEQUENCE, actions are awaited one by one.
## Otherwise, actions are launched and awaited as a group.
func _run_act(act : CutsceneAct) -> void:
	if act.playtype == CutsceneAct.Playtype.SEQUENCE:
		for action in act.cutscene_actions:
			if _abort_requested:
				return
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

	# CutsceneChangeScene is not compatible with true parallel execution because it can
	# destroy the currently running scene while other actions are still executing.
	# Treat any parallel act that contains it as a sequence.
	var contains_change_scene : bool = false
	for a in valid:
		if a is CutsceneChangeScene:
			contains_change_scene = true
			break

	if contains_change_scene:
		push_warning("CutsceneManager: CutsceneChangeScene in PARALLEL act treated as SEQUENCE")
		for a in valid:
			if _abort_requested:
				return
			await _run_action(a)
		return

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


#endregion

#region Action dispatch
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
	
	if action is CutsceneCameraFollow:
		await _run_camera_follow(action)
		return
		
	if action is CutsceneChangeScene:
		await _run_change_scene(action)
		return
		
	if action is CutsceneQueueFree:
		await _run_queue_free(action)
		return
		
	if action is CutsceneInstantiate:
		await _run_instantiate(action)
		return
		
		
	push_warning("CutsceneManager: action class missing implementation: " + action.get_class())
	## Executes a CutsceneActorMove.
## 1) Resolve actor (controlled character if requested, otherwise by field_actor_id)
## 2) Resolve each marker id into a CutsceneMarker
## 3) Move actor to each marker in order
#endregion

#region Action handlers: Actor move
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

#endregion

#region Action handlers: Dialogue
func _run_dialogue(action : CutsceneDialogue) -> void:
	if action.dialogue_resource == null:
		push_error("CutsceneManager: CutsceneDialogue dialogue_resource is null")
		return

	var start_title : String = action.dialogue_start
	if start_title.is_empty():
		start_title = "start"

	DM.show_dialogue(action.dialogue_resource, start_title)

	while true:
		var ended_resource : Resource = await DM.dialogue_session_ended
		if ended_resource == action.dialogue_resource:
			break
#endregion

#region Action handlers: Scene and spawning
func _run_change_scene(action : CutsceneChangeScene) -> void:
	if action.scene_to_load.is_empty():
		push_error("CutsceneManager: CutsceneChangeScene scene_to_load is empty")
		return
	if action.target_transition_area.is_empty():
		push_error("CutsceneManager: CutsceneChangeScene target_transition_area is empty")
		return
	if SceneManager.main_scene == null:
		push_error("CutsceneManager: CutsceneChangeScene cannot run because SceneManager.main_scene is null")
		return
	if SceneManager.is_loading_field_scene:
		push_error("CutsceneManager: CutsceneChangeScene cannot run because a field scene load is already in progress")
		return

	# If this cutscene was triggered from dialogue, close the balloon so GameState can
	# restore to FIELD after the scene load.
	DM.force_cleanup_dialogue_session()

	# Restore camera rig properties before the scene load so we do not carry cutscene
	# overrides into the new field scene.
	_restore_camera_overrides_async()

	# Scene change ends the current cutscene script.
	_abort_requested = true

	# The leaving scene is about to be freed, so there is no actor state to restore.
	_cutscene_state_entries.clear()

	# Most authored transitions center the spawn; keep entry offset at zero.
	SceneManager.transition_entry_offset = Vector2.ZERO

	await SceneManager.load_field_scene(action.scene_to_load, action.target_transition_area)

	# If we force closed dialogue, the dialogue_ended signal will not fire.
	# Ensure enemy pause state is not left enabled after the scene load.
	SceneManager.set_field_enemies_paused(false)

func _run_instantiate(action : CutsceneInstantiate) -> void:
	if action.instantiated_scene == null:
		push_error("CutsceneManager: CutsceneInstantiate instantiated_scene is null")
		return
	if action.instantiate_location_ids.is_empty():
		push_warning("CutsceneManager: CutsceneInstantiate has no instantiate_location_ids")
		return
	if current_field_scene == null:
		push_error("CutsceneManager: CutsceneInstantiate cannot run because current_field_scene is null")
		return

	var parent : Node = _resolve_instantiate_parent(action.type)
	if parent == null:
		push_error("CutsceneManager: CutsceneInstantiate could not resolve a parent for type")
		return

	# CutsceneArea triggers can arrive during physics query flushing.
	# Defer spawning to the next frame so physics state changes do not error.
	await get_tree().process_frame

	var spawned_actors : Array[FieldActor] = []

	if action.target_id != &"" and action.instantiate_location_ids.size() > 1:
		push_warning("CutsceneManager: CutsceneInstantiate will set the same target_id on multiple instances")

	for marker_id in action.instantiate_location_ids:
		var marker : CutsceneMarker = _find_marker(marker_id)
		if marker == null:
			push_error("CutsceneManager: marker id missing in scene: " + String(marker_id))
			continue

		var inst = action.instantiated_scene.instantiate()
		if inst == null:
			push_error("CutsceneManager: CutsceneInstantiate failed to instantiate scene")
			continue

		_apply_instantiated_id(action, inst)
		parent.add_child(inst)

		if inst is Node2D:
			var n2d : Node2D = inst
			n2d.global_position = marker.global_position
		else:
			push_error("CutsceneManager: CutsceneInstantiate instance root is not Node2D")

		if action.type == CutsceneInstantiate.TYPE.ACTOR:
			if inst is FieldActor:
				var fa : FieldActor = inst
				spawned_actors.append(fa)

	# Give spawned actors one frame to initialize their StateMachine before forcing CutScene.
	var should_force_spawned : bool = false

	if _active_pause_entities == CutsceneScript.PENTITIES.ALL:
		should_force_spawned = true
	elif _active_pause_entities == CutsceneScript.PENTITIES.PLAYER:
		# PLAYER mode pauses the controlled character and cutscene referenced actors.
		# For freshly spawned actors, treat them as referenced only when they get an id.
		if action.type == CutsceneInstantiate.TYPE.ACTOR:
			if action.target_id != &"":
				should_force_spawned = true

	if spawned_actors.size() > 0 and should_force_spawned:
		await get_tree().process_frame
		for fa in spawned_actors:
			if is_instance_valid(fa):
				_enter_cutscene_state_for_actor(fa)

func _resolve_instantiate_parent(t : int) -> Node:
	if current_field_scene == null:
		return null

	if t == CutsceneInstantiate.TYPE.ACTOR:
		if current_field_scene.field_actors != null:
			return current_field_scene.field_actors
		return current_field_scene

	if t == CutsceneInstantiate.TYPE.OBJECT:
		if current_field_scene.interactables != null:
			return current_field_scene.interactables
		return current_field_scene

	if t == CutsceneInstantiate.TYPE.VFX:
		if SceneManager.main_scene != null:
			if SceneManager.main_scene.field_vfx != null:
				return SceneManager.main_scene.field_vfx
		return current_field_scene

	return current_field_scene


func _apply_instantiated_id(action : CutsceneInstantiate, inst : Object) -> void:
	if action.target_id == &"":
		return

	if action.type == CutsceneInstantiate.TYPE.VFX:
		return

	# ACTOR: primary contract in this project is FieldActor.field_actor_id
	if action.type == CutsceneInstantiate.TYPE.ACTOR:
		if inst is FieldActor:
			var fa : FieldActor = inst
			fa.field_actor_id = action.target_id
			return

		# Fallbacks for actor scenes that expose a different id property.
		if _set_property_if_present(inst, &"actor_id", action.target_id):
			return
		_set_property_if_present(inst, &"field_actor_id", action.target_id)
		return

	# OBJECT: set object_id when present
	if action.type == CutsceneInstantiate.TYPE.OBJECT:
		if _set_property_if_present(inst, &"object_id", action.target_id):
			return
		_set_property_if_present(inst, &"field_object_id", action.target_id)
		return


func _set_property_if_present(obj : Object, prop_name : StringName, value : Variant) -> bool:
	for p in obj.get_property_list():
		if StringName(p.name) == prop_name:
			obj.set(prop_name, value)
			return true
	return false
func _run_queue_free(action : CutsceneQueueFree) -> void:
	var target_id : StringName = action.target_id
	if target_id == &"":
		push_error("CutsceneManager: CutsceneQueueFree target_id is empty")
		return

	var actor : FieldActor = _find_field_actor(target_id)
	if actor == null:
		push_error("CutsceneManager: CutsceneQueueFree actor id missing in scene: " + String(target_id))
		return

	_remove_cutscene_state_entry_for_actor(actor)

	actor.call_deferred("queue_free")
	await get_tree().process_frame

#endregion

#region Actor movement helpers
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


func _collect_all_field_actors() -> Array[FieldActor]:
	var actors : Array[FieldActor] = []
	if current_field_scene == null:
		return actors

	var stack : Array[Node] = [current_field_scene]
	while stack.size() > 0:
		var n : Node = stack.pop_back()

		if n is FieldActor:
			actors.append(n)

		for child in n.get_children():
			stack.append(child)

	return actors



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

			if action is CutsceneQueueFree:
				var qf : CutsceneQueueFree = action
				var qid : StringName = qf.target_id
				if qid == &"":
					continue
				if not ids.has(qid):
					ids.append(qid)

	return ids
	
#endregion

#region CutScene state forcing
func _enter_cutscene_states(script : CutsceneScript) -> void:
	_cutscene_state_entries.clear()

	# NONE: do not force any actor into CutsceneState.
	if int(script.pause_entities) == CutsceneScript.PENTITIES.NONE:
		return

	# PLAYER: pause the controlled character and any actors explicitly referenced by this cutscene's actions.
	if int(script.pause_entities) == CutsceneScript.PENTITIES.PLAYER:
		if CharDataKeeper.controlled_character != null:
			var controlled_only : FieldActor = CharDataKeeper.controlled_character
			if is_instance_valid(controlled_only):
				_enter_cutscene_state_for_actor(controlled_only)

		var ids_player : Array[StringName] = _collect_actor_ids(script)
		for id in ids_player:
			var actor_p : FieldActor = _find_field_actor(id)
			if actor_p == null:
				continue
			_enter_cutscene_state_for_actor(actor_p)

		return

	# ALL: pause every FieldActor in the current FieldScene.
	for actor_all in _collect_all_field_actors():
		_enter_cutscene_state_for_actor(actor_all)

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
		var sm = entry.get("sm")
		var prev = entry.get("prev_state")
		var actor = entry.get("actor")

		# Scene changes or CutsceneQueueFree can free these nodes.
		if sm != null and prev != null:
			if is_instance_valid(sm) and is_instance_valid(prev):
				sm.change_state(prev)

		if actor != null:
			if is_instance_valid(actor):
				actor.velocity = Vector2.ZERO

	_cutscene_state_entries.clear()

#endregion

#region Dialogue helpers
func _has_active_dialogue_balloon() -> bool:
	var balloon : Node = DM.active_balloon
	if balloon == null:
		return false
	if not is_instance_valid(balloon):
		return false
	if balloon.is_queued_for_deletion():
		return false
	return true

#endregion

#region Action handlers: Camera
func _run_camera_move(action : CutsceneCameraMove) -> void:
	var rig : Node2D = _resolve_camera_rig(action.camera_rig_id)
	if rig == null:
		push_error("CutsceneManager: camera rig missing: " + String(action.camera_rig_id))
		return

	if action.move_location_ids.is_empty():
		push_warning("CutsceneManager: CutsceneCameraMove has no move_location_ids")
		return

	_begin_camera_override_for_rig(rig)

	for marker_id in action.move_location_ids:
		var marker : CutsceneMarker = _find_marker(marker_id)
		if marker == null:
			push_error("CutsceneManager: marker id missing in scene: " + String(marker_id))
			continue

		await _move_camera_rig_to(rig, marker.global_position, action)
		
func _run_camera_follow(action : CutsceneCameraFollow) -> void:
	var rig : Node2D = _resolve_camera_rig(action.camera_rig_id)
	if rig == null:
		push_error("CutsceneManager: camera rig missing: " + String(action.camera_rig_id))
		return

	var target : Node2D = null

	if action.follow_controlled_character:
		var player : FieldActor = CharDataKeeper.controlled_character
		if player == null:
			push_error("CutsceneManager: CutsceneCameraFollow follow_controlled_character is true, but controlled_character is null")
			return
		if not is_instance_valid(player):
			push_error("CutsceneManager: CutsceneCameraFollow follow_controlled_character is true, but controlled_character is an invalid instance")
			return
		target = player
	else:
		if action.actor_id == &"":
			push_error("CutsceneManager: CutsceneCameraFollow actor_id is empty")
			return
		target = _find_field_actor(action.actor_id)
		if target == null:
			push_error("CutsceneManager: actor id missing in scene: " + String(action.actor_id))
			return

	var entry : Dictionary = _begin_camera_override_for_rig(rig)
	entry["persist_follow_settings"] = action.persist_follow_settings

	if rig is FieldCameraRig:
		var fr : FieldCameraRig = rig

		if action.override_follow_settings:
			fr.follow_speed = action.follow_speed
			fr.snap = action.snap

		if action.do_transition_to_target:
			fr.clear_target()
			fr.activate()

			var tmp : CutsceneCameraMove = CutsceneCameraMove.new()
			tmp.path_type = int(action.path_type)
			tmp.transition_type = action.transition_type
			tmp.easing_method = action.easing_method
			tmp.move_speed = action.move_speed

			await _move_camera_rig_to(fr, target.global_position, tmp)

		fr.activate()
		fr.set_target(target, action.snap_on_follow_start)
		return

	if action.do_transition_to_target:
		var tmp_generic : CutsceneCameraMove = CutsceneCameraMove.new()
		tmp_generic.path_type = int(action.path_type)
		tmp_generic.transition_type = action.transition_type
		tmp_generic.easing_method = action.easing_method
		tmp_generic.move_speed = action.move_speed
		await _move_camera_rig_to(rig, target.global_position, tmp_generic)

	if rig.has_method("set_target"):
		rig.call("set_target", target, action.snap_on_follow_start)


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

			var persist_settings : bool = false
			if entry.has("persist_follow_settings"):
				persist_settings = entry["persist_follow_settings"]

			if not persist_settings:
				if entry.has("prev_follow_speed"):
					fr.follow_speed = entry["prev_follow_speed"]
				if entry.has("prev_snap"):
					fr.snap = entry["prev_snap"]

			# No follow_player call here.

		if entry.has("process_mode"):
			rig.process_mode = entry["process_mode"]

	_camera_override_entries.clear()


#endregion

#region Action handlers: Timing
func _run_wait(action : CutsceneWait) -> void:
	var t : float = action.wait_time

	# Data validity: negative values behave like a one frame yield.
	if t <= 0.0:
		await get_tree().process_frame
		return

	# process_always = true so the timer still advances even if the tree is paused elsewhere.
	var timer = get_tree().create_timer(t, true)
	await timer.timeout
	
	
#endregion

#region Cleanup helpers
func _remove_cutscene_state_entry_for_actor(actor : FieldActor) -> void:
	for i in range(_cutscene_state_entries.size() - 1, -1, -1):
		var e : Dictionary = _cutscene_state_entries[i]
		if e.get("actor") == actor:
			_cutscene_state_entries.remove_at(i)
			return
#endregion
