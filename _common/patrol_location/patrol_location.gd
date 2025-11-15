@tool
class_name PatrolLocation
extends Node2D

@onready var sprite_2d = %Sprite2D
@onready var line_2d = %Line2D
@onready var num_label = %NumLabel
@onready var wait_label = %WaitLabel

@export var wait_time : float = 0.0:
	set(v):
		wait_time = v
		_update_wait_time_label()

const COLORS = [ Color(1,0,0), Color(1,1,0), Color(0,1,0), Color(0,1,1), Color(0,0,1), Color(1,0,1) ]


var target_position : Vector2 = Vector2.ZERO

signal transform_changed


func _enter_tree() -> void:
	set_notify_transform( true )

func _notification( what: int ) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		transform_changed.emit()


func _ready()->void:
	target_position = global_position
	_update_wait_time_label()
	#print(str(name) + " " + str(target_position))
	if Engine.is_editor_hint():
		return
	sprite_2d.queue_free()
		
		
func update_label(_s:String) -> void:
	num_label.text = _s
	
func update_line(next_location:Vector2)->void:
	
	line_2d.points[1] = next_location - position
		
func _update_wait_time_label()->void:
	if Engine.is_editor_hint():
		wait_label.text = "WAIT:" + str(snappedf(wait_time, 0.1)) + "s"
		

func _get_color_by_index( i : int ) -> Color:
	var color_count : int = COLORS.size()
	while i > color_count - 1:
		i -= color_count
	return COLORS[ i ]
