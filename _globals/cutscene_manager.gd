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

## Stores temporary lock information per actor.
## Each entry contains:
## 1) actor : FieldActor
## 2) sm : Node (optional, the StateMachine node if present)
## 3) sm_mode : int (optional, previous process_mode)
var _locked_entries : Array[Dictionary] = []


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

	_lock_actors_referenced_by_cutscene(script)
	await _run_cutscene_script(script)
	_unlock_actors()

	if GameState.gamestate == GameState.State.CUTSCENE:
		GameState.gamestate = _previous_gamestate

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
## Add more branches here as additional CutsceneAction types are introduced.
func _run_action(action : CutsceneAction) -> void:
	if action is CutsceneActorMove:
		await _run_actor_move(action)
		return

	push_warning("CutsceneManager: action class missing implementation: " + action.get_class())


## Executes a CutsceneActorMove.
## 1) Resolve actor by field_actor_id
## 2) Resolve each marker id into a CutsceneMarker
## 3) Move actor to each marker in order
func _run_actor_move(action : CutsceneActorMove) -> void:
	var actor_id_sn : StringName = StringName(action.actor_id)
	if actor_id_sn == &"":
		push_error("CutsceneManager: CutsceneActorMove actor_id is empty")
		return

	var actor : FieldActor = _find_field_actor(actor_id_sn)
	if actor == null:
		push_error("CutsceneManager: actor id missing in scene: " + String(actor_id_sn))
		return

	for marker_id in action.move_location_ids:
		var marker : CutsceneMarker = _find_marker(marker_id)
		if marker == null:
			push_error("CutsceneManager: marker id missing in scene: " + String(marker_id))
			continue

		await _move_actor_to(actor, marker.global_position, action)


## Moves an actor to a target position.
## INSTANT updates position immediately.
## Other path types currently use a simple tween based on move_speed.
func _move_actor_to(actor : FieldActor, target_pos : Vector2, action : CutsceneActorMove) -> void:
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


## Builds a list of actor ids referenced by the cutscene and locks them.
## Locking currently disables the actor StateMachine node, when present.
func _lock_actors_referenced_by_cutscene(script : CutsceneScript) -> void:
	_locked_entries.clear()

	var ids : Array[StringName] = _collect_actor_ids(script)
	for id in ids:
		var actor : FieldActor = _find_field_actor(id)
		if actor == null:
			continue
		_lock_actor(actor)


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
				var id : StringName = StringName(move.actor_id)
				if id == &"":
					continue
				if not ids.has(id):
					ids.append(id)

	return ids


## Applies the temporary lock to a specific actor.
## Current behavior
## 1) Zero velocity
## 2) If a StateMachine node exists, disable its processing and remember the previous process_mode
func _lock_actor(actor : FieldActor) -> void:
	actor.velocity = Vector2.ZERO

	var entry : Dictionary = {}
	entry["actor"] = actor

	var sm : Node = actor.get_node_or_null("StateMachine")
	if sm != null:
		entry["sm"] = sm
		entry["sm_mode"] = sm.process_mode
		sm.process_mode = Node.PROCESS_MODE_DISABLED

	_locked_entries.append(entry)


## Restores all actor locks captured during this cutscene run.
## StateMachine process_mode is restored exactly to its previous value.
func _unlock_actors() -> void:
	for entry in _locked_entries:
		var sm : Node = entry.get("sm", null)
		if sm != null:
			sm.process_mode = entry["sm_mode"]

		var actor : FieldActor = entry["actor"]
		actor.velocity = Vector2.ZERO

	_locked_entries.clear()
