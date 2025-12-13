@tool
class_name TitleButton
#title_button.gd
##button used on the title screen
extends PanelContainer

@onready var button = %Button

@export var button_text : String = ""

const DISABLED_COLOR = Color("696969ff") 
const ENABLED_COLOR = Color("f1b400ff")
const TRANS_COLOR = Color("00000000")
const WHITE_COLOR = Color("ffffffff")
const MINUS_COLOR = Color("9b3800ff")

func _ready()->void:
	button.text = button_text
	self_modulate = TRANS_COLOR
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)
	
func on_button_pressed()->void:
	#pressed behavior setup in start_menu.gd
	pass
	
func on_button_focus_entered()->void:
	self_modulate = ENABLED_COLOR
	pass
	
func on_button_focus_exited()->void:
	self_modulate = TRANS_COLOR
	pass
		
func grab_button_focus()->void:
	button.grab_focus()
