##scene_manager.gd
##Global Script SceneManager
extends Node

#region State

enum SIDE {UP, DOWN, LEFT, RIGHT}

## True when a player node has been instantiated in the current scene
var player_is_made : bool = false

## True when at least one follower has been spawned in the current scene
var party_is_made : bool = false

## Node used as the spawn location for the party on scene change
## This should usually be set by the scene script (for example a Marker2D)
var party_spawn_point

## Cached reference to the last actor in the follow chain
## Starts as the player, then becomes the last follower that was added
var last_party_actor : Node2D = null

## Tracks only the party actor nodes spawned by SceneManager so they can be freed safely
## without touching map authored NPCs or other field nodes.
var spawned_party_actors : Array[Node2D] = []

var main_scene = null

var current_field_scene : FieldScene = null

var last_direction_faced : int = SIDE.DOWN
var spawn_direction : int = SIDE.DOWN

var spawn_offset : Vector2 = Vector2.ZERO

var transition_entry_offset : Vector2 = Vector2.ZERO


signal load_started
signal load_completed

#endregion


#region Internal helpers (lookup and basic data)


## Returns the Node that should own party actor nodes (player and followers).
## With the current architecture, this is the active field scene's FieldActors node.
func _get_field_actors_parent() -> Node:
	if current_field_scene == null or is_instance_valid(current_field_scene) == false:
		push_warning("SceneManager: current_field_scene is null; cannot find FieldActors")
		return null

	var container : Node2D = current_field_scene.get_actor_container()
	if container == null:
		push_warning("SceneManager: current_field_scene has no actor container (FieldActors).")
	return container


func _get_spawn_position() -> Vector2:
	var pos : Vector2 = Vector2.ZERO

	if party_spawn_point == null:
		pos = Vector2.ZERO
	elif party_spawn_point is Node2D:
		pos = (party_spawn_point as Node2D).global_position
	elif party_spawn_point is StringName or party_spawn_point is String:
		if current_field_scene != null and is_instance_valid(current_field_scene):
			var spawn_id : StringName = StringName(str(party_spawn_point))

			var t = _get_destination_transitioner(spawn_id)
			if t != null:
				pos = t.global_position
			elif current_field_scene.has_method("get_spawn_global_position"):
				pos = current_field_scene.get_spawn_global_position(spawn_id)
			else:
				pos = Vector2.ZERO


	return pos + spawn_offset



## Returns the index of the current party leader in CharDataKeeper.party_members.
## Uses CharDataKeeper.controlled_index when that is valid, otherwise falls back to 0.
## Returns -1 if there are no party members at all.
func _get_leader_index() -> int:
	var count = CharDataKeeper.party_members.size()
	if count == 0:
		return -1

	var idx = CharDataKeeper.controlled_index
	if idx < 0 or idx >= count:
		idx = 0
	return idx


## Returns the PartyMemberData for the current leader.
## Returns null if there is no valid leader.
func _get_leader_member() -> PartyMemberData:
	var idx = _get_leader_index()
	if idx == -1:
		return null
	return CharDataKeeper.get_member(idx)



## Frees only the party actor nodes spawned by SceneManager.
## Required now that party actors live under a persistent Main scene and will not
## be implicitly destroyed by unloading a field scene.
func _free_spawned_party_actors() -> void:
	for actor in spawned_party_actors:
		if actor != null and is_instance_valid(actor):
			actor.queue_free()
	spawned_party_actors.clear()

	player_is_made = false
	party_is_made = false
	last_party_actor = null
	CharDataKeeper.controlled_character = null

func _get_destination_transitioner(spawn_id : StringName) -> SceneTransitioner:
	if current_field_scene == null or is_instance_valid(current_field_scene) == false:
		return null

	var node : Node = current_field_scene.find_child(String(spawn_id), true, false)
	if node == null:
		return null

	return node as SceneTransitioner


