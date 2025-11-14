#walk_center_point.gd
##This node is used to determine where an NPC should walk if their position at load is not to be used.
class_name WalkCenterPoint
extends Node2D


@onready var collision_shape_2d = %CollisionShape2D


func _ready()->void:
	collision_shape_2d.queue_free()
	visible = false
