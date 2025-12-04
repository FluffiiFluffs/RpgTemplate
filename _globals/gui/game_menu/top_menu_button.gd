@tool
class_name TopMenuButton
extends PanelContainer


@onready var button = %Button

@export var pressed : bool = false


##Should be a grayscale
@export var unselected : Texture2D = null
##Should be colored
@export var selected : Texture2D = null
@export var ui_name : String = ""

signal change_text(ui_name)

func _process(_delta)->void:
	if Engine.is_editor_hint():
		if pressed == false:
			button.icon = unselected
		else:
			button.icon = selected
		return
		
func _ready()->void:
	button.focus_entered.connect(button_focused)
	button.focus_exited.connect(button_unfocused)
	button.icon = unselected
	
func button_focused()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	button.icon = selected
	change_text.emit(ui_name)
	pass

func button_unfocused()->void:
	self_modulate = GameMenu.DISABLED_COLOR
	button.icon = unselected
	
	pass