func _sync_spawn_settings_from_destination() -> void:
	spawn_offset = Vector2.ZERO

	if party_spawn_point is StringName == false and party_spawn_point is String == false:
		return

	var spawn_id : StringName = StringName(str(party_spawn_point))
	var t = _get_destination_transitioner(spawn_id)
	if t == null:
		push_warning("SceneManager: spawn id '" + String(spawn_id) + "' did not resolve to a SceneTransitioner in the loaded field.")
		return

	spawn_direction = int(t.spawn_direction)
	spawn_offset = t.compute_spawn_offset(transition_entry_offset)


func _side_to_vector(side : int) -> Vector2:
	match side:
		SIDE.UP:
			return Vector2.UP
		SIDE.DOWN:
			return Vector2.DOWN
		SIDE.LEFT:
			return Vector2.LEFT
		SIDE.RIGHT:
			return Vector2.RIGHT
	return Vector2.DOWN


func _apply_spawn_facing_to_player(player : PlayerCharacter) -> void:
	if player == null:
		return

	last_direction_faced = spawn_direction

	var v := _side_to_vector(spawn_direction)
	if player.has_method("force_face_direction"):
		player.call("force_face_direction", v)



#endregion


#region Player instantiation (shared between scenarios)

## Instantiates the player character node for the given PartyMemberData and
## places it at the provided position. Also sets CharDataKeeper.controlled_character.
func _instantiate_player_for_member(member : PartyMemberData, position : Vector2) -> PlayerCharacter:
	if member == null:
		return null

	var actors_parent = _get_field_actors_parent()
	if actors_parent == null:
		return null

	var new_player : PlayerCharacter = CharDataKeeper.PLAYER_CHARACTER.instantiate()
	new_player.global_position = position

	CharDataKeeper.controlled_character = new_player
	actors_parent.call_deferred("add_child", new_player)
	await get_tree().process_frame

	if member.char_resource != null:
		new_player.sprite_2d.texture = member.char_resource.char_sprite_sheet
		new_player.name = member._get_name()

	player_is_made = true
	last_party_actor = new_player
	spawned_party_actors.append(new_player)
	_apply_spawn_facing_to_player(new_player)

	return new_player


#endregion




#region Scenario 1: spawn player when there is no player yet

func spawn_player_when_no_party() -> void:
	if CharDataKeeper.controlled_character != null and 	is_instance_valid(CharDataKeeper.controlled_character) == false:
		CharDataKeeper.controlled_character = null
	
	## A player already exists, nothing to do
	if CharDataKeeper.controlled_character != null and is_instance_valid(CharDataKeeper.controlled_character):
		player_is_made = true
		last_party_actor = CharDataKeeper.controlled_character
		return

	var member : PartyMemberData = _get_leader_member()

	## No current party, seed from all_party_members[0]
	if member == null and CharDataKeeper.party_members.is_empty():
		if CharDataKeeper.all_party_members.size() > 0:
			var warrior_data : PartyMemberData = CharDataKeeper.all_party_members[0]
			if warrior_data != null:
				CharDataKeeper.add_party_member(warrior_data)
				CharDataKeeper.controlled_index = 0
				member = warrior_data

	if member == null:
		return

	var spawn_pos = _get_spawn_position()
	await _instantiate_player_for_member(member, spawn_pos)
	spawn_offset = Vector2.ZERO
	transition_entry_offset = Vector2.ZERO


#endregion


#region Follower instantiation helpers

func _spawn_follower_for_member(member : PartyMemberData, previous_actor : Node2D) -> Node2D:
	if member == null:
		return null
	if member.char_resource == null:
		return null
	if previous_actor == null:
		return null
	if is_instance_valid(previous_actor) == false:
		return null

	var parent = previous_actor.get_parent()
	if parent == null:
		parent = _get_field_actors_parent()
	if parent == null:
		return null

	var follower : NPC = CharDataKeeper._NPC.instantiate()
	follower.npc_data = member.char_resource
	follower.is_following = true
	follower.collisions_on = false
	follower.global_position = previous_actor.global_position + Vector2(0, -1)

	parent.call_deferred("add_child", follower)
	await get_tree().process_frame

	follower.actor_to_follow = previous_actor

	if follower.p_det_timer != null:
		if follower.p_det_timer.timeout.is_connected(follower._check_for_player):
			follower.p_det_timer.timeout.disconnect(follower._check_for_player)
		follower.p_det_timer.call_deferred("queue_free")

	if follower.p_det_area != null:
		follower.p_det_area.call_deferred("queue_free")

	follower.name = member._get_name()
	spawned_party_actors.append(follower)

	return follower

