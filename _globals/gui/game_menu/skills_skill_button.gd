class_name SkillsSkillButton
extends PanelContainer
##Button is instantiated with skills_ui.make_skill_button()
##button.pressed, focus_entered, and focus_exited are handled with that function



@export var skill : Skill = null
@onready var skill_button: Button = %SkillButton
@onready var skill_cost: Label = %SkillCost

var is_selected : bool = false
var is_blocked : bool = false

func _ready()->void:
	refresh_visual_state()


func grab_button_focus()->void:
	skill_button.grab_focus()

func set_selected(selected : bool)->void:
	is_selected = selected
	if skill_button:
		skill_button.button_pressed = selected
	refresh_visual_state()

func set_blocked(blocked : bool)->void:
	is_blocked = blocked
	refresh_visual_state()

func refresh_visual_state()->void:
	var is_focused : bool = false
	if skill_button != null:
		is_focused = skill_button.has_focus()

	if is_selected:
		if is_blocked:
			self_modulate = GameMenu.MINUS_COLOR
		else:
			self_modulate = GameMenu.ENABLED_COLOR
		return

	if is_focused:
		if is_blocked:
			self_modulate = GameMenu.MINUS_COLOR
		else:
			self_modulate = GameMenu.WHITE_COLOR
		return

	if is_blocked:
		self_modulate = GameMenu.DISABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
		
func on_button_pressed()->void:
	pass
