class_name Main
extends Node
##Main.gd
##Main scene
##The main scene of the game. Used to manage almost all aspects of the game outside of global functions.

#region Node References
@onready var field_root : Node2D = %FieldRoot
@onready var field_scene_container : Node2D = %FieldSceneContainer
@onready var field_vfx : Node2D = %FieldVFX
@onready var field_camera_rig : Node2D= %FieldCameraRig
@onready var field_camera : Camera2D = %FieldCamera
@onready var battle_root : Node2D = %BattleRoot
@onready var transition_layer : CanvasLayer = %TransitionLayer
@onready var audio_root : Node = %AudioRoot
@onready var runtime : Node = %Runtime
@onready var title_menu_layer : Node = %TitleMenuLayer

#endregion Node References

#region Export Variables
@export var title_menu_scene : PackedScene = null
@export var starting_field_scene : PackedScene = null
@export var starting_spawn_id : StringName = &"Start"




#endregion Export Variables



#region Variables
var current_field_scene : Node = null
var current_battle_scene : Node = null
var title_menu_instance : CanvasLayer = null


#endregion Variables

#region Lifecycle

func _ready()->void:
	SceneManager.main_scene = self
	#_show_start_menu()
	
	pass
	
#endregion Lifecycle


#region Mode Switching

	
func _show_start_menu()->void:
	field_root.visible = false
	battle_root.visible = false
	field_camera.enabled = false
	if GameMenu != null:
		GameMenu.visible = false
		
	if title_menu_instance == null and title_menu_scene != null:
		title_menu_instance = title_menu_scene.instantiate() as CanvasLayer
		title_menu_layer.add_child(title_menu_instance)
	
	if title_menu_instance != null:
		title_menu_instance.visible = true
		
	if GameState != null:
		GameState.gamestate = GameState.State.STARTMENU
		
func start_new_game()->void:
	if title_menu_instance != null:
		title_menu_instance.visible = false
	if GameMenu != null:
		GameMenu.visible = false
		
	field_root.visible = true
	battle_root.visible = false
	field_camera.enabled = true
	field_camera.make_current()
	
	if GameState != null:
		GameState.gamestate = GameState.State.FIELD
	#if starting_field_scene != null:
		#await change_field_to(starting_field_scene, starting_spawn_id)
		
func field_camera_to_player()->void:
	if CharDataKeeper.controlled_character == null:
		printerr("Field camera could not be placed on player (NULL)")
		return
	##make camera rig follow the player

#region Helpers
