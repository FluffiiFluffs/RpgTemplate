@tool
class_name CurrentEquipButton
extends PanelContainer


@onready var button : Button = %Button
@onready var title_label : Label = %TitleLabel
@onready var equipment_label : Label = %EquipmentLabel

@export var equip_title : String = ""

var is_active : bool = false


func _ready()->void:
	self_modulate = GameMenu.TRANS_COLOR
	title_label.text = equip_title
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)

	if Engine.is_editor_hint():
		return
	pass

#func on_button_pressed()->void:
	#setup by GameMenu script, since it needs a custom function

func on_button_focus_entered()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	pass
	
func on_button_focus_exited()->void:
	if is_active:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
		
func grab_button_focus()->void:
	button.grab_focus()
