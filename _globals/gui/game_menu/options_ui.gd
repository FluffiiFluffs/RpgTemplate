class_name OptionsUI extends Control



#region Options Menu variables
#Options Menu
##Options Menu Music Slider (scene)
@onready var opt_music_slider : OptVolumeSlider = %OptMusicSlider
##Options menu SFX Slider (scene)
@onready var opt_sfx_slider: OptVolumeSlider = %OptSFXSlider
##Options menu voices slider (scene)
@onready var opt_voices_slider : OptVolumeSlider = %OptVoicesSlider
##Voices type label, changes with check button (FULL, START)
@onready var v_type_label : Label = %VTypeLabel
##Voices type button toggle
@onready var v_type_button : CheckButton = %VTypeButton
##Portrait type label, changes with check button (TALKING, STILL)
@onready var p_type_label : Label = %PTypeLabel
##Portrait type button toggle
@onready var p_type_button : CheckButton = %PTypeButton
##Movement type label, changes with check button (WALK OR RUN, RUN ONLY)
@onready var m_type_label : Label = %MTypeLabel
##Movement type toggle
@onready var m_type_button : CheckButton = %MTypeButton
##Message speed slider
@onready var m_speed : OptMSpeedSlider = %MSpeed
##Battle message speed slider
@onready var bm_speed : OptMSpeedSlider = %BMSpeed
##Menu memory button toggle
@onready var menu_mem_button : CheckButton = %MenuMemButton
##Battle memory button toggle
@onready var batt_mem_button : CheckButton = %BattMemButton
##Takes user to inventory sort order menu
@onready var opt_item_sort_order_button : Button = %OptItemSortOrderButton
## Takes user to the skill sort order menu
@onready var opt_skill_sort_order_button: Button = %OptSkillSortOrderButton
##Takes user to controls menu
@onready var opt_controls_button : Button = %OptControlsButton
##Takes user to in-game-stats menu
@onready var opt_in_game_stats_button : Button = %OptInGameStatsButton
##Take user to load game menu
@onready var load_game_button : Button = %LoadGameButton
##Pops up exit game confirmation.
@onready var exit_game_button : Button = %ExitGameButton
@onready var options_panel_container: PanelContainer = %OptionsPanelContainer


#endregion Options Menu variables


func _ready()->void:
	#region initialize position and visibility
	visible = true
	options_panel_container.visible = false
	options_panel_container.position = Vector2(0,-224)
	
	 #endregion initialize position and visibility
	pass

#region Options Menu

func open_options()->void:
	setup_options_menu()
	#animation_player.play("options_show")
	await options_show()
	GameMenu.menu_state = "OPTIONS_OPEN"
	GameMenu.last_top_button_focused = GameMenu.top_level.options_button
	opt_music_slider.button.grab_focus()
	GameMenu.top_level.options_button.is_active = true
	
func close_options()->void:
	#animation_player.play("options_hide")
	GameMenu.top_level.options_button.is_active = false
	await options_hide()


func options_show()->void:
	GameMenu.menu_is_animating = true
	options_panel_container.position = Vector2(0, -224)
	await GameMenu.top_level.top_menu_hide()
	options_panel_container.visible = true
	var tween = create_tween()
	tween.tween_property(options_panel_container,"position", Vector2(0,0),0.15)
	await tween.finished
	GameMenu.menu_is_animating = false
	
	pass
	
func options_hide()->void:
	GameMenu.menu_is_animating = true
	options_panel_container.position = Vector2(0,0)
	var tween = create_tween()
	tween.tween_property(options_panel_container,"position", Vector2(0, -224), 0.15)
	await tween.finished
	await GameMenu.top_level.top_menu_show()
	options_panel_container.visible = false
	GameMenu.menu_is_animating = false
	
	pass


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
	
func setup_options_buttons_presses()->void:
	v_type_button.toggled.connect(v_type_toggled)
	p_type_button.toggled.connect(p_type_toggled)
	menu_mem_button.toggled.connect(menu_mem_toggled)
	batt_mem_button.toggled.connect(batt_mem_toggled)
	m_type_button.toggled.connect(m_type_button_toggled)
	opt_item_sort_order_button.pressed.connect(opt_item_sort_order_button_pressed)
	opt_skill_sort_order_button.pressed.connect(opt_skill_sort_order_button_pressed)
	opt_controls_button.pressed.connect(opt_controls_button_pressed)
	opt_in_game_stats_button.pressed.connect(opt_in_game_stats_button_pressed)
	load_game_button.pressed.connect(load_game_button_pressed)
	exit_game_button.pressed.connect(exit_game_button_pressed)



