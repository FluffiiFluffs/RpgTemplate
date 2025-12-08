@tool
class_name QuestTypeButton
extends PanelContainer

@export var type : String = "COMPLETED"
@onready var label : Label = %Label
@onready var button : Button = %Button

var is_active : bool = false


func _ready()->void:
	label.text = type
	self_modulate = GameMenu.TRANS_COLOR
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)
	button.pressed.connect(on_button_pressed)
	
	
func on_button_focus_entered()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	pass
	
func on_button_focus_exited()->void:
	if is_active == true:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
	pass
	
func on_button_pressed()->void:
	match type:
		"CURRENT":
			if QuestManager.current_quests.is_empty():
				GameMenu.last_quests_menu_state = "QUESTS_CURRENT_QUESTS"
				is_active = false
				GameMenu.menu_state = "QUESTS_SELECT_TYPE"
				GameMenu.clear_quests_list()
				GameMenu.clear_quest_description()
				return
			else:
				GameMenu.menu_state = "QUESTS_CURRENT_QUESTS"
				is_active = true
				GameMenu.last_quests_menu_state = "QUESTS_CURRENT_QUESTS"
				GameMenu.open_current_quests()
			pass
		"COMPLETED":
			if QuestManager.completed_quests.is_empty():
				GameMenu.last_quests_menu_state = "QUESTS_COMPLETED_QUESTS"
				is_active = false
				GameMenu.menu_state = "QUESTS_SELECT_TYPE"
				GameMenu.clear_quests_list()
				GameMenu.clear_quest_description()
			else:
				GameMenu.menu_state = "QUESTS_CURRENT_QUESTS"
				is_active = true
				GameMenu.last_quests_menu_state = "QUESTS_COMPLETED_QUESTS"
				GameMenu.open_completed_quests()
			pass

func grab_button_focus()->void:
	button.grab_focus()
