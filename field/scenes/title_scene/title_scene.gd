class_name TitleScene
extends Node2D

@export var field_id : StringName = &""
@export var enforce_draw_order : bool = true
@export var adopt_placed_actors_on_enter : bool = true

@onready var tile : Node2D = %Tile
@onready var ground1 : TileMapLayer = %Ground1
@onready var ground_2 : TileMapLayer = %Ground2
@onready var ground_3 : TileMapLayer = %Ground3
@onready var ground_4 : TileMapLayer = %Ground4
@onready var ground_5 : TileMapLayer = %Ground5
@onready var decor_bottom : TileMapLayer = %DecorBottom
@onready var decor_top : TileMapLayer = %DecorTop

@onready var navigation : NavigationRegion2D = %Navigation

@onready var markers : Node2D = %Markers
@onready var player_spawn : Node2D = %PlayerSpawn

@onready var interactables : Node2D = %Interactables
@onready var triggers : Node2D = %Triggers
@onready var triggers_audio : Node2D = %Audio
@onready var triggers_cutscene : Node2D = %Cutscene
@onready var triggers_encounter : Node2D = %Encounter
@onready var transition_areas : Node2D = %TransitionAreas

@onready var field_actors : Node2D = %FieldActors
@onready var placed_enemies : Node2D = %PlacedEnemies
@onready var enemy_spawners : Node2D = %EnemySpawners
@onready var placed_npcs : Node2D = %PlacedNPCs
@onready var party : Node2D = %Party

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var license_sprite: Sprite2D = %LicenseSprite
@onready var choice_text: Label = %ChoiceText
@onready var title_buttons: TitleButtons = %TitleButtons
@onready var spawn_marker_2d: Marker2D = %SpawnMarker2D
@onready var title_sparkle: GPUParticles2D = %TitleSparkle
@onready var canvas_layer: CanvasLayer = %CanvasLayer

@onready var options_menu: TitleOptionsMenu = %OptionsMenu
@onready var new_game_menu: Control = %NewGameMenu
@onready var exit_game_menu: Control = %ExitGameMenu
@onready var load_game_menu: Control = %LoadGameMenu
@onready var load_game_confirm_menu: Control = %LoadGameConfirmMenu

@onready var new_game_yes: Button = %NewGameYes
@onready var new_game_no: Button = %NewGameNo
@onready var exit_game_yes: Button = %ExitGameYes
@onready var exit_game_no: Button = %ExitGameNo
@onready var load_game_close_button: Button = %LoadGameCloseButton
@onready var load_game_yes: Button = %LoadGameYes
@onready var load_game_no: Button = %LoadGameNo





@export_enum("ALL_CLOSED", "NEW_GAME_MENU_OPEN", "LOAD_GAME_MENU_OPEN", "LOAD_GAME_CONFIRM", "OPTIONS_MENU_OPEN", "OPTIONS_SLIDER","CONTROLS_MENU_OPEN", "EXIT_GAME_MENU_OPEN") var menu_state : String = "ALL_CLOSED"

signal license_done

#region Image Files for Licensing
const LICENSE_01 = preload("uid://bfhgbrpmrlm1c")
const LICENSE_02 = preload("uid://dmlv77ltpei2o")
const LICENSE_03 = preload("uid://btc0385l67exe")
#endregion Image Files for Licensing


func _ready()->void:
	setup_title()
	title_sparkle.visible = false
	title_sparkle.emitting = false
	SceneManager.main_scene.field_camera_rig.global_position = Vector2(200, 112)
	play_licensing()


#region Setup
func setup_title()->void:
	#Find list of savegames to load
	#retrieve options from save file and apply to Options
	
	#Hide all menus in case they are visible from the inspector
	canvas_layer.visible = false
	options_menu.visible = false
	new_game_menu.visible = false
	load_game_menu.visible = false
	load_game_confirm_menu.visible = false
	exit_game_menu.visible = false
	options_menu.title_scene = self
	
	setup_buttons()
	options_menu.setup_options_menu()
	
	#Set menu state to ALL_CLOSED
	menu_state = "ALL_CLOSED"
	get_viewport().gui_release_focus()
	#unfocus all, to ensure nothing is focused by accident


##Connects all menu button functions to the buttons (except options)
func setup_buttons()->void:
	new_game_yes.pressed.connect(new_game_yes_pressed)
	new_game_no.pressed.connect(new_game_no_pressed)
	load_game_close_button.pressed.connect(load_game_close_pressed)
	load_game_yes.pressed.connect(load_game_yes_pressed)
	load_game_no.pressed.connect(load_game_no_pressed)
	exit_game_yes.pressed.connect(exit_game_yes_pressed)
	exit_game_no.pressed.connect(exit_game_no_pressed)
	


