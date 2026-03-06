class_name SkillsSkillButton
extends PanelContainer

@export var skill : Skill = null
@onready var skill_button: Button = %SkillButton
@onready var skill_cost: Label = %SkillCost

var is_selected : bool = false

func _ready()->void:
	skill_button.toggle_mode = false
	refresh_visual_state()

func grab_button_focus()->void:
	skill_button.grab_focus()

func set_selected(selected : bool)->void:
	is_selected = selected
	refresh_visual_state()

func set_blocked(_blocked : bool)->void:
	refresh_visual_state()

func refresh_visual_state()->void:
	var is_focused : bool = false
	if skill_button != null:
		is_focused = skill_button.has_focus()

	if is_selected:
		self_modulate = GameMenu.ENABLED_COLOR
		return

	if is_focused:
		self_modulate = GameMenu.WHITE_COLOR
		return

	self_modulate = GameMenu.TRANS_COLOR

func on_button_pressed()->void:
	pass
