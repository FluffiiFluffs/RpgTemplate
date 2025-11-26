##game_menu_gui.gd
##global GameMenu
extends CanvasLayer

@onready var animation_player = %AnimationPlayer


func _unhandled_input(event):
	if Input.is_action_just_pressed("test4"):
		animation_player.play("inventory_show")
