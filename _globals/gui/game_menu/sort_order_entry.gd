class_name SortOrderButton
extends HBoxContainer
##Button instantiated, to be used to control sort order of inventory in options menu


@onready var sort_num_label : Label = %SortNumLabel
@onready var sort_button_container : PanelContainer = %SortButtonContainer
@onready var sort_button : Button = %SortButton


@export var l_name : String = ""
@export var is_selected : bool = false




func _ready()->void:
	sort_button.focus_entered.connect(b_focused)
	sort_button.focus_exited.connect(b_unfocused)
	sort_button.pressed.connect(button_is_selected)
	
	
func button_is_selected()->void:
	is_selected = true
	#needs to set style box sort_button_container.border_width to 2 on all sides (left, tiop, right bottom)

func button_is_deselected()->void:
	is_selected = false
	#needs to set sort_button_container.style box border_width to 1 on all sides (left, tiop, right bottom)

func b_focused()->void:
	self_modulate = GameMenu.DISABLED_COLOR
	pass

func b_unfocused()->void:
	self_modulate = GameMenu.TRANS_COLOR
	
func set_button_text(_text:String)->void:
	sort_button.text = _text

func set_label_text(_num:int)->void:
	sort_num_label.text = str(_num)
	
func _unhandled_input(event):
	if Input.is_action_just_pressed("cancel_input"):
		if GameMenu.menu_state == "OPTIONS_SORT_ORDER":
			##close the sort menu
			pass
		if GameMenu.menu_state == "OPTIONS_SORT_ORDER_SORTING":
			##take sort menu out of selection mode
			pass
