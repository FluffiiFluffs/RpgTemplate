@tool
class_name InventoryOptionsButton
extends PanelContainer

@onready var button = %Button
@export var text : String = ""

@export var focus_color : Color = Color(0.945, 0.704, 0.0, 1.0)
@export var unfocus_color : Color = Color(1.0, 1.0, 1.0, 1.0)


func _process(_delta)->void:
	if Engine.is_editor_hint():
		button.text = text
		return
		
func _ready()->void:
	button.text = text
	button.focus_entered.connect(button_focused)
	button.focus_exited.connect(button_unfocused)


func button_focused()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	pass

func button_unfocused()->void:
	self_modulate = GameMenu.DISABLED_COLOR
