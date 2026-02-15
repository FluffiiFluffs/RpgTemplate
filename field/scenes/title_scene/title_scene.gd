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

signal license_done

#region Image Files for Licensing
const LICENSE_01 = preload("uid://bfhgbrpmrlm1c")
const LICENSE_02 = preload("uid://dmlv77ltpei2o")
const LICENSE_03 = preload("uid://btc0385l67exe")
#endregion Image Files for Licensing


func _ready()->void:
	title_sparkle.visible = false
	SceneManager.main_scene.field_camera_rig.global_position = Vector2(200, 112)
	play_licensing()
	


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("confirm_input"):
		match title_buttons.selected_button.to_lower():
			"new game":
				print("New Game")
				#take player to name entry / new game routine
			"load game":
				print("Load Game")
				#Open load game menu
			"options":
				print("Options")
				#open options menu
			"exit game":
				print("Exit Game")
				#Open are you sure window
			"":
				print("Nothing!")
				return

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
	animation_player.play("show_license")
	await animation_player.animation_finished
	play_license_02()

func play_license_02()->void:
	license_sprite.texture = LICENSE_02
	animation_player.play("show_license")
	await animation_player.animation_finished
	play_license_03()

func play_license_03()->void:
	license_sprite.texture = LICENSE_03
	animation_player.play("show_license")
	await animation_player.animation_finished
	show_title_menu()
	license_done.emit()
#region Licensing

#region Show Menu
func show_title_menu()->void:
	await show_title_back()
	await show_title_graphic()
	await show_title_buttons()
	GameState.gamestate = GameState.State.STARTMENU
	spawn_title_player()

func show_title_back()->void:
	animation_player.play("show_title_back")
	await animation_player.animation_finished
	pass

func show_title_graphic()->void:
	animation_player.play("show_title_graphic")
	await animation_player.animation_finished

func show_title_buttons()->void:
	animation_player.play("show_title_buttons")
	await animation_player.animation_finished
	
func spawn_title_player()->void:
	#pick a random party member from all available party members
	var new_player : PartyMemberData = CharDataKeeper.all_party_members.pick_random()
	var new_player_field : FieldPartyMember = new_player.field_scene.instantiate()
	party.add_child(new_player_field)
	new_player_field.is_controlled = true
	CharDataKeeper.controlled_character = new_player_field
	new_player_field.global_position = spawn_marker_2d.global_position
	
		
	
	pass
