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
var party_spawn_point

## Cached reference to the last actor in the follow chain
## Starts as the player, then becomes the last follower that was added
var last_party_actor : Node2D = null

## Tracks only the party actor nodes spawned by SceneManager so they can be freed safely
## without touching map authored NPCs or other field nodes.
var spawned_party_actors : Array[Node2D] = []

var main_scene : Main = null

var current_field_scene : FieldScene = null

var spawn_direction : int = SIDE.DOWN
var next_scene_transitioner_name : String = ""

var spawn_offset : Vector2 = Vector2.ZERO
var transition_entry_offset : Vector2 = Vector2.ZERO


signal load_started
signal load_completed

#endregion


#region Scene Changing
##Loads a new field scene (used with SceneTransitioner)
func load_field_scene(scene_path : String, scene_transition_target: String)->void:
	load_started.emit()
	#play transition begin
	main_scene.transition_layer.play_begin()
	await main_scene.transition_layer.animation_player.animation_finished
	
	#stores the name of the next transitioner to be found
	next_scene_transitioner_name = scene_transition_target
	
	
	#get rid of old scene
	for child in main_scene.field_scene_container.get_children():
		main_scene.field_scene_container.call_deferred("remove_child",child)
		await get_tree().process_frame
		child.queue_free()
	await get_tree().process_frame
	
	
	#use scene path string to instantiate a scene under main_scene.field_scene_container
	var new_scene = load(scene_path).instantiate()
	main_scene.field_scene_container.add_child(new_scene)
	current_field_scene = new_scene
	party_spawn_point = find_transitioner(current_field_scene, next_scene_transitioner_name)
	spawn_offset = party_spawn_point.compute_spawn_offset(transition_entry_offset)
	make_party_at_spawn_point(party_spawn_point)
	main_scene.field_camera_rig.follow_player()
	
	
	await get_tree().process_frame
	main_scene.transition_layer.play_end()
	await main_scene.transition_layer.animation_player.animation_finished
	load_completed.emit()
	
	#play transition end
	pass


#endregion Scene Changing



#region Instantiate Player + Party
##If player is already present within CharDataKeeper.party_members
func make_player_at_first_spawn_point()->void:
	if CharDataKeeper.party_members.is_empty():
		CharDataKeeper.party_members.append(CharDataKeeper.all_party_members[0])
	var player = CharDataKeeper.PLAYER_CHARACTER.instantiate() as PlayerCharacter
	current_field_scene.party.add_child(player)
	var player_data = CharDataKeeper.party_members[0]
	player.sprite_2d.texture = player_data.char_resource.char_sprite_sheet
	player.name = player_data.char_resource.char_name
	CharDataKeeper.controlled_character = player
	if !current_field_scene.player_spawn.get_children().is_empty():
		for child in current_field_scene.player_spawn.get_children():
			party_spawn_point = child
	else:
		if !current_field_scene.transition_areas.get_children().is_empty():
			for child in current_field_scene.transition_areas.get_children():
				party_spawn_point = child
		else:
			printerr("Tried to spawn player, but spawn points!")		
	player.force_face_direction(_side_to_vector(party_spawn_point.spawn_direction))
	player.global_position = party_spawn_point.global_position + party_spawn_point.compute_spawn_offset(party_spawn_point.global_position)

func make_party_at_spawn_point(spoint : SceneTransitioner)->void:
	var party = CharDataKeeper.party_members
	var index = -1
	for child in party:
		index += 1
		if index > party.size()-1: #this makes 1 player and 3 npcs
			return
		else:
			if index == 0:
				var pmember = CharDataKeeper.PLAYER_CHARACTER.instantiate() as PlayerCharacter
				current_field_scene.party.add_child(pmember)
				var p_data = party[index]
				pmember.sprite_2d.texture = p_data.char_resource.char_sprite_sheet
				CharDataKeeper.controlled_character = pmember
				pmember.name = p_data.char_resource.char_name
				pmember.force_face_direction(_side_to_vector(spoint.spawn_direction))
				pmember.global_position = spoint.global_position + spawn_offset
				last_party_actor = pmember
			else:
				var pmember = CharDataKeeper._NPC.instantiate() as NPC
				var p_data = party[index]
				pmember.actor_to_follow = last_party_actor
				pmember.is_following = true
				current_field_scene.party.add_child(pmember)
				pmember.sprite_2d.texture = p_data.char_resource.char_sprite_sheet
				pmember.name = p_data.char_resource.char_name
				pmember.p_det_area.queue_free()
				pmember.p_det_timer.queue_free()
				pmember.coll_timer.queue_free()
				pmember.global_position = last_party_actor.global_position + Vector2(0, -1)
				last_party_actor = pmember

#endregion Instantiate Player + Party


#region Helpers
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
	
	
##Finds the scene transitioner by name in the next field scene and returns it
func find_transitioner(fscene : FieldScene, tname : String )->SceneTransitioner:
	for child in fscene.transition_areas.get_children():
		if child is SceneTransitioner:
			if child.name == tname:
				return child
			else:
				return null
		else:
			return null
	return null
	
#endregion
