class_name BattleSkillButton
extends PanelContainer

@onready var label : Label = %Label
@onready var button : Button = %Button

##Reference to a battler.actor_data's skill resource. Setup on instantiation.
var skill : Skill = null
##Reference to the battler. Setup on instantiation.
var battler : Battler = null

##Makes border stay lit up when focus is lost (when the button is pressed)
var is_active : bool = false

func _ready()->void:
	self_modulate = GameMenu.TRANS_COLOR
	button.focus_entered.connect(button_focused)
	button.focus_exited.connect(button_unfocused)
	button.pressed.connect(button_pressed)

func button_focused()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	pass

func button_unfocused()->void:
	if is_active:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
	pass

func button_pressed()->void:
	if battler == null:
		printerr(name + " NO BATTLER SET!")
		queue_free()
		return
	if skill == null:
		printerr(name + " NO SKILL SET!")
		queue_free()
	if skill != null and battler != null:
		is_active = true 
		battler.ui_element.last_skill_selected = skill.name
		SceneManager.main_scene.current_battle_scene.command_controller.begin_use_skill(battler, skill)

##Grabs the button's focus
func grab_button_focus()->void:
	button.grab_focus()

##Should be called after ready just to be safe. Makes label name and disables button if there isn't enough resource
func setup()->void:
	label.text = skill.name
	if not skill.can_pay_cost(battler.actor_data):
		button.disabled = true
