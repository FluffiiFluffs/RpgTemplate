class_name OptVolumeSlider
extends PanelContainer


@onready var h_slider = %HSlider
@onready var button = %Button


@export_enum ("MUSIC", "SFX", "VOICES") var volume_type : String= "MUSIC"

func _ready()->void:
	h_slider.value_changed.connect(set_options_value)
	button.focus_entered.connect(button_focused)
	button.focus_exited.connect(button_unfocused)
	button.pressed.connect(button_pressed)
	get_volume()
	pass


#also should be called when menu is opened
func get_volume()->void:
	match volume_type:
		"MUSIC":
			h_slider.value = Options.music_volume
		"SFX":
			h_slider.value = Options.sfx_volume
		"VOICES":
			h_slider.value = Options.voices_type

func button_focused()->void:
	self_modulate = GameMenu.DISABLED_COLOR
	pass

func button_unfocused()->void:
	if GameMenu.current_selected_slider == self:
		return
	self_modulate = GameMenu.TRANS_COLOR
	pass
	
func button_pressed()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	GameMenu.slider_active(self)
	h_slider.grab_focus()


	pass


func set_options_value(_value:float)->void:
	match volume_type:
		"MUSIC":
			Options.music_volume = _value
		"SFX":
			Options.sfx_volume = _value
		"VOICES":
			Options.voices_volume = _value
	pass


func _unhandled_input(_event):
	if GameMenu.current_selected_slider == self:
		if Input.is_action_just_pressed("cancel_input"):
			GameMenu.slider_inactive()
			button.grab_focus()
