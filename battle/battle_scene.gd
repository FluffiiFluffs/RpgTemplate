class_name BattleScene
extends Node2D
@onready var button : Button = %Button


signal victory_button

func _ready()->void:
	button.pressed.connect(_on_button_pressed)
	
	
func _on_button_pressed()->void:
	victory_button.emit()
	pass
