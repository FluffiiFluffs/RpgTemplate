class_name SkillsSkillButton
extends PanelContainer
##Button is instantiated with skills_ui.make_skill_button()
##button.pressed, focus_entered, and focus_exited are handled with that function


@export var skill : Skill = null
@export var sp_cost : int = 0
@onready var skill_button: Button = %SkillButton
@onready var skill_cost: Label = %SkillCost

var is_selected : bool = false

func _ready()->void:
	self_modulate = GameMenu.TRANS_COLOR
	pass


func grab_button_focus()->void:
	skill_button.grab_focus()

func set_selected(selected : bool)->void:
	is_selected = selected
	if skill_button:
		skill_button.button_pressed = selected
	if selected:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
