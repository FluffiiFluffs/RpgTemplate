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



## Currently active overscene instance started by CutsceneOverscene.
var current_overscene : Node = null

## Cached field_root process mode so it can be restored after the overscene ends.
var _previous_field_root_process_mode : int = Node.PROCESS_MODE_INHERIT

#var current_field_scene : FieldScene = null

var spawn_direction : int = SIDE.DOWN
var next_scene_transitioner_name : String = ""

var spawn_offset : Vector2 = Vector2.ZERO
var transition_entry_offset : Vector2 = Vector2.ZERO

var is_loading_field_scene : bool = false

var _field_enemies_paused : bool = false


signal load_started
signal load_completed

#endregion


func _ready()->void:
	call_deferred("_connect_dialogue_pause")


func _connect_dialogue_pause()->void:
	DM.dialogue_session_started.connect(_on_dialogue_session_started)
	DM.dialogue_session_ended.connect(_on_dialogue_session_ended)

func _on_dialogue_session_started(_resource : Resource)->void:
	if GameState.gamestate == GameState.State.FIELD:
		GameState.gamestate = GameState.State.DIALOGUE
	set_field_enemies_paused(true)

func _on_dialogue_session_ended(_resource : Resource)->void:
	# DialogueManager.dialogue_ended can occur before the balloon is actually removed.
	# DM emits dialogue_session_ended only after the balloon has been cleared/invalidated.
	if GameState.gamestate == GameState.State.DIALOGUE:
		GameState.gamestate = GameState.State.FIELD
		set_field_enemies_paused(false)


func set_field_enemies_paused(paused : bool)->void:
	if paused == _field_enemies_paused:
		return
	_field_enemies_paused = paused

	if main_scene == null:
		return
	if main_scene.current_field_scene == null:
		return

	var fscene : FieldScene = main_scene.current_field_scene

	var mode : int = Node.PROCESS_MODE_INHERIT
	if paused:
		mode = Node.PROCESS_MODE_DISABLED

	@warning_ignore("int_as_enum_without_cast")
	fscene.placed_enemies.process_mode = mode
	@warning_ignore("int_as_enum_without_cast")
	fscene.enemy_spawners.process_mode = mode




#region Scene Changing
##Loads a new field scene (used with SceneTransitioner)
func load_field_scene(scene_path : String, scene_transition_target: String) -> void:
	is_loading_field_scene = true
	load_started.emit()

	DM.force_cleanup_dialogue_session()

	main_scene.transition_layer.play_begin()
	await main_scene.transition_layer.animation_player.animation_finished

	next_scene_transitioner_name = scene_transition_target

	CharDataKeeper.field_party_nodes.clear()
	CharDataKeeper.controlled_character = null

	for child in main_scene.field_scene_container.get_children():
		child.queue_free()

	main_scene.current_field_scene = null
	main_scene.title_scene = null

	var new_scene : FieldScene = load(scene_path).instantiate() as FieldScene
	main_scene.field_scene_container.add_child(new_scene)
	main_scene.current_field_scene = new_scene
	CutsceneManager.register_field_scene(main_scene.current_field_scene)
	last_party_actor = null

	party_spawn_point = find_transitioner(main_scene.current_field_scene, next_scene_transitioner_name)
	if party_spawn_point == null:
		push_error("SceneManager: transitioner not found: " + next_scene_transitioner_name + " in scene: " + scene_path)
	else:
		spawn_offset = party_spawn_point.compute_spawn_offset(transition_entry_offset)
		make_party_at_spawn_point(party_spawn_point)
		main_scene.field_camera_rig.follow_player()

	await get_tree().process_frame
	main_scene.transition_layer.play_end()
	await main_scene.transition_layer.animation_player.animation_finished

	GameState.gamestate = GameState.State.FIELD

	load_completed.emit()
	is_loading_field_scene = false