#endregion Setup

#region Button Setup
##Start a new game[br]
##Takes user to the name input screen
func new_game_yes_pressed()->void:
	#Open name input screen (don't actually change scenes yet)
	print("NEW GAME STARTED")
	new_game_confirm_close() #this will close the menu until the input screen is actually implemented
	pass
	
##Closes the new game confirmation window
func new_game_no_pressed()->void:
	new_game_confirm_close()
	pass
	
##Closes the load game menu
func load_game_close_pressed()->void:
	load_game_menu_close()
	pass
	
##Loads the selected saved game file. Called when a saved game is selected
func load_game_yes_pressed()->void:
	#load selected saved game
	pass
	
##Returns to the load game menu and focuses the last saved game that was selected
func load_game_no_pressed()->void:
	load_game_menu_confirm_close()
	pass
	
##Confirms the player wishes to exit the game. Closes the game
func exit_game_yes_pressed()->void:
	get_tree().quit()
	pass

##Closes the exit game menu
func exit_game_no_pressed()->void:
	exit_game_menu_close()
	pass


#endregion Button Setup



#region Licensing
func play_licensing()->void:
	if Options.show_licensing:
		await get_tree().create_timer(1.0).timeout
		play_license_01()
	else:
		show_title_menu()
		pass

func play_license_01()->void:
	license_sprite.texture = LICENSE_01
	animation_player.play("license_show")
	await animation_player.animation_finished
	play_license_02()

func play_license_02()->void:
	license_sprite.texture = LICENSE_02
	animation_player.play("license_show")
	await animation_player.animation_finished
	play_license_03()

func play_license_03()->void:
	license_sprite.texture = LICENSE_03
	animation_player.play("license_show")
	await animation_player.animation_finished
	show_title_menu()
	license_done.emit()
#endregion Licensing

#region Show Hide Menus
func show_title_menu()->void:
	await show_title_back()
	await show_title_graphic()
	await show_title_buttons()
	GameState.gamestate = GameState.State.STARTMENU
	spawn_title_player()

func show_title_back()->void:
	animation_player.play("title_back_show")
	await animation_player.animation_finished
	pass

func show_title_graphic()->void:
	animation_player.play("title_graphic_show")
	await animation_player.animation_finished

func show_title_buttons()->void:
	animation_player.play("title_buttons_show")
	await animation_player.animation_finished
	
func spawn_title_player()->void:
	#pick a random party member from all available party members
	var new_player : PartyMemberData = CharDataKeeper.all_party_members.pick_random()
	var new_player_field : FieldPartyMember = new_player.field_scene.instantiate()
	party.add_child(new_player_field)
	new_player_field.is_controlled = true
	CharDataKeeper.controlled_character = new_player_field
	new_player_field.global_position = spawn_marker_2d.global_position
	
	
	
##Opens confirmation box for starting a new game (Y/N)
##Exists so the player doesn't accidentally start a new game when they don't want to
func new_game_confirm_open()->void:
	canvas_layer.visible = true
	#show new game confirm menu
	animation_player.play("new_game_menu_show")
	await animation_player.animation_finished
	#focus N (just in case)
	new_game_no.grab_focus()
		
	#set field character being controlled to is_controlled = true
	CharDataKeeper.controlled_character.is_controlled = false
	#Change menu state to "NEW_GAME_MENU_OPEN"
	menu_state = "NEW_GAME_MENU_OPEN"

##Closes confirmation box for starting a new game
func new_game_confirm_close()->void:
	#close new game confirm menu
	animation_player.play("new_game_menu_hide")
	await animation_player.animation_finished
	canvas_layer.visible = false
	
	#set field character being controlled to is_controlled = false
	CharDataKeeper.controlled_character.is_controlled = true	
	#change menu state back to "ALL_CLOSED"
	get_viewport().gui_release_focus()
	menu_state = "ALL_CLOSED"
	
##Opens the options menu, settings should reflect the save file containing options variables
func options_menu_open()->void:
	#show options menu
	canvas_layer.visible = true
	animation_player.play("options_menu_show")
	await animation_player.animation_finished
	#focus top option
	options_menu.opt_music_slider.button.grab_focus()
	
	#set field character being controlled to is_controlled = true
	CharDataKeeper.controlled_character.is_controlled = false
	#Change menu state to "OPTIONS_MENU_OPEN"
	menu_state = "OPTIONS_MENU_OPEN"

