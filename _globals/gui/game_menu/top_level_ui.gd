class_name TopLevelUI extends Control

##Holds top menu buttons
@onready var top_menu_button_h_box : HBoxContainer= %TopMenuButtonHBox
##Text property accessed to show the name of the UI element selected (on focus)
@onready var selector_label : Label = %SelectorLabel
##Button takes player to the inventory screen
@onready var items_button : TopMenuButton = %ItemsButton
##Button takes player to the equip screen
@onready var equip_button : TopMenuButton = %EquipButton
##Button takes player to the magic screen
@onready var skills_button : TopMenuButton = %SkillsButton
##Button takes player to the stats screen
@onready var stats_button : TopMenuButton = %StatsButton
##Button takes player to the quests screen
@onready var quests_button : TopMenuButton = %QuestsButton
##Button takes player to the systems screen
@onready var options_button :TopMenuButton= %OptionsButton

##Text property accessed to show amount of money player has
@onready var money_value_label = %MoneyValueLabel
##Hbox holding TopLevelStats scenes for each party member in the party
@onready var party_h_box_container = %PartyHBoxContainer
##Slot00 Name, Level, HP, MP, Buffs
@onready var toplevel_stats_1 : TopLevelStats = %ToplevelStats1
##Slot01 Name, Level, HP, MP, Buffs
@onready var toplevel_stats_2 : TopLevelStats = %ToplevelStats2
##Slot02 Name, Level, HP, MP, Buffs
@onready var toplevel_stats_3 : TopLevelStats = %ToplevelStats3
##Slot03 Name, Level, HP, MP, Buffs
@onready var toplevel_stats_4 : TopLevelStats = %ToplevelStats4
@onready var top_positioner: Control = %TopPositioner
@onready var bottom_positioner: Control = %BottomPositioner
@onready var money_h_box: HBoxContainer = %MoneyHBox


func _ready()->void:
	#region Set up positions + visibility
	visible = true
	top_positioner.position = Vector2(0,-52)
	bottom_positioner.position = Vector2(200, 284)
	top_positioner.visible = false
	bottom_positioner.visible = false
	#endregion Set up positions + visibility
	pass





#region Top Menu
##Open top menu on the field
func top_menu_open()->void:
	if GameState.gamestate == GameState.State.FIELD:
		SceneManager.set_field_enemies_paused(true)
		clear_top_level_stats_containers()
		setup_top_level_stats()
		top_menu_show()
		visible = true
		#play top menu animation open
		GameMenu.menu_state = "TOP_MENU_OPEN"
		if CharDataKeeper.controlled_character:
			CharDataKeeper.controlled_character.idle.force_idle()
		GameState.gamestate = GameState.State.GAMEMENU #in gamemenu
	pass

##Forces the top menu open, and disregards the game state.
func force_top_menu_open()->void:
	clear_top_level_stats_containers()
	setup_top_level_stats()
	visible = true
	top_menu_show()
	#play top menu animation open
	GameMenu.menu_state = "TOP_MENU_OPEN"
	if CharDataKeeper.controlled_character:
		CharDataKeeper.controlled_character.idle.force_idle()
	#GameState.gamestate = GameState.State.GAMEMENU #in gamemenu
	pass



##Closes top menu
func top_menu_close()->void:
	GameState.gamestate = GameState.State.FIELD #back to field state
	await top_menu_hide()
	SceneManager.set_field_enemies_paused(false)
	#play top menu animation closed
	GameMenu.menu_state = "TOP_MENU_CLOSED"
	pass

##Forces the top menu closed, just in case it happens when a battle starts. 
##Called by main when battle starts
func force_menu_close_for_battle()->void:
	get_viewport().gui_release_focus()
	visible = false
	GameMenu.menu_state = "TOP_MENU_CLOSED"

##Connects button presses for each button under ButtonHBox
func setup_top_menu_button_presses()->void:
	items_button.button.pressed.connect(on_top_items_button_pressed)
	equip_button.button.pressed.connect(on_top_equip_button_pressed)
	skills_button.button.pressed.connect(on_top_skills_button_pressed)
	stats_button.button.pressed.connect(on_top_stats_button_pressed)
	quests_button.button.pressed.connect(on_top_quests_button_pressed)
	options_button.button.pressed.connect(on_top_options_button_pressed)

##Focuses the TopMenuButton set in last_top_menu_button (must be set manually in code)
func focus_last_top_menu_button()->void:
	GameMenu.last_top_button_focused.button.grab_focus()

