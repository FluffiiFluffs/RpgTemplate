class_name InventoryItemButton
extends PanelContainer

@export var item : Item = null
@export var quantity : int = 0
@onready var item_button = %ItemButton
@onready var item_qty_label = %ItemQtyLabel


func _ready()->void:
	item_button.focus_entered.connect(button_focused)
	item_button.focus_exited.connect(button_unfocused)


func button_focused()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	pass

func button_unfocused()->void:
	self_modulate = GameMenu.DISABLED_COLOR
