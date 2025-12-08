class_name QuestButton
extends PanelContainer
##Button in UI used to show the title of a quest

@export var quest : Quest = null

@onready var label : Label = %Label
@onready var button : Button = %Button

var is_active : bool = false

func _ready()->void:
	self_modulate = GameMenu.TRANS_COLOR
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)

func grab_button_focus()->void:
	button.grab_focus()

func on_button_focus_exited()->void:
	self_modulate = GameMenu.TRANS_COLOR

func on_button_focus_entered()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	GameMenu.update_quest_description(quest)