##Loads the title scene. Title scene is specifically loaded
func load_title_scene()->void:
	is_loading_field_scene = true
	GameState.gamestate = GameState.State.INTRO
	load_started.emit()
	DM.force_cleanup_dialogue_session()

	set_field_enemies_paused(false)
	_field_enemies_paused = false

	player_is_made = false
	party_is_made = false
	party_spawn_point = null
	last_party_actor = null
	next_scene_transitioner_name = ""
	spawn_offset = Vector2.ZERO
	transition_entry_offset = Vector2.ZERO
	current_overscene = null
	_previous_field_root_process_mode = Node.PROCESS_MODE_INHERIT

	CharDataKeeper.field_party_nodes.clear()
	CharDataKeeper.controlled_character = null

	if main_scene == null:
		load_completed.emit()
		is_loading_field_scene = false
		return

	main_scene.field_camera_rig.clear_target()
	main_scene.field_camera_rig.activate()

	for child in main_scene.over_scene.get_children():
		child.queue_free()

	for child in main_scene.battle_root.get_children():
		child.queue_free()
	main_scene.current_battle_scene = null
	main_scene.battling_field_enemy_scene = null
	main_scene.battle_root.visible = false

	for child in main_scene.field_scene_container.get_children():
		child.queue_free()

	main_scene.current_field_scene = null
	main_scene.title_scene = null

	main_scene.field_root.visible = true
	main_scene.field_root.process_mode = Node.PROCESS_MODE_INHERIT

	var new_scene: TitleScene = load("uid://b36ngnfew8k5c").instantiate() as TitleScene
	main_scene.field_scene_container.add_child(new_scene)
	main_scene.title_scene = new_scene

	CutsceneManager.register_field_scene(main_scene.title_scene)

	load_completed.emit()
	is_loading_field_scene = false
	
	
##Loads a field scene by filename.
##Loops through res://field/scenes/field_scenes/ and subfolders, returns the file.
##Used primary during loading a saved game.
@warning_ignore("unused_parameter")
func load_field_scene_by_filename(filename : String)->FieldScene:
	return null


## Entry point for character naming routine
## Instantiates name_input.tscn into main.overscene (uses load, not preload)
## Changes game state from whatever it's at, and records what it was before that point so it can be restored after naming is done
## Uses ID in the argument to call NameInput.load_member_by_id(id). It is assumed both of these functions will be called with ids specified (via a cutscene action or dialogue call)
func begin_cutscene_name_party_member(action : CutsceneNamePartyMember) -> Node:
	if action == null:
		push_error("SceneManager: begin_cutscene_name_party_member action is null")
		return null

	if action.actor_id == &"":
		push_error("SceneManager: begin_cutscene_name_party_member actor_id is empty")
		return null

	if current_overscene != null and is_instance_valid(current_overscene):
		push_error("SceneManager: begin_cutscene_name_party_member called while another overscene is already active")
		return null

	var packed_scene : PackedScene = load(action.scene_path) as PackedScene
	if packed_scene == null:
		push_error("SceneManager: failed to load naming scene: " + action.scene_path)
		return null

	var overscene : NameInput = packed_scene.instantiate() as NameInput
	if overscene == null:
		push_error("SceneManager: failed to instantiate NameInput")
		return null

	overscene.apply_name_party_member_action(action)

	_previous_field_root_process_mode = main_scene.field_root.process_mode
	main_scene.field_root.process_mode = Node.PROCESS_MODE_DISABLED
	main_scene.over_scene.add_child(overscene)
	current_overscene = overscene
	return overscene
	
	
## Instantiates a cutscene overscene under main_scene.over_scene and suspends field_root processing.
## Returns the instantiated overscene so CutsceneManager can await its completion signal.
func begin_cutscene_overscene(scene_path : String) -> Node:
	if scene_path.is_empty():
		push_error("SceneManager: begin_cutscene_overscene scene_path is empty")
		return null

	if main_scene == null:
		push_error("SceneManager: begin_cutscene_overscene cannot run because main_scene is null")
		return null

	if current_overscene != null and is_instance_valid(current_overscene):
		push_error("SceneManager: begin_cutscene_overscene called while another overscene is already active")
		return null

	var packed_scene : PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		push_error("SceneManager: begin_cutscene_overscene failed to load scene: " + scene_path)
		return null

	var overscene : Node = packed_scene.instantiate()
	if overscene == null:
		push_error("SceneManager: begin_cutscene_overscene failed to instantiate scene: " + scene_path)
		return null

	_previous_field_root_process_mode = main_scene.field_root.process_mode
	main_scene.field_root.process_mode = Node.PROCESS_MODE_DISABLED
	main_scene.over_scene.add_child(overscene)
	current_overscene = overscene
	return overscene


