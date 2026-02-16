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
##ALERT This is not used or referenced anywhere, commented out
#var spawned_party_actors : Array[Node2D] = []

var main_scene : Main = null

#var current_field_scene : FieldScene = null

var spawn_direction : int = SIDE.DOWN
var next_scene_transitioner_name : String = ""

var spawn_offset : Vector2 = Vector2.ZERO
var transition_entry_offset : Vector2 = Vector2.ZERO

var is_loading_field_scene : bool = false

signal load_started
signal load_completed

#endregion


#region Scene Changing
##Loads a new field scene (used with SceneTransitioner)
func load_field_scene(scene_path : String, scene_transition_target: String)->void:
	is_loading_field_scene = true
	load_started.emit()
	
	#play transition begin
	main_scene.transition_layer.play_begin()
	await main_scene.transition_layer.animation_player.animation_finished
	
	#stores the name of the next transitioner to be found
	next_scene_transitioner_name = scene_transition_target
	
	#Clear out the field party nodes array so it can be populated again
	CharDataKeeper.field_party_nodes.clear()
	#Clear the controlled character, too
	CharDataKeeper.controlled_character = null
	
	if main_scene.current_field_scene != null:
		main_scene.current_field_scene.queue_free()
		main_scene.current_field_scene = null
	
	#use scene path string to instantiate a scene under main_scene.field_scene_container
	var new_scene = load(scene_path).instantiate()
	main_scene.field_scene_container.add_child(new_scene)
	main_scene.current_field_scene = new_scene
	if party_spawn_point != null:
		party_spawn_point = find_transitioner(main_scene.current_field_scene, next_scene_transitioner_name)
		spawn_offset = party_spawn_point.compute_spawn_offset(transition_entry_offset)
		make_party_at_spawn_point(party_spawn_point)
		main_scene.field_camera_rig.follow_player()
	
	
	await get_tree().process_frame
	main_scene.transition_layer.play_end()
	await main_scene.transition_layer.animation_player.animation_finished
	load_completed.emit()
	is_loading_field_scene = false


func load_title_scene()->void:
	is_loading_field_scene = true
	GameState.gamestate = GameState.State.INTRO
	load_started.emit()
	
	#Clear out the field party nodes array so it can be populated again
	CharDataKeeper.field_party_nodes.clear()
	#Clear the controlled character, too
	CharDataKeeper.controlled_character = null

	#use scene path string to instantiate a scene under main_scene.field_scene_container
	var new_scene = load("uid://b36ngnfew8k5c").instantiate()
	main_scene.field_scene_container.add_child(new_scene)
	main_scene.title_scene = new_scene

	load_completed.emit()
	is_loading_field_scene = false




#endregion Scene Changing



#region Instantiate Player + Party
##Currently unused and should probably not be used going forward 20263101
##If player is already present within CharDataKeeper.party_members
func make_player_at_first_spawn_point()->void:
	if CharDataKeeper.party_members.is_empty():
		CharDataKeeper.party_members.append(CharDataKeeper.all_party_members[0])
	var player = CharDataKeeper.party_members[0]
	var player_scene = player.field_scene.instantiate() as FieldPartyMember
	main_scene.current_field_scene.party.add_child(player_scene)
	var player_data = CharDataKeeper.party_members[0]
	#player.sprite_2d.texture = player_data.char_resource.char_sprite_sheet
	player_scene.name = player_data.get_display_name()
	CharDataKeeper.controlled_character = player_scene
	if !main_scene.current_field_scene.player_spawn.get_children().is_empty():
		for child in main_scene.current_field_scene.player_spawn.get_children():
			party_spawn_point = child
	else:
		if !main_scene.current_field_scene.transition_areas.get_children().is_empty():
			for child in main_scene.current_field_scene.transition_areas.get_children():
				party_spawn_point = child
		else:
			printerr("Tried to spawn player, but spawn no points!")		
	player_scene.force_face_direction(_side_to_vector(party_spawn_point.spawn_direction))
	player_scene.global_position = party_spawn_point.global_position + party_spawn_point.compute_spawn_offset(party_spawn_point.global_position)

func make_party_at_spawn_point(spoint : SceneTransitioner)->void:
	CharDataKeeper.field_party_nodes.clear() #just make sure it's empty
	var party = CharDataKeeper.party_members
	var index = -1
	for child in party:
		index += 1
		if index > party.size()-1: #this makes 1 player and 3 npcs
			return
		else:
			if index == 0:
				var pmember = CharDataKeeper.party_members[index]
				var pmemberscene = pmember.field_scene.instantiate() as FieldPartyMember
				main_scene.current_field_scene.party.add_child(pmemberscene)
				var p_data = party[index]
				#pmember.sprite_2d.texture = p_data.char_resource.char_sprite_sheet
				CharDataKeeper.controlled_character = pmemberscene
				pmemberscene.name = p_data.get_display_name()
				pmemberscene.actor_id = p_data.actor_id
				pmemberscene.force_face_direction(_side_to_vector(spoint.spawn_direction))
				pmemberscene.global_position = spoint.global_position + spawn_offset
				pmemberscene.set_controlled_on()
				last_party_actor = pmemberscene
				pmemberscene.is_controlled = true
				CharDataKeeper.field_party_nodes.append(pmemberscene)
			else:
				var pmember = CharDataKeeper.party_members[index]
				var pmemberscene = pmember.field_scene.instantiate() as FieldPartyMember
				var p_data = party[index]
				pmemberscene.actor_to_follow = last_party_actor
				pmemberscene.is_controlled = false
				pmemberscene.is_following = true
				
				main_scene.current_field_scene.party.add_child(pmemberscene)
				pmemberscene.set_controlled_off()
				#pmember.sprite_2d.texture = p_data.char_resource.char_sprite_sheet
				pmemberscene.name = p_data.get_display_name()
				pmemberscene.actor_id = p_data.actor_id
				pmemberscene.global_position = last_party_actor.global_position + Vector2(0, -1)
				last_party_actor = pmemberscene
				CharDataKeeper.field_party_nodes.append(pmemberscene)

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
	var n = fscene.transition_areas.get_node_or_null(tname)
	if n is SceneTransitioner:
		return n
	return null
	
#endregion
