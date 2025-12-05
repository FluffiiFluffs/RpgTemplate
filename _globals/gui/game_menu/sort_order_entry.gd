class_name SortOrderButton
extends HBoxContainer
##Button instantiated, to be used to control sort order of inventory in options menu


@onready var sort_num_label : Label = %SortNumLabel
@onready var sort_button_container : PanelContainer = %SortButtonContainer
@onready var sort_button : Button = %SortButton


#@export var l_name : String = ""
@export var is_selected : bool = false


func _ready()->void:
	sort_button_container.self_modulate = GameMenu.TRANS_COLOR
	sort_button.focus_entered.connect(b_focused)
	sort_button.focus_exited.connect(b_unfocused)
	sort_button.pressed.connect(_on_sort_button_pressed)


func _on_sort_button_pressed()->void:
	if GameMenu:
		GameMenu.sort_order_button_pressed(self)


func set_selected(selected : bool)->void:
	is_selected = selected
	if selected:
		sort_button_container.self_modulate = GameMenu.ENABLED_COLOR
	else:
		sort_button_container.self_modulate = GameMenu.TRANS_COLOR


func b_focused()->void:
	if not is_selected:
		sort_button_container.self_modulate = GameMenu.WHITE_COLOR


func b_unfocused()->void:
	if not is_selected:
		sort_button_container.self_modulate = GameMenu.TRANS_COLOR


func set_button_text(_text:String)->void:
	sort_button.text = _text


func set_label_text(_num:int)->void:
	sort_num_label.text = str(_num)



func grab_button_focus()->void:
	sort_button.grab_focus()