## Frees the active cutscene overscene and restores field_root processing.
func end_cutscene_overscene() -> void:
	if main_scene == null:
		current_overscene = null
		return

	if current_overscene != null and is_instance_valid(current_overscene):
		current_overscene.queue_free()

	current_overscene = null
	@warning_ignore("int_as_enum_without_cast")
	main_scene.field_root.process_mode = _previous_field_root_process_mode


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
				pmemberscene.field_actor_id = p_data.actor_id
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
				pmemberscene.field_actor_id = p_data.actor_id
				pmemberscene.global_position = last_party_actor.global_position + Vector2(0, -1)
				last_party_actor = pmemberscene
				CharDataKeeper.field_party_nodes.append(pmemberscene)

func remake_party_in_current_scene() -> void:
	if main_scene == null:
		push_error("SceneManager: remake_party_in_current_scene cannot run because main_scene is null")
		return

	var fscene : Node = main_scene.current_field_scene
	if fscene == null:
		push_error("SceneManager: remake_party_in_current_scene cannot run because there is no active field scene")
		return

	if not (fscene is FieldScene or fscene is TitleScene):
		push_error("SceneManager: remake_party_in_current_scene active scene does not expose a party node")
		return

	if CharDataKeeper.party_members.is_empty():
		push_warning("SceneManager: remake_party_in_current_scene called with no party members")
		return

	var party_parent : Node2D = fscene.party
	if party_parent == null:
		push_error("SceneManager: remake_party_in_current_scene party parent is null")
		return

	var recorded_positions : Dictionary = {}
	var leader_position : Vector2 = Vector2.ZERO
	var have_leader_position : bool = false

	for child in party_parent.get_children():
		if child is FieldPartyMember:
			var field_member : FieldPartyMember = child
			if field_member.field_actor_id != &"":
				recorded_positions[field_member.field_actor_id] = field_member.global_position
				if have_leader_position == false:
					leader_position = field_member.global_position
					have_leader_position = true

	if have_leader_position == false and CharDataKeeper.controlled_character != null:
		if is_instance_valid(CharDataKeeper.controlled_character):
			leader_position = CharDataKeeper.controlled_character.global_position
			have_leader_position = true

	for child in party_parent.get_children():
		child.queue_free()

	await get_tree().process_frame

	CharDataKeeper.field_party_nodes.clear()
	CharDataKeeper.controlled_character = null
	last_party_actor = null

	for index in range(CharDataKeeper.party_members.size()):
		if index > CharDataKeeper.party_size - 1:
			break

		var pmember : PartyMemberData = CharDataKeeper.party_members[index]
		if pmember == null:
			continue

		var pmemberscene : FieldPartyMember = pmember.field_scene.instantiate() as FieldPartyMember
		party_parent.add_child(pmemberscene)
		pmemberscene.name = pmember.get_display_name()
		pmemberscene.field_actor_id = pmember.actor_id

		var spawn_position : Vector2 = leader_position
		if recorded_positions.has(pmember.actor_id):
			spawn_position = recorded_positions[pmember.actor_id]
		elif index != 0:
			spawn_position = leader_position + Vector2(0, -1)

		pmemberscene.global_position = spawn_position
		pmemberscene.force_face_direction(Vector2.DOWN)

		if index == 0:
			CharDataKeeper.controlled_character = pmemberscene
			pmemberscene.set_controlled_on()
			pmemberscene.is_controlled = true
			pmemberscene.is_following = false
			pmemberscene.actor_to_follow = null
			last_party_actor = pmemberscene
		else:
			pmemberscene.actor_to_follow = last_party_actor
			pmemberscene.is_controlled = false
			pmemberscene.is_following = true
			pmemberscene.set_controlled_off()
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
## Finds a SceneTransitioner anywhere inside the loaded field scene by node name.
## This allows authored spawn points to live in any branch of the scene tree.
func find_transitioner(fscene : FieldScene, tname : String) -> SceneTransitioner:
	if fscene == null:
		return null
	return _find_transitioner_recursive(fscene, tname)


func _find_transitioner_recursive(root : Node, tname : String) -> SceneTransitioner:
	for child in root.get_children():
		if child is SceneTransitioner and child.name == tname:
			return child

		var found : SceneTransitioner = _find_transitioner_recursive(child, tname)
		if found != null:
			return found

	return null
	
#endregion
