##scene_manager.gd
##Global Script SceneManager
extends Node

#region State

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

#endregion


#region Internal helpers (lookup and basic data)


## Returns the Node that should own party actor nodes (player and followers).
## Under the persistent Main scene, this is Main/FieldRoot/FieldActors.
## Falls back to get_tree().current_scene if that path is not present (useful for test scenes).
func _get_field_actors_parent() -> Node:
	var cs = get_tree().current_scene
	if cs == null:
		return null

	var actors = cs.get_node_or_null("FieldRoot/FieldActors")
	if actors != null:
		return actors

	return cs



## Returns the world position where the party leader should be spawned.
## If party_spawn_point is a Node2D, uses its global_position.
## Otherwise returns Vector2.ZERO as a safe default.
func _get_spawn_position() -> Vector2:
	if party_spawn_point != null and party_spawn_point is Node2D:
		return party_spawn_point.global_position
	return Vector2.ZERO


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

	return new_player


#endregion




#region Scenario 1: spawn player when there is no player yet

func spawn_player_when_no_party() -> void:
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

#endregion
