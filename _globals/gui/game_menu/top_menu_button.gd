@tool
class_name TopMenuButton
extends PanelContainer


@onready var button = %Button

@export var pressed : bool = false


##Should be a grayscale
@export var unselected : Texture2D = null
##Should be colored
@export var selected : Texture2D = null

func _process(_delta)->void:
	if Engine.is_editor_hint():
		if pressed == false:
			button.icon = unselected
		else:
			button.icon = selected
		return
