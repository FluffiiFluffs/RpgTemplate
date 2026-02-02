##Scene intended to be instantiated over an actor on VFX layer
##[br]
##Automatically plays animation and then queues free when instantiated
class_name PoisonBubble
extends Node2D

@onready var animation_player: AnimationPlayer = %AnimationPlayer


func _ready()->void:
	play_and_destroy()
	
func play_and_destroy()->void:
	animation_player.play("float")
	await animation_player.animation_finished
	queue_free()
