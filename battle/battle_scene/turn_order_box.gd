class_name TurnOrderBox
extends PanelContainer

@onready var texture_rect : TextureRect = %TextureRect

var is_active : bool = false

func _process(_delta)->void:
	if is_active == true:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.WHITE_COLOR
