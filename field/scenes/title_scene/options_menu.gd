class_name TitleOptionsMenu
extends Control

@onready var opt_music_slider: TitleOptVolumeSlider = %OptMusicSlider
@onready var opt_sfx_slider:TitleOptVolumeSlider= %OptSFXSlider
@onready var opt_voices_slider:TitleOptVolumeSlider= %OptVoicesSlider
@onready var v_type_label: Label = %VTypeLabel
@onready var v_type_button: CheckButton = %VTypeButton
@onready var p_type_label: Label = %PTypeLabel
@onready var p_type_button: CheckButton = %PTypeButton
@onready var m_type_label: Label = %MTypeLabel
@onready var m_type_button: CheckButton = %MTypeButton
@onready var m_speed: TitleOptMSpeedSlider = %MSpeed
@onready var bm_speed: TitleOptMSpeedSlider = %BMSpeed
@onready var menu_mem_button: CheckButton = %MenuMemButton
@onready var batt_mem_button: CheckButton = %BattMemButton
@onready var opt_controls_button: Button = %OptControlsButton
@onready var opt_close_button: Button = %OptCloseButton


@export var title_scene : TitleScene = null

var current_selected_slider = null

##Setup routine for the options menu
func setup_options_menu()->void:
	ui_set_v_type()
	ui_set_p_type()
	ui_set_move_type()
	ui_set_menu_memory()
	ui_set_volume()
	m_speed.get_options_speed()
	bm_speed.get_options_speed()
	m_speed.set_speed_label()
	bm_speed.set_speed_label()
	setup_options_focus()
	setup_options_buttons_presses()

##Connects button presses to their functions
func setup_options_buttons_presses()->void:
	v_type_button.toggled.connect(v_type_toggled)
	p_type_button.toggled.connect(p_type_toggled)
	menu_mem_button.toggled.connect(menu_mem_toggled)
	batt_mem_button.toggled.connect(batt_mem_toggled)
	m_type_button.toggled.connect(m_type_button_toggled)
	opt_controls_button.pressed.connect(opt_controls_button_pressed)
	opt_close_button.pressed.connect(opt_close_button_pressed)

##Custom setup due to menu being non-linear
func setup_options_focus()->void:
	opt_music_slider.button.focus_neighbor_top = opt_close_button.get_path()
	opt_music_slider.button.focus_neighbor_bottom = v_type_button.get_path()
	opt_music_slider.button.focus_neighbor_left = opt_music_slider.button.get_path()
	opt_music_slider.button.focus_neighbor_right = opt_sfx_slider.button.get_path()
	opt_music_slider.button.focus_previous = opt_close_button.get_path()
	opt_music_slider.button.focus_next = opt_sfx_slider.button.get_path()
	
	opt_sfx_slider.button.focus_neighbor_top = opt_close_button.get_path()
	opt_sfx_slider.button.focus_neighbor_bottom = v_type_button.get_path()
	opt_sfx_slider.button.focus_neighbor_left = opt_music_slider.button.get_path()
	opt_sfx_slider.button.focus_neighbor_right = opt_voices_slider.button.get_path()
	opt_sfx_slider.button.focus_previous = opt_music_slider.button.get_path()
	opt_sfx_slider.button.focus_next = opt_voices_slider.button.get_path()

	opt_voices_slider.button.focus_neighbor_top = opt_close_button.get_path()
	opt_voices_slider.button.focus_neighbor_bottom = p_type_button.get_path()
	opt_voices_slider.button.focus_neighbor_left = opt_sfx_slider.button.get_path()
	opt_voices_slider.button.focus_neighbor_right = opt_voices_slider.button.get_path()
	opt_voices_slider.button.focus_previous = opt_sfx_slider.button.get_path()
	opt_voices_slider.button.focus_next = v_type_button.get_path()

	m_type_button.focus_neighbor_top = v_type_button.get_path()
	m_type_button.focus_neighbor_bottom = m_speed.button.get_path()
	#m_type_button.focus_neighbor_left = #self, set in inspector
	#m_type_button.focus_neighbor_right # = self, set in inspector
	m_type_button.focus_previous = opt_voices_slider.button.get_path()
	m_type_button.focus_next = m_speed.button.get_path()

	m_speed.button.focus_neighbor_top = m_type_button.get_path()
	m_speed.button.focus_neighbor_bottom = menu_mem_button.get_path()
	m_speed.button.focus_neighbor_left = m_speed.button.get_path()
	m_speed.button.focus_neighbor_right = bm_speed.button.get_path()
	m_speed.button.focus_previous = m_type_button.get_path()
	m_speed.button.focus_next = bm_speed.button.get_path()

	bm_speed.button.focus_neighbor_top = m_type_button.get_path()
	bm_speed.button.focus_neighbor_bottom = batt_mem_button.get_path()
	bm_speed.button.focus_neighbor_left = m_speed.button.get_path()
	bm_speed.button.focus_neighbor_right = bm_speed.button.get_path()
	bm_speed.button.focus_previous = m_speed.button.get_path()
	bm_speed.button.focus_next = menu_mem_button.get_path()
	
	menu_mem_button.focus_neighbor_top = m_speed.button.get_path()
	menu_mem_button.focus_neighbor_bottom = opt_controls_button.get_path()
	menu_mem_button.focus_neighbor_left = menu_mem_button.get_path()
	menu_mem_button.focus_neighbor_right = batt_mem_button.get_path()
	menu_mem_button.focus_previous = bm_speed.button.get_path()
	menu_mem_button.focus_next = batt_mem_button.get_path()
	
	batt_mem_button.focus_neighbor_top = bm_speed.button.get_path()
	batt_mem_button.focus_neighbor_bottom = opt_controls_button.get_path()
	batt_mem_button.focus_neighbor_left = menu_mem_button.get_path()
	batt_mem_button.focus_neighbor_right = batt_mem_button.get_path()
	batt_mem_button.focus_previous = menu_mem_button.get_path()
	batt_mem_button.focus_next = batt_mem_button.get_path()

