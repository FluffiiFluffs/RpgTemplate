##Main.gd
##Main scene
extends Node

#region Node References
@onready var field_root : Node2D = %FieldRoot
@onready var field_scene_container : Node2D = %FieldSceneContainer
@onready var field_actors : Node2D = %FieldActors
@onready var field_vfx : Node2D = %FieldVFX
@onready var field_camera_rig : Node2D= %FieldCameraRig
@onready var field_camera : Camera2D = %FieldCamera
@onready var battle_root : Node2D = %BattleRoot
@onready var battle_scene_container : Node2D = %BattleSceneContainer
@onready var battle_vfx : Node2D = %BattleVFX
@onready var battle_camera_rig : Node2D = %BattleCameraRig
@onready var battle_camera : Camera2D  = %BattleCamera
@onready var transition_layer : CanvasLayer = %TransitionLayer
@onready var audio_root : Node = %AudioRoot
@onready var runtime : Node = %Runtime
@onready var title_menu_layer : Node = %TitleMenuLayer

#endregion Node References

#region Export Variables
@export var title_menu_scene : PackedScene = null




#endregion Export Variables



#region State
var current_field_scene : Node = null
var current_battle_scene : Node = null
var title_menu_instance : CanvasLayer = null
#endregion State

#region Lifecycle

func _ready()->void:
	add_to_group(&"main") #Scene is added to global main group
	_show_start_menu()
	pass
	
#endregion Lifecycle


#region Mode Switching

	
func _show_start_menu()->void:
	field_root.visible = false
	battle_root.visible = false
	field_camera.enabled = false
	battle_camera.enabled = false
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
	battle_camera.enabled = false
	field_camera.make_current()
	
	if GameState != null:
		GameState.gamestate = GameState.State.FIELD
	
	pass
