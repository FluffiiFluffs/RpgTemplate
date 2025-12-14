class_name TransitionLayer
extends CanvasLayer

@onready var animation_player : AnimationPlayer = %AnimationPlayer

##Animation to play when loading begins. 
func play_begin()->void:
	animation_player.play("L_TO_R_BEGIN")

##Animation to play when loading finishes
func play_end()->void:
	animation_player.play("L_TO_R_END")
	