##Sets the value of the music/sounds within the game
func ui_set_volume()->void:
	opt_music_slider.h_slider.value = Options.music_volume
	opt_sfx_slider.h_slider.value = Options.sfx_volume
	opt_voices_slider.h_slider.value = Options.voices_volume

##Gets voice type from Options and sets the UI to match
func ui_set_v_type()->void:
	if Options.voices_type == 1:
		v_type_label.text = "START"
		v_type_button.button_pressed = false
	else:
		v_type_label.text = "FULL"
		v_type_button.button_pressed = true

##Gets portrait type from Options and sets the UI to match
func ui_set_p_type()->void:
	if Options.portrait_type == 0:
		p_type_label.text = "TALKING"
		p_type_button.button_pressed = false
	else:
		p_type_label.text = "STILL"
		p_type_button.button_pressed = true

##Toggles voice type between FULL and START
func v_type_toggled(_toggle : bool)->void:
	if _toggle == false:
		v_type_label.text = "START"
		Options.voices_type = 1
	else:
		v_type_label.text = "FULL"
		Options.voices_type = 0

##Toggles portrait type between TALKING and STILL
func p_type_toggled(_toggle : bool)->void:
	if _toggle == false:
		p_type_label.text = "TALKING"
		Options.portrait_type = 0
	else:
		p_type_label.text = "STILL"
		Options.portrait_type = 1

##Gets menu memory and battle menu memory from Options and sets the UI to match
func ui_set_menu_memory()->void:
	if Options.menu_memory == true:
		menu_mem_button.button_pressed = true
	else:
		menu_mem_button.button_pressed = false
	if Options.battle_menu_memory == true:
		batt_mem_button.button_pressed = true
	else:
		batt_mem_button.button_pressed = false


##Sets the movement type label text 
func ui_set_move_type()->void:
	if Options.always_run == false:
		m_type_button.button_pressed = false
		m_type_label.text = "WALK OR RUN"

	else:
		m_type_button.button_pressed = true
		m_type_label.text = "ALWAYS RUN"

##Toggles move speed type
func m_type_button_toggled(_toggle : bool)->void:
	if _toggle == false:
		Options.always_run = false
		m_type_label.text = "WALK OR RUN"
		if CharDataKeeper.controlled_character:
			CharDataKeeper.controlled_character.move_speed = CharDataKeeper.controlled_character.original_move_speed
	else:
		Options.always_run = true
		m_type_label.text = "ALWAYS RUN"
		if CharDataKeeper.controlled_character:
			CharDataKeeper.controlled_character.move_speed = CharDataKeeper.controlled_character.run_speed

##Toggles (normal) menu memory on / off
func menu_mem_toggled(_toggle : bool)->void:
	if _toggle == false:
		Options.menu_memory = false
	else:
		Options.menu_memory = true

##Toggles battle menu memory on / off
func batt_mem_toggled(_toggle : bool)->void:
	if _toggle == false:
		Options.battle_menu_memory = false
	else:
		Options.battle_menu_memory = true

##Calls the options menu close function from title scene
func opt_close_button_pressed()->void:
	title_scene.options_menu_close()


##Pops up controls config window
func opt_controls_button_pressed()->void:
	pass

##Sets the slider being pressed to active
func slider_active(_slider)->void:
	current_selected_slider = _slider
	title_scene.menu_state = "OPTIONS_SLIDER"

##Sets the slider to inactive
func slider_inactive()->void:
	current_selected_slider = null
	title_scene.menu_state = "OPTIONS_MENU_OPEN"
