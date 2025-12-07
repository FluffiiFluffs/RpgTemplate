class_name InventoryItemButton
extends PanelContainer
##Button is instantiated with GameMenu.make_item_button()
##button.pressed, focus_entered, and focus_exited are handled with that function


@export var item : Item = null
@export var islot : InventorySlot = null
@export var quantity : int = 0
@onready var item_button : Button = %ItemButton
@onready var item_qty_label : Label = %ItemQtyLabel

var is_selected : bool = false

func _ready()->void:
	pass


func grab_button_focus()->void:
	item_button.grab_focus()

func set_selected(selected : bool)->void:
	is_selected = selected
	if item_button:
		item_button.button_pressed = selected
	if selected:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
