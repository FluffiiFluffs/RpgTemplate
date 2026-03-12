class_name SortOrderButton
extends HBoxContainer
##Button instantiated, to be used to control sort order of inventory in options menu


const ENABLED_COLOR = Color("f1b400ff")
const TRANS_COLOR = Color("00000000")
const WHITE_COLOR = Color("ffffffff")

@onready var sort_num_label : Label = %SortNumLabel
@onready var sort_button_container : PanelContainer = %SortButtonContainer
@onready var sort_button : Button = %SortButton

@export var is_selected : bool = false


func _ready()->void:
	sort_button_container.self_modulate = TRANS_COLOR
	sort_button.focus_entered.connect(b_focused)
	sort_button.focus_exited.connect(b_unfocused)
	sort_button.pressed.connect(_on_sort_button_pressed)


func _on_sort_button_pressed()->void:
	var sort_order_controller: Node = _get_sort_order_controller()
	if sort_order_controller != null:
		sort_order_controller.sort_order_button_pressed(self)


func set_selected(selected : bool)->void:
	is_selected = selected
	if selected:
		sort_button_container.self_modulate = ENABLED_COLOR
	else:
		sort_button_container.self_modulate = TRANS_COLOR


func b_focused()->void:
	if not is_selected:
		sort_button_container.self_modulate = WHITE_COLOR


func b_unfocused()->void:
	if not is_selected:
		sort_button_container.self_modulate = TRANS_COLOR


func set_button_text(_text:String)->void:
	sort_button.text = _text


func set_label_text(_num:int)->void:
	sort_num_label.text = str(_num)


func grab_button_focus()->void:
	sort_button.grab_focus()


func _get_sort_order_controller() -> Node:
	var current_node: Node = self
	while current_node != null:
		if current_node.has_method("sort_order_button_pressed"):
			return current_node
		current_node = current_node.get_parent()
	return null
