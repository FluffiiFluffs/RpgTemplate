class_name CommandButton
extends PanelContainer
##Scene used as a button within battle_scene's UI to allow player to select top level commands (attack, skill, defend, run)

@onready var texture_rect : TextureRect = %TextureRect
@onready var button : Button = %Button
@export var button_type : String = ""

var is_active : bool = false

func _ready()->void:
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
		self_modulate = GameMenu.TRANS_color
	pass	
	
func on_button_pressed()->void:
	match button_type:
		#attack opens selection of who to attack, active true
		"attack":
			pass
		#skill opens skill menu, active, true
		"skill":
			pass
		#item opens battle item menu (should only show battle-usable items), active true
		"item":
			pass
		#defend opens defend selection (party only), selects the active party member (but can select other party members). adds stack of defense for 1 round until the party member who used defend has their turn again, active true
		"defend":
			pass
		#run attempts to run from battle immediately, rolls
		"run":
			pass
		_:
			printerr(name + ": Invalid button_type " + button_type)
	pass

func setup_button_icon()->void:
	#makes button icon a particular icon depending on what button_type is
	#button icon must be 12x12 texture
	match button_type:
		"attacK":
			pass
		"skill":
			pass
		"item":
			pass
		"defend":
			pass
		"run":
			pass
		_:
			return
	pass

func grab_button_focus()->void:
	button.grab_focus()

func activate_button()->void:
	button.disabled = false
func deactivate_button()->void:
	button.disabled = true
