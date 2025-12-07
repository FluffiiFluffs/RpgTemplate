@tool
class_name InventoryOptionsButton
extends PanelContainer

@onready var button : Button = %Button
@export var text : String = ""
var is_active = false

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
	if !is_active:
		self_modulate = GameMenu.WHITE_COLOR
		
func set_color()->void:
	if is_active == true:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.WHITE_COLOR

func grab_button_focus()->void:
	button.grab_focus()