##Closes the options menu. Saves settings to options file which should be loaded when the game starts if it exists (autosaves). ##TODO need save/load system in order to do this
func options_menu_close()->void:
	#save options to file (autosave)
	
	#hide options menu
	animation_player.play("options_menu_hide")
	await animation_player.animation_finished
	canvas_layer.visible = false
	
	#set field character being controlled to is_controlled = true
	CharDataKeeper.controlled_character.is_controlled = true
	get_viewport().gui_release_focus()
	#change menu state back to "ALL_CLOSED"
	menu_state = "ALL_CLOSED"


##Opens the load game menu. Focuses the first save or if no saves, then the focus close button
func load_game_menu_open()->void:
	#unhide load menu
	canvas_layer.visible = true
	animation_player.play("load_game_menu_show")
	await animation_player.animation_finished
	
	#focus first save. If no saves, then focus close button
	load_game_close_button.grab_focus()
	
	#set field character being controlled to is_controlled = false
	CharDataKeeper.controlled_character.is_controlled = false
	menu_state = "LOAD_GAME_MENU_OPEN"

##Closes load menu if player hits close button or cancel_input
func load_game_menu_close()->void:
	#hide load menu
	animation_player.play("load_game_menu_hide")
	await animation_player.animation_finished
	canvas_layer.visible = false
	
	#set field character being controlled to is_controlled = true
	CharDataKeeper.controlled_character.is_controlled = true
	get_viewport().gui_release_focus()
	menu_state = "ALL_CLOSED"
	
func load_game_menu_confirm_open()->void:
	#unhide load menu confirm
	canvas_layer.visible = true
	animation_player.play("load_game_confirm_menu_show")
	await animation_player.animation_finished
	
	#focus N
	load_game_no.grab_focus()
	
	#Change menu state to "LOAD_MENU_CONFIRM_OPEN"
	menu_state = "LOAD_GAME_MENU_CONFIRM"


##Returns to the load game menu and refocuses the last saved game selected
func load_game_menu_confirm_close()->void:
	#hide load menu confirmation
	animation_player.play("load_game_confirm_menu_hide")
	await animation_player.animation_finished
	canvas_layer.visible = false
	
	#TODO refocus last save slot in load menu. for now, just focuses the close button
	load_game_close_button.grab_focus()
		
	#change menu state back to "ALL_CLOSED"
	menu_state = "LOAD_GAME_MENU_OPEN"
	

	
##Opens the exit game confirm menu (Y/N)
func exit_game_menu_open()->void:
	canvas_layer.visible = true
	#unhide exit menu confirm box
	animation_player.play("exit_game_menu_show")
	await animation_player.animation_finished
	#focus N
	exit_game_no.grab_focus()
	#set field character being controlled to is_controlled = false
	CharDataKeeper.controlled_character.is_controlled = false
	
	#Change menu state to "EXIT_GAME_MENU_OPEN"
	menu_state = "EXIT_GAME_MENU_OPEN"
	
	
##Closes the exit game confirm menu
##If user hits N or cancel_input
func exit_game_menu_close()->void:
	#hide exit menu
	animation_player.play("exit_game_menu_hide")
	await animation_player.animation_finished
	canvas_layer.visible = false
	#set field character being controlled to is_controlled = true
	CharDataKeeper.controlled_character.is_controlled = true
	
	#change menu state back to "ALL_CLOSED"
	menu_state = "ALL_CLOSED"
	
	#unfocus all
	get_viewport().gui_release_focus()

#endregion Show Hide Menus



func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("confirm_input"):
		if menu_state == "ALL_CLOSED":
			match title_buttons.selected_button:
				"new game":
					print("New Game")
					new_game_confirm_open()
					#take player to name entry / new game routine
				"load game":
					print("Load Game")
					load_game_menu_open()
					#Open load game menu
				"options":
					print("Options")
					options_menu_open()
					#open options menu
				"exit game":
					print("Exit Game")
					exit_game_menu_open()
					#Open are you sure window
				"":
					print("Nothing!")
					return
					
	if Input.is_action_just_pressed("cancel_input"):
		match menu_state:
			"ALL_CLOSED":
				return
			"NEW_GAME_MENU_OPEN":
				new_game_confirm_close()
			"LOAD_GAME_MENU_OPEN":
				load_game_menu_close()
			"LOAD_GAME_CONFIRM":
				load_game_menu_confirm_close()
			"OPTIONS_MENU_OPEN":
				options_menu_close()
			"OPTIONS_SLIDER":
				#Refocus last in options menu, this already happens via options menu scripting
				menu_state = "OPTIONS_OPEN"
			"CONTROLS_MENU_OPEN":
				pass
			
			"EXIT_GAME_MENU_OPEN":
				exit_game_menu_close()
				menu_state = "ALL_CLOSED"
