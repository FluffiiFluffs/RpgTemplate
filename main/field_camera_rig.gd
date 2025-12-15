class_name FieldCameraRig
extends Node2D



@onready var field_camera : Camera2D = %FieldCamera
@export var follow_speed : float = 0.0 #0.0 = snap
@export var snap : bool = false

var main : Main = null
var target : Node2D = null

func _ready()->void:
	main = get_parent().get_parent()

func _physics_process(delta)->void:
	if target == null:
		return
	var desired = target.global_position
	if follow_speed <= 0.0:
		global_position = desired
		return
	var smoothing = 1.0 - pow(0.001, follow_speed * delta)
	global_position = global_position.lerp(desired, smoothing)
	
func activate()->void:
	field_camera.enabled = true
	field_camera.make_current()
	
func deactivate()->void:
	field_camera.enabled = false

func set_target(new_target : Node2D, snap_now : bool = false)->void:
	target = new_target
	if target == null:
		return
	if snap_now or snap:
		global_position = target.global_position
		
func clear_target()->void:
	target = null
	
func follow_player(snap_now : bool = true)->void:
	var player = CharDataKeeper.controlled_character
	if player == null:
		target = null
		printerr("FieldCameraRig could not find player(null)")
		return
	activate()
	set_target(player, snap_now)
