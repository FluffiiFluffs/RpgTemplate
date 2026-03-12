@tool
class_name TitleOptMSpeedSlider
extends PanelContainer

@export_enum ("MENU", "BATTLE") var message_type : String = "MENU"
@onready var m_speed_label : Label = %MSpeedLabel
@onready var m_speed_value : Label = %MSpeedValue
@onready var m_speed_slider : HSlider = %MSpeedSlider
@onready var button : Button = %Button
@onready var options_menu : TitleOptionsMenu = find_parent("OptionsMenu") as TitleOptionsMenu


func _ready()->void:
	set_label()
	m_speed_slider.value_changed.connect(slider_changed)
	button.pressed.connect(button_pressed)
	button.focus_entered.connect(button_focused)
	button.focus_exited.connect(button_unfocused)
	if Engine.is_editor_hint():
		return
	get_options_speed()
	set_speed_label()


func button_focused()->void:
	self_modulate = GameMenu.DISABLED_COLOR

func button_unfocused()->void:
	if options_menu.current_selected_slider == self:
		return
	self_modulate = GameMenu.TRANS_COLOR

func get_options_speed()->void:
	match message_type:
		"MENU":
			m_speed_slider.value = Options.message_speed
		"BATTLE":
			m_speed_slider.value = Options.battle_message_speed

func set_label()->void:
	match message_type:
		"MENU":
			m_speed_label.text = "MESSAGE SPEED"
		"BATTLE":
			m_speed_label.text = "BATTLE MESSAGE SPEED"
			
func set_speed_label()->void:
	match message_type:
		"MENU":
			m_speed_value.text = str(Options.message_speed)
		"BATTLE":
			m_speed_value.text = str(Options.battle_message_speed)

func button_pressed()->void:
	options_menu.slider_active(self)
	self_modulate = GameMenu.ENABLED_COLOR
	options_menu.title_scene.menu_state = "OPTIONS_SLIDER"
	m_speed_slider.grab_focus()

func slider_changed(_value:float)->void:
	match message_type:
		"MENU":
			Options.message_speed = _value
			m_speed_value.text = str(_value)
		"BATTLE":
			Options.battle_message_speed = _value
			m_speed_value.text = str(_value)
	set_speed_label()

func _unhandled_input(_event)->void:
	if options_menu.current_selected_slider == self:
		if Input.is_action_just_pressed("cancel_input"):
			button.grab_focus()
			await get_tree().process_frame
			options_menu.slider_inactive()
