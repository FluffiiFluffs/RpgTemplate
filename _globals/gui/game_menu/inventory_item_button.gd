class_name InventoryItemButton
extends PanelContainer

@export var item : Item = null
@export var quantity : int = 0
@onready var item_button = %ItemButton
@onready var item_qty_label = %ItemQtyLabel

@export var focus_color : Color = Color(0.945, 0.704, 0.0, 1.0)
@export var unfocus_color : Color = Color(1.0, 1.0, 1.0, 1.0)


func _ready()->void:
	item_button.focus_entered.connect(button_focused)
	item_button.focus_exited.connect(button_unfocused)


func button_focused()->void:
	self_modulate = focus_color
	pass

func button_unfocused()->void:
	self_modulate = unfocus_color
