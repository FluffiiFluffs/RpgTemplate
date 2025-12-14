##Main.gd
##Main scene
extends Node

#region Node References
@onready var field_root : Node2D = %FieldRoot
@onready var field_scene_container : Node2D = %FieldSceneContainer
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
@export var starting_field_scene : PackedScene = null
@export var starting_spawn_id : StringName = &"Start"




#endregion Export Variables



#region State
var current_field_scene : Node = null
var current_battle_scene : Node = null
var title_menu_instance : CanvasLayer = null
#endregion State

#region Lifecycle

func _ready()->void:
	SceneManager.main_scene = self
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
	if starting_field_scene != null:
		await change_field_to(starting_field_scene, starting_spawn_id)

func change_field_to(field_scene : PackedScene, spawn_id : StringName) -> void:

	if field_scene == null:
		return

	## Run exit hook if the current field supports it
	if current_field_scene != null and is_instance_valid(current_field_scene):
		if current_field_scene.has_method("on_field_exit"):
			current_field_scene.call("on_field_exit")


		## Party actor nodes are field owned now, so clearing references is enough
		if SceneManager != null:
			SceneManager.reset_party_runtime_state()

		current_field_scene.queue_free()
		current_field_scene = null

	## Instance the new field
	var new_field = field_scene.instantiate()
	field_scene_container.add_child(new_field)
	await new_field.ready

	current_field_scene = new_field

	## Tell SceneManager which field is active so it can spawn party into FieldActors
	if SceneManager != null:
		SceneManager.set_current_field_scene(new_field)

		## Spawn target can be a spawn id (recommended for TransitionAreas)
		SceneManager.set_party_spawn_point(spawn_id)

	## Run field enter hook if available
	if new_field.has_method("on_field_enter"):
		await new_field.call("on_field_enter", spawn_id)


	## Spawn the party into the field
	if SceneManager != null:
		await SceneManager.make_party_in_scene()

	pass
