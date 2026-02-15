class_name TransitionLayer
extends CanvasLayer
##transition_layer.gd
##attached to TransitionLayer.tscn within Main.tscn
##Controls transition animations along with the animationplayer within the scene


@onready var animation_player : AnimationPlayer = %AnimationPlayer

##Animation to play when loading begins. 
##Black wipe from left to center of screen
func play_begin()->void:
	animation_player.play("L_TO_R_BEGIN")

##Animation to play when loading finishes
##Black wipe from center of screen to right of screen
func play_end()->void:
	animation_player.play("L_TO_R_END")

##Shows black screen
func play_black()->void:
	animation_player.play("L_TO_R_DURING")

##Fades screen to black
func play_fade_to_black()->void:
	animation_player.play("fade_to_black")

##Fades screen from black 
func play_fade_from_black()->void:
	animation_player.play("fade_from_black")
