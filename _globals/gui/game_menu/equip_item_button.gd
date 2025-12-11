class_name EquipItemButton
extends PanelContainer
##Button instantiated and used to show current available equipment to be selected from Inventory.current_inventory (filtering done when menu is opened)

@onready var label : Label = %Label
@onready var button : Button = %Button

var item_ref : Item = null
var slot_ref = null

func _ready()->void:
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)
	
func on_button_focus_entered()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	pass
	
func on_button_focus_exited()->void:
	self_modulate = GameMenu.TRANS_COLOR
	pass
