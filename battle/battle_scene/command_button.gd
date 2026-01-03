class_name CommandButton
extends PanelContainer
##Scene used as a button within party member's BattleStats UI to select actions (attack, skill, defend, run)

@onready var texture_rect : TextureRect = %TextureRect
@onready var button : Button = %Button
@export var button_type : String = ""
@onready var command_container_container : PanelContainer = %CommandContainerContainer

var is_active : bool = false
var battle_stats : BattleStats = null

signal command_button_pressed

func _ready()->void:
	self_modulate = GameMenu.TRANS_COLOR
	battle_stats = command_container_container.get_parent().get_parent()
	setup_button_icon()
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)
	button.pressed.connect(on_button_pressed)
	
func on_button_focus_entered()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	pass
	
func on_button_focus_exited()->void:
	if is_active:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
	pass	


func on_button_pressed()->void:
	command_button_pressed.emit(button_type)

func setup_button_icon()->void:
	#makes button icon a particular icon depending on what button_type is
	#button icon must be 12x12 texture
	match button_type:
		"attack":
			texture_rect.texture = battle_stats.ATTACK
		"skill":
			texture_rect.texture = battle_stats.SKILL
		"item":
			texture_rect.texture = battle_stats.ITEM
		"defend":
			texture_rect.texture = battle_stats.DEFEND
		"run":
			texture_rect.texture = battle_stats.RUN
		_:
			return
	pass

func grab_button_focus()->void:
	button.grab_focus()

func activate_button()->void:
	button.disabled = false
func deactivate_button()->void:
	button.disabled = true
