class_name TitleOptVolumeSlider
extends PanelContainer


@onready var h_slider : HSlider = %HSlider
@onready var button : Button = %Button


@export_enum ("MUSIC", "SFX", "VOICES") var volume_type : String= "MUSIC"

func _ready()->void:
	h_slider.value_changed.connect(set_options_value)
	button.focus_entered.connect(button_focused)
	button.focus_exited.connect(button_unfocused)
	button.pressed.connect(button_pressed)
	get_volume()

#also should be called when menu is opened
func get_volume()->void:
	match volume_type:
		"MUSIC":
			h_slider.value = Options.music_volume
		"SFX":
			h_slider.value = Options.sfx_volume
		"VOICES":
			h_slider.value = Options.voices_volume

func button_focused()->void:
	self_modulate = GameMenu.DISABLED_COLOR
	pass

func button_unfocused()->void:
	if SceneManager.main_scene.title_scene.options_menu.current_selected_slider == self:
		return
	self_modulate = GameMenu.TRANS_COLOR

func button_pressed()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	SceneManager.main_scene.title_scene.options_menu.slider_active(self)
	h_slider.grab_focus()

func set_options_value(_value:float)->void:
	match volume_type:
		"MUSIC":
			Options.music_volume = _value
		"SFX":
			Options.sfx_volume = _value
		"VOICES":
			Options.voices_volume = _value

func _unhandled_input(_event):
	if SceneManager.main_scene.title_scene.options_menu.current_selected_slider == self:
		if Input.is_action_just_pressed("cancel_input"):
			button.grab_focus()
			await get_tree().process_frame
			SceneManager.main_scene.title_scene.options_menu.slider_inactive() 