##Custom setup due to menu being non-linear
func setup_options_focus()->void:
	opt_music_slider.button.focus_neighbor_top = opt_music_slider.button.get_path()
	opt_music_slider.button.focus_neighbor_bottom = v_type_button.get_path()
	opt_music_slider.button.focus_neighbor_left = opt_music_slider.button.get_path()
	opt_music_slider.button.focus_neighbor_right = opt_sfx_slider.button.get_path()
	opt_music_slider.button.focus_previous = opt_music_slider.button.get_path()
	opt_music_slider.button.focus_next = opt_sfx_slider.button.get_path()
	
	opt_sfx_slider.button.focus_neighbor_top = opt_sfx_slider.button.get_path()
	opt_sfx_slider.button.focus_neighbor_bottom = v_type_button.get_path()
	opt_sfx_slider.button.focus_neighbor_left = opt_music_slider.button.get_path()
	opt_sfx_slider.button.focus_neighbor_right = opt_voices_slider.button.get_path()
	opt_sfx_slider.button.focus_previous = opt_music_slider.button.get_path()
	opt_sfx_slider.button.focus_next = opt_voices_slider.button.get_path()

	opt_voices_slider.button.focus_neighbor_top = opt_voices_slider.button.get_path()
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
	menu_mem_button.focus_neighbor_bottom = opt_item_sort_order_button.get_path()
	menu_mem_button.focus_neighbor_left = menu_mem_button.get_path()
	menu_mem_button.focus_neighbor_right = batt_mem_button.get_path()
	menu_mem_button.focus_previous = bm_speed.button.get_path()
	menu_mem_button.focus_next = batt_mem_button.get_path()
	
	batt_mem_button.focus_neighbor_top = bm_speed.button.get_path()
	batt_mem_button.focus_neighbor_bottom = opt_item_sort_order_button.get_path()
	batt_mem_button.focus_neighbor_left = menu_mem_button.get_path()
	batt_mem_button.focus_neighbor_right = batt_mem_button.get_path()
	batt_mem_button.focus_previous = menu_mem_button.get_path()
	batt_mem_button.focus_next = opt_item_sort_order_button.get_path()

	opt_item_sort_order_button.focus_neighbor_top = menu_mem_button.get_path()
	opt_item_sort_order_button.focus_neighbor_bottom = opt_skill_sort_order_button.get_path()
	opt_item_sort_order_button.focus_neighbor_left = opt_item_sort_order_button.get_path()
	opt_item_sort_order_button.focus_neighbor_right = opt_item_sort_order_button.get_path()
	opt_item_sort_order_button.focus_previous = batt_mem_button.get_path()
	opt_item_sort_order_button.focus_next = opt_skill_sort_order_button.get_path()

	opt_skill_sort_order_button.focus_neighbor_top = opt_item_sort_order_button.get_path()
	opt_skill_sort_order_button.focus_neighbor_bottom = opt_controls_button.get_path()
	opt_skill_sort_order_button.focus_neighbor_left = opt_skill_sort_order_button.get_path()
	opt_skill_sort_order_button.focus_neighbor_right = opt_skill_sort_order_button.get_path()
	opt_skill_sort_order_button.focus_previous = opt_item_sort_order_button.get_path()
	opt_skill_sort_order_button.focus_next = opt_controls_button.get_path()



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

func ui_set_move_type()->void:
	if Options.always_run == false:
		m_type_button.button_pressed = false
		m_type_label.text = "WALK OR RUN"

	else:
		m_type_button.button_pressed = true
		m_type_label.text = "ALWAYS RUN"


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

func menu_mem_toggled(_toggle : bool)->void:
	if _toggle == false:
		Options.menu_memory = false
	else:
		Options.menu_memory = true

func batt_mem_toggled(_toggle : bool)->void:
	if _toggle == false:
		Options.battle_menu_memory = false
	else:
		Options.battle_menu_memory = true

##Pops up inventory sort order window
func opt_item_sort_order_button_pressed()->void:
	GameMenu.sort_order.open_sort_menu()
	pass


func opt_skill_sort_order_button_pressed()->void:
	GameMenu.sort_order.open_skill_sort_menu()
	pass

##Pops up controls config window
func opt_controls_button_pressed()->void:
	pass

##Pops up in-game stats window
func opt_in_game_stats_button_pressed()->void:
	pass

##pops up load game window
func load_game_button_pressed()->void:
	SaveManager.save_load_menu.show_saveload_menu()
	SaveManager.save_load_menu.menu_mode = SaveLoadMenu.MODE.LOAD
	SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.NONE
	GameMenu.menu_state = "OPTIONS_LOAD_MENU_OPEN"
	pass

##Pops up exit game confirmation window
func exit_game_button_pressed()->void:
	pass

func slider_active(_slider)->void:
	GameMenu.current_selected_slider = _slider
	GameMenu.menu_state = "OPTIONS_SLIDER"

func slider_inactive()->void:
	GameMenu.current_selected_slider = null
	GameMenu.menu_state = "OPTIONS_OPEN"
	
func force_close_for_load() -> void:
	options_panel_container.visible = false
	options_panel_container.position = Vector2(0, -224)
	GameMenu.current_selected_slider = null

#endregion