#endregion


#region Scenario 3: respawn full party (tests and later map transitions)

func spawn_existing_party_at_spawn_point() -> void:
	if CharDataKeeper.party_members.is_empty():
		return

	_free_spawned_party_actors()

	var leader_index = _get_leader_index()
	if leader_index == -1:
		return

	var leader_member : PartyMemberData = CharDataKeeper.get_member(leader_index)
	if leader_member == null:
		return

	var spawn_pos = _get_spawn_position()
	var player = await _instantiate_player_for_member(leader_member, spawn_pos)
	spawn_offset = Vector2.ZERO
	transition_entry_offset = Vector2.ZERO

	if player == null:
		return

	var previous_actor : Node2D = player
	var spawned_any : bool = false
	var count = CharDataKeeper.party_members.size()

	for i in range(count):
		if i == leader_index:
			continue

		var member : PartyMemberData = CharDataKeeper.get_member(i)
		if member == null:
			continue

		var follower = await _spawn_follower_for_member(member, previous_actor)
		if follower == null:
			continue

		previous_actor = follower
		spawned_any = true

	if spawned_any:
		party_is_made = true
		last_party_actor = previous_actor

#endregion


#region Scenario 2: add one party member and spawn follower

func add_party_member_from_all(index : int) -> void:
	if index < 0:
		return
	if index >= CharDataKeeper.all_party_members.size():
		push_warning("add_party_member_from_all: index out of range: " + str(index))
		return

	var base_member : PartyMemberData = CharDataKeeper.all_party_members[index]
	if base_member == null:
		return

	if CharDataKeeper.party_members.has(base_member):
		return

	CharDataKeeper.add_party_member(base_member)

	if CharDataKeeper.party_members.size() == 1:
		CharDataKeeper.controlled_index = 0
		await spawn_player_when_no_party()
		return

	if CharDataKeeper.controlled_character == null or is_instance_valid(CharDataKeeper.controlled_character) == false:
		await spawn_existing_party_at_spawn_point()
		return

	var previous_actor : Node2D = last_party_actor
	if previous_actor == null:
		previous_actor = CharDataKeeper.controlled_character

	var member_index = CharDataKeeper.party_members.size() - 1
	var member : PartyMemberData = CharDataKeeper.get_member(member_index)

	var follower = await _spawn_follower_for_member(member, previous_actor)
	if follower != null:
		last_party_actor = follower
		party_is_made = true

#endregion


#region Public API

func make_player_in_scene() -> void:
	await spawn_player_when_no_party()


func make_party_in_scene() -> void:
	if CharDataKeeper.party_members.is_empty() and CharDataKeeper.all_party_members.size() > 0:
		for base_member in CharDataKeeper.all_party_members:
			if base_member != null:
				CharDataKeeper.add_party_member(base_member)
		CharDataKeeper.controlled_index = 0

	await spawn_existing_party_at_spawn_point()


func set_party_spawn_point(spawn_point) -> void:
	party_spawn_point = spawn_point
	_sync_spawn_settings_from_destination()

	

func set_current_field_scene(field_scene : FieldScene) -> void:
	current_field_scene = field_scene
	_sync_spawn_settings_from_destination()

	
## Clears party runtime references without queue_free.
## Use this when you are about to unload the field scene anyway.
func reset_party_runtime_state() -> void:
	spawned_party_actors.clear()
	player_is_made = false
	party_is_made = false
	last_party_actor = null
	CharDataKeeper.controlled_character = null


#endregion
