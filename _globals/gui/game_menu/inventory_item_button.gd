class_name InventoryItemButton
extends PanelContainer
##Button is instantiated with GameMenu.make_item_button()
##button.pressed, focus_entered, and focus_exited are handled with that function


@export var item : Item = null
@export var quantity : int = 0
@onready var item_button : Button = %ItemButton
@onready var item_qty_label : Label = %ItemQtyLabel

func _ready()->void:
	pass