## Tween animation for showing the top menu
func top_menu_show()->void:
	GameMenu.menu_is_animating = true
	top_positioner.position = Vector2(0, -52)
	bottom_positioner.position = Vector2(200, 284)
	money_h_box.modulate = Color(1.0, 1.0, 1.0, 0.0)
	top_positioner.visible = true
	bottom_positioner.visible = true
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(top_positioner, "position", Vector2(0,0), 0.15)
	tween.tween_property(bottom_positioner, "position", Vector2(200, 220), 0.15)
	await tween.finished
	var tween2 = create_tween()
	tween2.tween_property(money_h_box, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	GameMenu.menu_is_animating = false


# Tween animation for hiding the top menu
func top_menu_hide()->void:
	GameMenu.menu_is_animating = true
	top_positioner.position = Vector2(0, 0)
	bottom_positioner.position = Vector2(200, 220)
	money_h_box.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(top_positioner, "position", Vector2(0,-52), 0.15)
	tween.tween_property(bottom_positioner, "position", Vector2(200, 284), 0.15)
	await tween.finished
	top_positioner.visible = false
	bottom_positioner.visible = false
	GameMenu.menu_is_animating = false


## Shows only the bottom positioner, top positioner moves away
func top_level_bottom_only()->void:
	GameMenu.menu_is_animating = true
	top_positioner.position = Vector2(0, 0)
	bottom_positioner.position = Vector2(200, 220)
	money_h_box.modulate = Color(1.0, 1.0, 1.0, 0.0)
	top_positioner.visible = true
	bottom_positioner.visible = true
	var tween = create_tween()
	tween.tween_property(top_positioner, "position", Vector2(0,-52), 0.15)
	await tween.finished
	GameMenu.menu_is_animating = false
	pass
	
## Returns the top positioner when only the bottom positioner was shown
func top_level_bottom_only_return()->void:
	GameMenu.menu_is_animating = true
	top_positioner.position = Vector2(0, -52)
	bottom_positioner.position = Vector2(200, 220)
	money_h_box.modulate = Color(1.0, 1.0, 1.0, 0.0)
	top_positioner.visible = true
	bottom_positioner.visible = true
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(top_positioner, "position", Vector2(0,0), 0.15)
	await tween.finished
	var tween2 = create_tween()
	tween2.tween_property(money_h_box, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	GameMenu.menu_is_animating = false
	pass



##Connects signals to change text of selector
func setup_selector()->void:
	items_button.change_text.connect(change_selector_text)
	equip_button.change_text.connect(change_selector_text)
	skills_button.change_text.connect(change_selector_text)
	stats_button.change_text.connect(change_selector_text)
	quests_button.change_text.connect(change_selector_text)
	options_button.change_text.connect(change_selector_text)

##changes the selector_label's text to match the TopMenuButton's exported text.[br]
##Signal change_text emits the export variable and is used as an argument in this function[br]
##Signal is emitted upon focus_entered
func change_selector_text(_text : String) ->void:
	selector_label.text = _text

##Opens inventory and focuses first item in inventory
func on_top_items_button_pressed()->void:
	GameMenu.inventory.open_inventory()

##Allows user to select a party member (top_level_stats.button) and then opens an equip page based on that.
func on_top_equip_button_pressed()->void:
	GameMenu.equip.enter_equip_selection()

##Allows user to select a party member (top_level_stats.button) and then opens a magic page based on that
func on_top_skills_button_pressed()->void:
	pass
	
##Allows user to select party member (top_level_stats.button) and then opens a status page based on that
func on_top_stats_button_pressed()->void:
	GameMenu.stats.enter_stats_selection()

##Opens up quests page
func on_top_quests_button_pressed()->void:
	GameMenu.quests.open_quests_menu()

##Opens the options page
func on_top_options_button_pressed()->void:
	GameMenu.options.open_options()


##Loads party member information into the appropriate slot
func load_party()->void:
	pass

##clears the party's top level stat containers
func clear_top_level_stats_containers()->void:
	for child in party_h_box_container.get_children():
		party_h_box_container.remove_child(child)
		child.queue_free()

##Instantiates top level stats scenes
func setup_top_level_stats()->void:
	for member in CharDataKeeper.party_members:
		var new_stats_container = GameMenu.TOP_LEVEL_STATS.instantiate() as TopLevelStats
		new_stats_container.party_member = member
		party_h_box_container.call_deferred("add_child", new_stats_container)
		await get_tree().process_frame
		update_top_level_stats_box(new_stats_container)
		setup_top_level_stats_button_neighbors()

func update_top_level_stats_box(stats_box) -> void:
	if stats_box == null:
		return

	var pmember = stats_box.party_member as PartyMemberData
	if pmember == null:
		return

	# name
	stats_box.char_name_label.text = pmember.get_display_name()

	# class color
	stats_box.class_color = pmember.class_color
	stats_box.set_class_color(stats_box.class_color)

	# border color should match HP state
	if pmember.current_hp <= 0:
		stats_box.set_border_color_when_dead()
	else:
		stats_box.set_border_color_to_class()

	# HP and MP bars
	stats_box.hp_progress_bar.max_value = pmember.get_max_hp()
	stats_box.hp_progress_bar.value = pmember.current_hp
	stats_box.sp_progress_bar.max_value = pmember.get_max_sp()
	stats_box.sp_progress_bar.value = pmember.current_sp

	stats_box.update_buffs()

func setup_top_level_stats_button_neighbors() -> void:
	var stats_boxes: Array[TopLevelStats] = []

	# Collect only TopLevelStats children, in order
	for child in party_h_box_container.get_children():
		if child is TopLevelStats:
			stats_boxes.append(child)

	var count = stats_boxes.size()
	if count == 0:
		return

	# Only one entry, everything points to itself
	if count == 1:
		var only_stats: TopLevelStats = stats_boxes[0]
		var _button: Button = only_stats.button
		var path = _button.get_path()

		_button.focus_neighbor_top = path
		_button.focus_neighbor_bottom = path
		_button.focus_neighbor_left = path
		_button.focus_neighbor_right = path
		return

	# Two or more entries, use wrap for left and right
	for i in range(count):
		var stats_box: TopLevelStats = stats_boxes[i]
		var _button: Button = stats_box.button
		if _button == null:
			continue

		var prev_index = (i - 1 + count) % count
		var next_index = (i + 1) % count

		var prev_button: Button = stats_boxes[prev_index].button
		var next_button: Button = stats_boxes[next_index].button

		var self_path = _button.get_path()
		_button.focus_neighbor_top = self_path
		_button.focus_neighbor_bottom = self_path
		_button.focus_neighbor_left = prev_button.get_path()
		_button.focus_neighbor_right = next_button.get_path()

func return_class_color(classnum : int)->Color:
	match classnum:
		0:
			return Options.class_color_warrior
		1:
			return Options.class_color_thief
		2:
			return Options.class_color_mage
		3:
			return Options.class_color_healer
		_:
			return Color(1.0, 1.0, 1.0, 1.0)

func focus_last_top_level_stats()->void:
	if !party_h_box_container.get_children().is_empty():
		if GameMenu.last_top_level_stats_focused == null:
			for child in party_h_box_container.get_children():
				if child is TopLevelStats:
					child.grab_button_focus()
					break
		else:
			GameMenu.last_top_level_stats_focused.grab_button_focus()
			

##menu_state = "TOP_MENU_OPEN", last_top_button_focused = false, focus_last_top_menu_button()
func close_to_top_menu()->void:
	GameMenu.menu_state = "TOP_MENU_OPEN"
	GameMenu.last_top_button_focused.is_active = false
	focus_last_top_menu_button()

#func unhide_all_positioners()->void:
	#top_positioner.set_deferred("visible", true)	
	#bottom_positioner.set_deferred("visible", true)	
	#inventory_positioner_right.set_deferred("visible", true)
	#inventory_positioner_left.set_deferred("visible", true)
	#equip_positioner.set_deferred("visible", true)
	#magic_positioner.set_deferred("visible", true)
	#stats_positioner.set_deferred("visible", true)
	#quests_positioner_left.set_deferred("visible", true)
	#quests_positioner_right.set_deferred("visible", true)
	#options_positioner.set_deferred("visible", true)
	#sort_order_positioner.set_deferred("visible", true)
	
	
func force_close_for_load() -> void:
	# Closed visual state, no tweens.
	top_positioner.position = Vector2(0, -52)
	bottom_positioner.position = Vector2(200, 284)
	money_h_box.modulate = Color(1.0, 1.0, 1.0, 0.0)

	top_positioner.visible = false
	bottom_positioner.visible = false

	for child in top_menu_button_h_box.get_children():
		if child is TopMenuButton:
			var top_button := child as TopMenuButton
			top_button.is_active = false
			top_button.self_modulate = GameMenu.WHITE_COLOR

			if top_button.button != null:
				top_button.button.icon = top_button.unselected
#endregion top menu
