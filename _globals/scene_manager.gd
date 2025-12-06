##scene_manager.gd
##Global Script SceneManager
extends Node2D

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

#endregion


#region Internal helpers (lookup and basic data)

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

#endregion


#region Player instantiation (shared between scenarios)

## Instantiates the player character node for the given PartyMemberData and
## places it at the provided position. Also sets CharDataKeeper.controlled_character.
## Called by both "no party yet" and "existing party" flows.
func _instantiate_player_for_member(member : PartyMemberData, position : Vector2) -> PlayerCharacter:
	if member == null:
		return null

	var new_player : PlayerCharacter = CharDataKeeper.PLAYER_CHARACTER.instantiate()
	new_player.global_position = position

	CharDataKeeper.controlled_character = new_player
	get_tree().current_scene.call_deferred("add_child", new_player)
	await get_tree().process_frame

	if member.char_resource != null:
		new_player.sprite_2d.texture = member.char_resource.char_sprite_sheet
		new_player.name = member._get_name()

	player_is_made = true
	last_party_actor = new_player

	return new_player

#endregion


#region Scenario 1: spawn player when there is no player yet

## Spawns a player character into the current scene when none exists.
## If there is no party yet, this seeds the party with all_party_members[0]
## (for example, warrior) and uses that as the leader.
func spawn_player_when_no_party() -> void:
	## A player already exists, nothing to do
	if player_is_made and CharDataKeeper.controlled_character != null:
		return

	var member : PartyMemberData = _get_leader_member()

	## No current party, so seed from all_party_members[0] for new game or testing
	if member == null and CharDataKeeper.party_members.is_empty():
		if CharDataKeeper.all_party_members.size() > 0:
			var warrior_data : PartyMemberData = CharDataKeeper.all_party_members[0]
			if warrior_data != null:
				CharDataKeeper.add_party_member(warrior_data)
				CharDataKeeper.controlled_index = 0
				member = warrior_data

	## Still nothing to control, bail out
	if member == null:
		return

	var spawn_pos = _get_spawn_position()
	await _instantiate_player_for_member(member, spawn_pos)

#endregion


#region Follower instantiation helpers

## Internal helper that spawns a follower NPC for the given PartyMemberData and
## attaches it to the follow chain by setting actor_to_follow.
## The follower is placed exactly one pixel above the previous actor
## which is important for clean Y sorting.
func _spawn_follower_for_member(member : PartyMemberData, previous_actor : Node2D) -> Node2D:
	if member == null:
		return null
	if member.char_resource == null:
		return null
	if previous_actor == null:
		return null

	var parent = previous_actor.get_parent()
	if parent == null:
		return null

	var follower : NPC = CharDataKeeper._NPC.instantiate()
	follower.npc_data = member.char_resource
	follower.is_following = true
	follower.collisions_on = false

	## Place follower one pixel above the previous actor for Y sorting
	follower.global_position = previous_actor.global_position + Vector2(0, -1)

	parent.call_deferred("add_child", follower)
	await get_tree().process_frame

	follower.actor_to_follow = previous_actor

	## Remove standard detection logic so this behaves as a pure follower
	if follower.p_det_timer != null:
		if follower.p_det_timer.timeout.is_connected(follower._check_for_player):
			follower.p_det_timer.timeout.disconnect(follower._check_for_player)
		follower.p_det_timer.call_deferred("queue_free")

	if follower.p_det_area != null:
		follower.p_det_area.call_deferred("queue_free")

	follower.name = member._get_name()

	return follower

#endregion


#region Scenario 3: respawn full party on scene change

## For scene changes when CharDataKeeper.party_members is not empty.
## Rebuilds the player and all followers at the spawn point in the new scene.
## Every follower is placed one pixel above the previous actor.
func spawn_existing_party_at_spawn_point() -> void:
	if CharDataKeeper.party_members.is_empty():
		return

	## Reset SceneManager state for this new scene
	player_is_made = false
	party_is_made = false
	last_party_actor = null

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

	## Spawn followers for every non leader party member
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

## Adds a single party member from CharDataKeeper.all_party_members and, when appropriate,
## spawns a follower for that member in the current scene.
## This is suitable for join events where you recruit one member at a time.
##
## Example mapping:
##   index 0 = warrior_party_member_data.tres
##   index 1 = thief_party_member_data.tres
##   index 2 = mage_party_member_data.tres
##   index 3 = healer_party_member_data.tres
func add_party_member_from_all(index : int) -> void:
	if index < 0:
		return
	if index >= CharDataKeeper.all_party_members.size():
		push_warning("add_party_member_from_all: index out of range: " + str(index))
		return

	var base_member : PartyMemberData = CharDataKeeper.all_party_members[index]
	if base_member == null:
		return

	## Prevent adding the same PartyMemberData reference twice
	if CharDataKeeper.party_members.has(base_member):
		return

	CharDataKeeper.add_party_member(base_member)

	## If this is the first member ever, make this member the leader and spawn the player
	if CharDataKeeper.party_members.size() == 1:
		CharDataKeeper.controlled_index = 0
		await spawn_player_when_no_party()
		return

	## Ensure the player and any existing followers are present in the scene
	## If there is no player yet, this will spawn the full party including the new member
	if not player_is_made or CharDataKeeper.controlled_character == null:
		await spawn_existing_party_at_spawn_point()
		return

	var player : Node2D = CharDataKeeper.controlled_character
	if player == null:
		return

	var previous_actor : Node2D = last_party_actor
	if previous_actor == null:
		previous_actor = player

	## The member we just appended is the last entry in party_members
	var member_index = CharDataKeeper.party_members.size() - 1
	var member : PartyMemberData = CharDataKeeper.get_member(member_index)

	var follower = await _spawn_follower_for_member(member, previous_actor)
	if follower != null:
		last_party_actor = follower
		party_is_made = true

#endregion


#region Public API

## Convenience entry point for scenes that only care about
## "make sure a player exists".
## If there is no party yet, this will seed from all_party_members[0].
func make_player_in_scene() -> void:
	await spawn_player_when_no_party()


## Convenience entry point for test scenes where you want the full party
## from all_party_members to appear in the scene, even if the run time party
## is empty. After seeding, it respawns the full party at party_spawn_point.
func make_party_in_scene() -> void:
	## For testing, if run time party is empty but all_party_members has entries,
	## copy them into party_members so you get a full party at once.
	if CharDataKeeper.party_members.is_empty() and CharDataKeeper.all_party_members.size() > 0:
		for base_member in CharDataKeeper.all_party_members:
			if base_member != null:
				CharDataKeeper.add_party_member(base_member)
		CharDataKeeper.controlled_index = 0

	await spawn_existing_party_at_spawn_point()


## Optional helper for handling scene changes through SceneManager.
## You can expand this later to also handle fade transitions or similar.
func load_scene(_scene : PackedScene) -> void:
	## Example pattern:
	## 1) Clear node references from the old scene if needed
	##    CharDataKeeper.controlled_character = null
	##    player_is_made = false
	##    party_is_made = false
	##    last_party_actor = null
	##
	## 2) Change to the new scene
	##    get_tree().change_scene_to_packed(_scene)
	##
	## 3) In the new scene script _ready, set:
	##       SceneManager.party_spawn_point = $PartySpawnPoint
	##       SceneManager.spawn_existing_party_at_spawn_point()
	pass

#endregion
