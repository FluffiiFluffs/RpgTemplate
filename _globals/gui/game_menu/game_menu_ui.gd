##game_menu_gui.gd
##global GameMenu
extends CanvasLayer
##Runs the game menu in its entirety. 



#region Top Menu variables
##Holds top menu buttons
@onready var top_menu_button_h_box : HBoxContainer= %TopMenuButtonHBox
##Text property accessed to show the name of the UI element selected (on focus)
@onready var selector_label : Label = %SelectorLabel
##Button takes player to the inventory screen
@onready var items_button : TopMenuButton = %ItemsButton
##Button takes player to the equip screen
@onready var equip_button : TopMenuButton = %EquipButton
##Button takes player to the magic screen
@onready var magic_button : TopMenuButton = %MagicButton
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

#endregion top level variables

#region Positioner Variables
@onready var top_positioner : Control = %TopPositioner
@onready var bottom_positioner : Control= %BottomPositioner
@onready var inventory_positioner_left : Control = %InventoryPositionerLeft
@onready var inventory_positioner_right : Control = %InventoryPositionerRight
@onready var equip_positioner : Control = %EquipPositioner
@onready var magic_positioner : Control = %MagicPositioner
@onready var stats_positioner : Control = %StatsPositioner
@onready var quests_positioner_left : Control = %QuestsPositionerLeft
@onready var quests_positioner_right : Control = %QuestsPositionerRight
@onready var options_positioner : Control = %OptionsPositioner
@onready var sort_order_positioner : Control = %SortOrderPositioner
#endregion positioner variables



#region Inventory Variables
##InventoryItemButtons are instantiated into this box to create inventory entries
@onready var items_list_v_box : VBoxContainer = %ItemsListVBox
##Description panel
@onready var description_panel : PanelContainer = %DescriptionPanel
##Texture of item being described
@onready var desc_item_texture : TextureRect = %DescItemTexture
##Name of item being described
@onready var desc_item_name : Label = %DescItemName
##Type of item being described
@onready var desc_type_text : Label = %DescTypeText
##Quantity of item being described
@onready var desc_qty_text : Label = %DescQtyText
##Description of item being described
@onready var desc_text_label : Label = %DescTextLabel
##Shown/Hidden if the item is a piece of equipment or not
@onready var desc_equip_container : VBoxContainer = %DescEquipContainer
##Class name of slot00. Self-Modulates depending on if the item can be used by the class
@onready var slot_00_can_use_label : Label = %Slot00CanUseLabel
##Class name of slot01. Self-Modulates depending on if the item can be used by the class
@onready var slot_01_can_use_label : Label = %Slot01CanUseLabel
##Class name of slot02. Self-Modulates depending on if the item can be used by the class
@onready var slot_02_can_use_label : Label = %Slot02CanUseLabel
##Class name of slot03. Self-Modulates depending on if the item can be used by the class
@onready var slot_03_can_use_label : Label = %Slot03CanUseLabel
##Hbox of HP Bonus. Modulates based on bit value of item
@onready var hp_bonus_h_box : HBoxContainer = %HPBonusHBox
##Value of HP Bonus
@onready var hp_bonus_value : Label = %HPBonusValue
##Hbox of MP Bonus. Modulates based on bit value of item
@onready var sp_bonus_h_box : HBoxContainer = %SPBonusHBox
##Value of MP Bonus
@onready var sp_bonus_value : Label = %SPBonusValue
##Hbox of ATK Bonus. Modulates based on bit value of item
@onready var atk_bonus_h_box : HBoxContainer = %ATKBonusHBox
##Value of ATK Bonus
@onready var atk_bonus_value : Label = %ATKBonusValue
##Hbox of DEF Bonus. Modulates based on bit value of item
@onready var def_bonus_h_box : HBoxContainer = %DEFBonusHBox
##Value of DEF Bonus
@onready var def_bonus_value : Label = %DEFBonusValue
##Hbox of STR Bonus. Modulates based on bit value of item
@onready var strength_bonus_h_box : HBoxContainer = %StrengthBonusHBox
##Value of STR Bonus
@onready var strength_bonus_value : Label = %StrengthBonusValue
##Hbox of SPD Bonus. Modulates based on bit value of item
@onready var agility_bonus_h_box : HBoxContainer = %AgilityBonusHBox
##Hbox of STR Bonus. Modulates based on bit value of item
@onready var stamina_bonus_h_box : HBoxContainer = %StaminaBonusHBox
##Value of STM Bonus
@onready var stamina_bonus_value : Label = %StaminaBonusValue
##Value of SPD bonus
@onready var agility_bonus_value : Label = %AgilityBonusValue
##Hbox of MAG Bonus. Modulates if value != 0
@onready var magic_bonus_h_box : HBoxContainer = %MagicBonusHBox
##Value of MAG Bonus
@onready var magic_bonus_value : Label = %MagicBonusValue

##Hbox containing options buttons for the inventory
@onready var inventory_options_h_box : HBoxContainer = %InventoryOptionsHBox
##Inventory screen: focuses items list so items can be used
@onready var use_items_button : InventoryOptionsButton = %UseItemsButton
##Inventory screen: sorts items automatically
@onready var sort_items_button : InventoryOptionsButton = %SortItemsButton
##Inventory screen: focuses item list so items can be reordered
@onready var reorder_items_button : InventoryOptionsButton  = %ReorderItemsButton
##Inventory screen: exits to the top menu
@onready var exit_items_button : InventoryOptionsButton  = %ExitItemsButton
#endregion inventory variables

#region equip menu variables
@onready var curr_main_hand : CurrentEquipButton = %CurrMainHand
@onready var curr_off_hand : CurrentEquipButton = %CurrOffHand
@onready var curr_head : CurrentEquipButton = %CurrHead
@onready var curr_chest : CurrentEquipButton = %CurrChest
@onready var curr_arms : CurrentEquipButton = %CurrArms
@onready var curr_legs : CurrentEquipButton = %CurrLegs
@onready var curr_accy_1 : CurrentEquipButton = %CurrAccy1
@onready var curr_accy_2 : CurrentEquipButton = %CurrAccy2
@onready var equip_panel_container : PanelContainer = %EquipPanelContainer
@onready var equip_equip_button : InventoryOptionsButton = %EquipEquipButton
@onready var equip_remove_button : InventoryOptionsButton = %EquipRemoveButton
@onready var equip_rem_all_button : InventoryOptionsButton = %EquipRemAllButton
@onready var equip_options_h_box : HBoxContainer = %EquipOptionsHBox
@onready var curr_equip_v_box : VBoxContainer = %CurrEquipVBox
@onready var equip_stats_hp : EquipStats = %EquipStatsHP
@onready var equip_stats_sp : EquipStats = %EquipStatsSP
@onready var equip_stats_atk : EquipStats = %EquipStatsATK
@onready var equip_stats_def : EquipStats = %EquipStatsDEF
@onready var equip_stats_str : EquipStats = %EquipStatsSTR
@onready var equip_stats_stm : EquipStats = %EquipStatsSTM
@onready var equip_stats_spd : EquipStats = %EquipStatsSPD
@onready var equip_stats_mag : EquipStats = %EquipStatsMAG
@onready var equip_name_label : Label = %EquipNameLabel
@onready var equip_stat_grid_container : GridContainer = %EquipStatGridContainer
@onready var equip_equipping_v_box : VBoxContainer = %EquipEquippingVBox



#endregion

#region magic menu variables
#endregion


#region stats menu variables
##Overall container for the screen. self-modulates by class color
@onready var stats_panel_container = %StatsPanelContainer
##Character name
@onready var stats_name_label = %StatsNameLabel
##Name of class
@onready var stats_class_label = %StatsClassLabel
@onready var stats_portrait_container : PanelContainer = %StatsPortraitContainer
##Shows portrait of character
@onready var stats_portrait : TextureRect = %StatsPortrait
##Level of character
@onready var stats_level_value : Label = %StatsLevelValue
##Amount of exp needed for next level
@onready var stats_next_lvl_value : Label = %StatsNextLvLValue
##Name of main hand equipment
@onready var stats_main_hand_text : Label = %StatsMainHandText
##Name of off-hand equipment
@onready var stats_off_hand_text : Label = %StatsOffHandText
##Name of head equipment
@onready var stats_head_text : Label = %StatsHeadText
##Name of chest equipment
@onready var stats_chest_text : Label = %StatsChestText
##Name of arms equipemnt
@onready var stats_arms_text = %StatsArmsText
##Name of legs equipment
@onready var stats_legs_text : Label = %StatsLegsText
##name of accy1 equipment
@onready var stats_accy_1_text : Label = %StatsAccy1Text
##Name of acc2 equipment
@onready var stats_accy_2_text : Label = %StatsAccy2Text
##Current HP value
@onready var stats_curr_hp_value : Label = %StatsCurrHPValue
##Max HP value
@onready var stats_max_hp_value : Label = %StatsMaxHPValue
##Current MP value
@onready var stats_curr_sp_value : Label = %StatsCurrSPValue
##Max MP value
@onready var stats_max_sp_value : Label = %StatsMaxSPValue
##ATK value
@onready var stats_atk_value : Label = %StatsATKValue
##DEF Value
@onready var stats_def_value : Label = %StatsDEFValue
##STR value
@onready var stats_str_value : Label = %StatsSTRValue
##STM value
@onready var stats_stm_value : Label = %StatsSTMValue
##SPD value
@onready var stats_spd_value : Label = %StatsSPDValue
##MAG value
@onready var stats_mag_value : Label = %StatsMAGValue
#endregion stats menu variables

#region quest menu variables
@onready var quests_list_v_box : VBoxContainer = %QuestsListVBox
@onready var quest_title : Label = %QuestTitle
@onready var quest_desc : Label = %QuestDesc
@onready var quest_step_desc : Label = %QuestStepDesc
@onready var quests_current_button : QuestTypeButton = %QuestsCurrentButton
@onready var quests_completed_button : QuestTypeButton = %QuestsCompletedButton
@onready var quest_desc_h_sep_1 : HSeparator = %QuestDescHSep1
@onready var quest_desc_h_sep_2 : HSeparator = %QuestDescHSep2
@onready var quests_type_h_box : HBoxContainer = %QuestsTypeHBox

#endregion quest menu variables



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
@onready var opt_sort_order_button : Button = %OptSortOrderButton
##Takes user to controls menu
@onready var opt_controls_button : Button = %OptControlsButton
##Takes user to in-game-stats menu
@onready var opt_in_game_stats_button : Button = %OptInGameStatsButton
##Take user to load game menu
@onready var load_game_button : Button = %LoadGameButton
##Pops up exit game confirmation.
@onready var exit_game_button : Button = %ExitGameButton



#SortMenu
@onready var sort_order_v_box : VBoxContainer = %SortOrderVBox

#endregion Options Menu variables

#region General Onready Variables
##Audio Stream Player for UI sounds
@onready var audio_stream_player : AudioStreamPlayer = %AudioStreamPlayer
##Animation Player for controlling what's on screen
@onready var animation_player : AnimationPlayer = %AnimationPlayer
#endregion general onready variables


#region Constants
const TOP_LEVEL_STATS = preload("uid://bw1yk70p3346y") #top level stats with button for selection.Shows party member's stats. instantiated.
const SORT_ORDER_ENTRY = preload("uid://dwhea87oe4shd") #scene with customizable name and button to be instantiated. used in options menu to determine Options.item_sort_order
const INVENTORY_ITEM_BUTTON = preload("uid://bhfhqwlqdj6ki") #scene with button. instantiated into inventory menu to allow items to be selected/used/reorderd/sorted etc
const QUEST_BUTTON = preload("uid://ddiywckqcwvou") #quest button scene for instantiation to show title of quest
const EQUIP_ITEM_BUTTON = preload("uid://d0guj5cenunp") #Instantiated for equipping items
const DISABLED_COLOR = Color("696969ff") 
const ENABLED_COLOR = Color("f1b400ff")
const TRANS_COLOR = Color("00000000")
const WHITE_COLOR = Color("ffffffff")
const MINUS_COLOR = Color("9b3800ff")

#endregion constants

#region General Variables

@export_enum("TOP_MENU_CLOSED","TOP_MENU_OPEN", "INVENTORY_OPTIONS", "USE_ITEMS", "USE_ITEMS_USING", "SELECT_PARTY_MEMBER", "REORDER_ITEMS", "REORDER_ITEMS_REORDERING", "SELECT_ITEM", "EQUIP_PARTY_SELECT","EQUIP_OPTIONS", "EQUIP_EQUIP_SELECT", "EQUIP_MENU_EQUIPPING", "EQUIP_MENU_REMOVE", "MAGIC_PARTY_SELECT", "MAGIC_SELECT_SPELL", "MAGIC_SPELL_USE_PARTY_SELECTION", "STATS_SELECTION", "STATS_OPEN", "QUESTS_SELECT_TYPE", "QUESTS_CURRENT_QUESTS", "QUESTS_COMPLETED_QUESTS", "OPTIONS_OPEN", "OPTIONS_SLIDER", "OPTIONS_SORT_ORDER", "OPTIONS_SORT_ORDER_SORTING") var menu_state : String = "TOP_MENU_CLOSED"

##Used to store the button that was focused before moving to another menu so it can be refocused when the menus is closed
var last_top_button_focused : TopMenuButton = null
##Stores button that is curretly focused by the UI
#var current_button_focused : Button = null #not used since more specific things are needed
var last_selected_inventory_options_button : InventoryOptionsButton = null

var last_selected_inventory_button : InventoryItemButton = null

var last_top_level_stats_focused : TopLevelStats = null
#var current_focused_party_member : int = 0 #not used since the party member is held within the top_level_stats scene

var last_quests_menu_state : String = "QUESTS_CURRENT_QUESTS"


var current_selected_slider : Control = null ##holds reference to the slider scene so it can refocus the button later

var sort_selected_index : int = -1

var current_selected_party_member : PartyMemberData = null

var last_curr_equip_slot_button : CurrentEquipButton = null

var equip_preview_owner : CurrentEquipButton = null

var last_selected_equip_option_button : InventoryOptionsButton = null



#endregion general variables

#region ready function
func _ready()->void:
	unhide_all_positioners()
	last_top_button_focused = items_button
	setup_top_menu_button_presses()
	setup_horizontal_focus_neighbors(top_menu_button_h_box)
	setup_inventory_options_buttons()
	setup_horizontal_focus_neighbors(quests_type_h_box)
	setup_horizontal_focus_neighbors(equip_options_h_box)
	setup_vertical_focus_neighbors(curr_equip_v_box)
	setup_equip_options_button_presses()
	setup_selector()
	setup_options_menu()
	setup_options_focus()
	setup_options_buttons_presses()
	sort_order_positioner.visible = true
	visible = false
#endregion ready function


#region Top Menu
##Open top menu on the field
func top_menu_open()->void:
	if GameState.gamestate == GameState.State.FIELD:
		SceneManager.set_field_enemies_paused(true)
		clear_top_level_stats_containers()
		setup_top_level_stats()
		visible = true
		animation_player.play("RESET")
		animation_player.play("top_menu_show")
		#play top menu animation open
		menu_state = "TOP_MENU_OPEN"
		if CharDataKeeper.controlled_character:
			CharDataKeeper.controlled_character.idle.force_idle()
		GameState.gamestate = GameState.State.GAMEMENU #in gamemenu
	pass

##Forces the top menu open, and disregards the game state.
func force_top_menu_open()->void:
	clear_top_level_stats_containers()
	setup_top_level_stats()
	visible = true
	animation_player.play("RESET")
	animation_player.play("top_menu_show")
	#play top menu animation open
	menu_state = "TOP_MENU_OPEN"
	if CharDataKeeper.controlled_character:
		CharDataKeeper.controlled_character.idle.force_idle()
	#GameState.gamestate = GameState.State.GAMEMENU #in gamemenu
	pass



##Closes top menu
func top_menu_close()->void:
	GameState.gamestate = GameState.State.FIELD #back to field state
	animation_player.play("top_menu_hide")
	await animation_player.animation_finished
	visible = false
	SceneManager.set_field_enemies_paused(false)
	#play top menu animation closed
	menu_state = "TOP_MENU_CLOSED"
	pass

##Forces the top menu closed, just in case it happens when a battle starts. 
##Called by main when battle starts
func force_menu_close_for_battle()->void:
	get_viewport().gui_release_focus()
	visible = false
	menu_state = "TOP_MENU_CLOSED"

##Connects button presses for each button under ButtonHBox
func setup_top_menu_button_presses()->void:
	items_button.button.pressed.connect(on_top_items_button_pressed)
	equip_button.button.pressed.connect(on_top_equip_button_pressed)
	magic_button.button.pressed.connect(on_top_magic_button_pressed)
	stats_button.button.pressed.connect(on_top_stats_button_pressed)
	quests_button.button.pressed.connect(on_top_quests_button_pressed)
	options_button.button.pressed.connect(on_top_options_button_pressed)

##Focuses the TopMenuButton set in last_top_menu_button (must be set manually in code)
func focus_last_top_menu_button()->void:
	last_top_button_focused.button.grab_focus()

##Connects signals to change text of selector
func setup_selector()->void:
	items_button.change_text.connect(change_selector_text)
	equip_button.change_text.connect(change_selector_text)
	magic_button.change_text.connect(change_selector_text)
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
	open_inventory()

##Allows user to select a party member (top_level_stats.button) and then opens an equip page based on that.
func on_top_equip_button_pressed()->void:
	enter_equip_selection()

##Allows user to select a party member (top_level_stats.button) and then opens a magic page based on that
func on_top_magic_button_pressed()->void:
	pass
##Allows user to select party member (top_level_stats.button) and then opens a status page based on that
func on_top_stats_button_pressed()->void:
	enter_stats_selection()

##Opens up quests page
func on_top_quests_button_pressed()->void:
	open_quests_menu()

##Opens the options page
func on_top_options_button_pressed()->void:
	open_options()


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
		var new_stats_container = TOP_LEVEL_STATS.instantiate() as TopLevelStats
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
		if last_top_level_stats_focused == null:
			for child in party_h_box_container.get_children():
				if child is TopLevelStats:
					child.grab_button_focus()
					break
		else:
			last_top_level_stats_focused.grab_button_focus()
			
func setup_horizontal_focus_neighbors(_hbox : HBoxContainer) -> void:
	var ilist := _hbox.get_children()
	var count := ilist.size()

		# Two or more entries, use wraparound for top and bottom
	for i in range(count):
		
		var child = ilist[i]
		var btn = child.button

		var left_index := (i - 1 + count) % count
		var right_index := (i + 1) % count
		var left_btn = ilist[left_index].button
		var right_btn = ilist[right_index].button

		var self_path = btn.get_path()
		btn.focus_neighbor_top = self_path
		btn.focus_neighbor_bottom = self_path
		btn.focus_neighbor_left = left_btn.get_path()
		btn.focus_neighbor_right = right_btn.get_path()
		btn.focus_previous = left_btn.get_path()
		btn.focus_next = right_btn.get_path()
		
		
func setup_vertical_focus_neighbors(_vbox : VBoxContainer)->void:
	var ilist := _vbox.get_children()
	var count := ilist.size()

		# Two or more entries, use wraparound for top and bottom
	for i in range(count):
		
		var child = ilist[i]
		var btn = child.button

		var top_index := (i - 1 + count) % count
		var bottom_index := (i + 1) % count
		var top_btn = ilist[top_index].button
		var bottom_btn = ilist[bottom_index].button

		var self_path = btn.get_path()
		btn.focus_neighbor_top = top_btn.get_path()
		btn.focus_neighbor_bottom = bottom_btn.get_path()
		btn.focus_neighbor_left = self_path
		btn.focus_neighbor_right = self_path
		btn.focus_previous = top_btn.get_path()
		btn.focus_next = bottom_btn.get_path()

##menu_state = "TOP_MENU_OPEN", last_top_button_focused = false, focus_last_top_menu_button()
func close_to_top_menu()->void:
	menu_state = "TOP_MENU_OPEN"
	last_top_button_focused.is_active = false
	focus_last_top_menu_button()
	
func unhide_all_positioners()->void:
	top_positioner.set_deferred("visible", true)	
	bottom_positioner.set_deferred("visible", true)	
	inventory_positioner_right.set_deferred("visible", true)
	inventory_positioner_left.set_deferred("visible", true)
	equip_positioner.set_deferred("visible", true)
	magic_positioner.set_deferred("visible", true)
	stats_positioner.set_deferred("visible", true)
	quests_positioner_left.set_deferred("visible", true)
	quests_positioner_right.set_deferred("visible", true)
	options_positioner.set_deferred("visible", true)
	sort_order_positioner.set_deferred("visible", true)
#endregion top menu


#region Inventory
##Instantiates item buttons under items_list_v_box
func open_inventory()->void:
	items_button.is_active = true
	#clears the items list, so it can generate a new one
	clear_items_list()
	#generates list of items
	generate_items_list()
	animation_player.play("inventory_show")
	#Sets up focus neighbors for inventory screen
	setup_inventory_focus_neighbors()
	#Grabs focus of the first inventory item if it's there, otherwise focuses exit button
	await animation_player.animation_finished
	call_deferred("focus_first_inventory_item")
		#play inventory open animation
	menu_state = "USE_ITEMS" #inventory open
	use_items_button.is_active = true
	update_inventory_options_buttons_color()
	last_selected_inventory_options_button = use_items_button
	last_top_button_focused = items_button
	pass
	
##Grabs focus of first inventory item in the list.
func focus_first_inventory_item() -> void:
	var ilist := items_list_v_box.get_children()

	# If there are no inventory items, fall back to the exit button
	if ilist.is_empty():
		if exit_items_button and exit_items_button.button:
			exit_items_button.button.grab_focus()
		return

	for child in ilist:
		if child is InventoryItemButton:
			# If InventoryItemButton has an inner button, use child.item_button
			child.item_button.grab_focus()
			return

func focus_inventory_item_index(index : int) -> void:
	var ilist := items_list_v_box.get_children()
	var count = ilist.size()

	# No inventory entries, fall back to the exit button
	if count == 0:
		if exit_items_button and exit_items_button.button:
			exit_items_button.button.grab_focus()
		return

	if index < 0:
		index = 0
	if index >= count:
		index = count - 1

	var child = ilist[index]
	if child is InventoryItemButton:
		(child as InventoryItemButton).grab_button_focus()
	else:
		# Fallback, just grab the first InventoryItemButton in the list
		for node in ilist:
			if node is InventoryItemButton:
				(node as InventoryItemButton).grab_button_focus()
				break

##Generates the inventory list
func generate_items_list()->void:
	#generate items list
	for i in Inventory.current_inventory:
		make_item_button(i)

##Makes an item button from an InventorySlot in Inventory.current_inventory
func make_item_button(invslot : InventorySlot) -> void:
	var islot = invslot
	var _item = islot.item
	var new_inventory_item_button : InventoryItemButton = INVENTORY_ITEM_BUTTON.instantiate()
	items_list_v_box.add_child(new_inventory_item_button)
	new_inventory_item_button.item = _item
	new_inventory_item_button.islot = islot
	new_inventory_item_button.self_modulate = TRANS_COLOR
	new_inventory_item_button.item_button.text = str(_item.name)
	new_inventory_item_button.item_qty_label.text = str(islot.quantity)
	
	new_inventory_item_button.item_button.pressed.connect(
		func()->void:
		select_item(new_inventory_item_button)
		new_inventory_item_button.self_modulate = ENABLED_COLOR)
		
	new_inventory_item_button.item_button.focus_entered.connect(func button_focused()->void:
		update_item_description(islot)
		if not new_inventory_item_button.is_selected:
			new_inventory_item_button.self_modulate = WHITE_COLOR
		)
		
	new_inventory_item_button.item_button.focus_exited.connect(func button_unfocused()->void:
		if not new_inventory_item_button.is_selected:
			new_inventory_item_button.self_modulate = TRANS_COLOR
		)

##does various things depending on what state the menu is in. used for InventoryItemButtons
func select_item(item_button : InventoryItemButton)->void:
	match menu_state:
		"REORDER_ITEMS":
			#stores first item selected
			last_selected_inventory_button = item_button
			#marks the selection as selected
			var ilist := items_list_v_box.get_children()
			for child in ilist:
				if child is InventoryItemButton:
					(child as InventoryItemButton).set_selected(child == item_button)
			menu_state = "REORDER_ITEMS_REORDERING"
			
		"REORDER_ITEMS_REORDERING":
			#picks second item and swaps or cancels out if the same item is selected
			if item_button == last_selected_inventory_button:
				cancel_reorder_selection()
				return
			var ilist := items_list_v_box.get_children()
			var from_index : int = ilist.find(last_selected_inventory_button)
			var to_index : int = ilist.find(item_button)
			if from_index == -1 or to_index == -1:
				cancel_reorder_selection()
				return
			_swap_inventory_slots(from_index, to_index)
			cancel_reorder_selection()
			#Updates list, and focuses new position
			update_items_list()
			var new_list := items_list_v_box.get_children()
			if to_index >= 0 and to_index < new_list.size():
				var new_button = new_list[to_index]
				if new_button is InventoryItemButton:
					(new_button as InventoryItemButton).grab_button_focus()
		"USE_ITEMS":
			# using an item from the inventory list
			# make sure there is actually a party on screen
			if party_h_box_container.get_children().is_empty():
				play_error_sound() # no party present, testing edge case
				return

			# get the item from this button
			var slot = item_button.islot
			if slot == null or slot.item == null:
				play_error_sound()
				return
			var item : Item = slot.item

			# if the item has no effects, reject immediately
			if item.effects.is_empty():
				# TODO: play "cannot use this" sound
				play_error_sound()
				return

			# find the first TopLevelStats whose member can be targeted
			var first_valid_stats : TopLevelStats = null

			for child in party_h_box_container.get_children():
				if not (child is TopLevelStats):
					continue
				var stats_box : TopLevelStats = child
				var member : PartyMemberData = stats_box.party_member
				var can_use_on_this = false

				for effect in item.effects:
					if effect == null:
						continue
					# item effects expose can_use_on_member
					if effect.can_use_on_member(member):
						can_use_on_this = true
						break

				if can_use_on_this:
					first_valid_stats = stats_box
					break

			# no valid targets
			if first_valid_stats == null:
				# the HP heal case will hit here if everyone is dead or full
				play_error_sound()
				return

			# store selected item button globally so TopLevelStats can read it
			last_selected_inventory_button = item_button

			# mark selection on the inventory list, so focus exit does not clear the highlight
			var ilist = items_list_v_box.get_children()
			for child in ilist:
				if child is InventoryItemButton:
					(child as InventoryItemButton).set_selected(child == item_button)

			# we are now in the "choose target" phase
			menu_state = "USE_ITEMS_USING"

			# focus the first valid party member's button
			first_valid_stats.grab_button_focus()
			pass
	

func setup_inventory_focus_neighbors() -> void:
	var ilist := items_list_v_box.get_children()
	var count := ilist.size()

	if count == 0:
		return

	# Only one entry, all neighbors point to itself
	if count == 1:
		var only_child = ilist[0]
		var btn = only_child.item_button
		var path = btn.get_path()
		btn.focus_neighbor_top = path
		btn.focus_neighbor_bottom = path
		btn.focus_neighbor_left = path
		btn.focus_neighbor_right = path
	else:
		# Two or more entries, use wraparound for top and bottom
		for i in range(count):
			
			var child = ilist[i]
			var btn = child.item_button

			var top_index := (i - 1 + count) % count
			var bottom_index := (i + 1) % count
			var top_btn = ilist[top_index].item_button
			var bottom_btn = ilist[bottom_index].item_button

			btn.focus_neighbor_top = top_btn.get_path()
			btn.focus_neighbor_bottom = bottom_btn.get_path()

			var self_path = btn.get_path()
			btn.focus_neighbor_left = self_path
			btn.focus_neighbor_right = self_path

	use_items_button.button.focus_neighbor_top = use_items_button.button.get_path()
	use_items_button.button.focus_neighbor_bottom = use_items_button.button.get_path()
	use_items_button.button.focus_neighbor_left = exit_items_button.button.get_path()
	use_items_button.button.focus_neighbor_right = sort_items_button.button.get_path()
	
	sort_items_button.button.focus_neighbor_top = sort_items_button.button.get_path()
	sort_items_button.button.focus_neighbor_bottom = sort_items_button.button.get_path()
	sort_items_button.button.focus_neighbor_left = use_items_button.button.get_path()
	sort_items_button.button.focus_neighbor_right = reorder_items_button.button.get_path()

	reorder_items_button.button.focus_neighbor_top = reorder_items_button.button.get_path()
	reorder_items_button.button.focus_neighbor_bottom = reorder_items_button.button.get_path()
	reorder_items_button.button.focus_neighbor_left = sort_items_button.button.get_path()
	reorder_items_button.button.focus_neighbor_right = exit_items_button.button.get_path()

	exit_items_button.button.focus_neighbor_top = exit_items_button.button.get_path()
	exit_items_button.button.focus_neighbor_bottom = exit_items_button.button.get_path()
	exit_items_button.button.focus_neighbor_left = reorder_items_button.button.get_path()
	exit_items_button.button.focus_neighbor_right = use_items_button.button.get_path()

func setup_inventory_options_buttons()->void:
		use_items_button.button.pressed.connect(on_items_use_button_pressed)
		sort_items_button.button.pressed.connect(on_items_sort_button_pressed)
		reorder_items_button.button.pressed.connect(on_items_reorder_button_pressed)
		exit_items_button.button.pressed.connect(on_items_exit_pressed)

##Focuses first item in the items list
func on_items_use_button_pressed()->void:
	var ilist := items_list_v_box.get_children()
	if ilist.is_empty():
		return
	var first_child = ilist[0]
	first_child.item_button.grab_focus()
	use_items_button.is_active = true
	update_inventory_options_buttons_color()
	last_selected_inventory_options_button = use_items_button
	menu_state = "USE_ITEMS"
	
func on_items_sort_button_pressed()->void:
	if Inventory.current_inventory.is_empty():
		return

	Inventory.sort_inventory_by_current_options()
	update_items_list()
	focus_first_inventory_item()  # this will trigger update_item_description for that slot
	last_selected_inventory_options_button = use_items_button
	use_items_button.is_active = true
	update_inventory_options_buttons_color()
	menu_state = "USE_ITEMS"

func on_items_reorder_button_pressed()->void:
	#not enough items, don't do anything
	if Inventory.current_inventory.size() < 2:
		return
	#Clears previous selection, enter reorder state
	cancel_reorder_selection()
	menu_state = "REORDER_ITEMS"
	last_selected_inventory_options_button = reorder_items_button
	reorder_items_button.is_active = true
	update_inventory_options_buttons_color()
	focus_first_inventory_item()

func update_inventory_options_buttons_color()->void:
	for child in inventory_options_h_box.get_children():
		child.set_color()
	
	
func cancel_reorder_selection()->void:
	if last_selected_inventory_button != null:
		last_selected_inventory_button.self_modulate = WHITE_COLOR
	last_selected_inventory_button = null
	var ilist := items_list_v_box.get_children()
	for child in ilist:
		if child is InventoryItemButton:
			(child as InventoryItemButton).set_selected(false)
	menu_state = "REORDER_ITEMS"
	
func on_items_exit_pressed()->void:
	close_inventory()
	menu_state = "TOP_MENU_OPEN"
	focus_last_top_menu_button()

func close_inventory()->void:
	#play inventory close animation
	animation_player.play("inventory_hide")
	menu_state = "TOP_MENU_OPEN" #back to top level
	#Clear items list
	clear_items_list()
	for child in inventory_options_h_box.get_children():
		child.is_active = false
	for child in top_menu_button_h_box.get_children():
		child.is_active = false

	
func update_items_list()->void:
	clear_items_list()
	generate_items_list()
	setup_inventory_focus_neighbors()

##Clears all items in the items list under items_list_v_box
func clear_items_list()->void:
	for child in items_list_v_box.get_children():
		items_list_v_box.remove_child(child)
		child.queue_free()

func update_item_description(islot:InventorySlot)->void:
	if islot == null:
		description_panel.set_deferred("visible", false)
		return

	# make sure it is visible again
	description_panel.set_deferred("visible", true)

	var _item = islot.item
	desc_item_texture.texture = _item.menu_sprite
	desc_item_name.text = str(_item.name)

	var type_name := ""
	for type_key in _item.ItemType:
		if _item.ItemType[type_key] == _item.type:
			type_name = String(type_key)
			break
	desc_type_text.text = type_name

	desc_qty_text.text = str(islot.quantity)
	desc_text_label.text = _item.description
	
	if _item.sort_id <= 5000:
		desc_equip_container.visible = false
	else:
		desc_equip_container.visible = true

		##checks bit value of can_equip and then sets the modulate of the label to ENABLED_COLOR or DISABLED_COLOR depending on if it can be equipped by that class
		var equip_flags = _item.can_equip
		if (equip_flags & _item.EquipClass.WARRIOR) != 0:
			slot_00_can_use_label.modulate = ENABLED_COLOR
		else:
			slot_00_can_use_label.modulate = DISABLED_COLOR
		
		if (equip_flags & Item.EquipClass.THIEF) != 0:
			slot_01_can_use_label.modulate = ENABLED_COLOR
		else:
			slot_01_can_use_label.modulate = DISABLED_COLOR
			
		if (equip_flags & Item.EquipClass.MAGE) != 0:
			slot_02_can_use_label.modulate = ENABLED_COLOR
		else:
			slot_02_can_use_label.modulate = DISABLED_COLOR
		
		if (equip_flags & Item.EquipClass.HEALER) != 0:
			slot_03_can_use_label.modulate = ENABLED_COLOR
		else:
			slot_03_can_use_label.modulate = DISABLED_COLOR
		
		if _item.hp_bonus != 0:
			hp_bonus_h_box.modulate = ENABLED_COLOR
			hp_bonus_value.text = str(_item.hp_bonus)
		else:
			hp_bonus_h_box.modulate = DISABLED_COLOR
			hp_bonus_value.text = "0"
		
		if _item.sp_bonus != 0:
			sp_bonus_h_box.modulate = ENABLED_COLOR
			sp_bonus_value.text = str(_item.sp_bonus)
		else:
			sp_bonus_h_box.modulate = DISABLED_COLOR
			sp_bonus_value.text = "0"
		
		if _item.atk_bonus != 0:
			atk_bonus_h_box.modulate = ENABLED_COLOR
			atk_bonus_value.text = str(_item.atk_bonus)
		else:
			atk_bonus_h_box.modulate = DISABLED_COLOR
			atk_bonus_value.text = "0"
		
		if _item.def_bonus != 0:
			def_bonus_h_box.modulate = ENABLED_COLOR
			def_bonus_value.text = str(_item.def_bonus)
		else:
			def_bonus_h_box.modulate = DISABLED_COLOR
			def_bonus_value.text = "0"
			
		if _item.strength_bonus != 0:
			strength_bonus_h_box.modulate = ENABLED_COLOR
			strength_bonus_value.text = str(_item.strength_bonus)
		else:
			strength_bonus_h_box.modulate = DISABLED_COLOR
			strength_bonus_value.text = "0"

		if _item.stamina_bonus != 0:
			stamina_bonus_h_box.modulate = ENABLED_COLOR
			stamina_bonus_value.text = str(_item.stamina_bonus)
		else:
			stamina_bonus_h_box.modulate = DISABLED_COLOR
			stamina_bonus_value.text = "0"
		if _item.agility_bonus != 0:
			agility_bonus_h_box.modulate = ENABLED_COLOR
			agility_bonus_value.text = str(_item.agility_bonus)
		else:
			agility_bonus_h_box.modulate = DISABLED_COLOR
			agility_bonus_value.text = "0"
		
		if _item.magic_bonus != 0:
			magic_bonus_h_box.modulate = ENABLED_COLOR
			magic_bonus_value.text = str(_item.magic_bonus)
		else:
			magic_bonus_h_box.modulate = DISABLED_COLOR
			magic_bonus_value.text = "0"
	pass

func focus_inventory_options()->void:
	use_items_button.button.grab_focus()

func focus_last_inventory_options_button()->void:
	last_selected_inventory_options_button.grab_button_focus()

func _swap_inventory_slots(a : int, b : int)->void:
	var inv = Inventory.current_inventory
	if a < 0 or a >= inv.size(): #safety check
		return
	if b < 0 or b >= inv.size(): #safety check
		return
	var tmp = inv[a]
	inv[a] = inv[b]
	inv[b] = tmp

#endregion inventory

#region Equip Menu
func enter_equip_selection()->void:
	if !party_h_box_container.get_children().is_empty():
		equip_button.is_active = true
		equip_equip_button.is_active = true
		equip_equip_button.self_modulate = ENABLED_COLOR
		last_top_button_focused = equip_button
		focus_last_top_level_stats()
		menu_state = "EQUIP_PARTY_SELECT"

func update_equip_menu_stats_labels(member : PartyMemberData)->void:
	equip_name_label.text = str(member.get_display_name())
	equip_stats_hp.equip_stats_base.text = str(member.get_max_hp())
	equip_stats_sp.equip_stats_base.text = str(member.get_max_sp())
	equip_stats_atk.equip_stats_base.text = str(member.get_atk_value())
	equip_stats_def.equip_stats_base.text = str(member.get_def_value())
	equip_stats_str.equip_stats_base.text = str(member.get_strength())
	equip_stats_stm.equip_stats_base.text = str(member.get_stamina())
	equip_stats_spd.equip_stats_base.text = str(member.get_agility())
	equip_stats_mag.equip_stats_base.text = str(member.get_magic())

func update_equip_menu_equipment_labels(member : PartyMemberData)->void:
	if member == null:
		return

	if member.mainhand != null:
		curr_main_hand.equipment_label.text = member.mainhand.name
		curr_main_hand.equipment = member.mainhand
	else:
		curr_main_hand.equipment_label.text = "EMPTY"
		curr_main_hand.equipment = null

	if member.two_handing == true and member.mainhand != null:
		curr_off_hand.equipment_label.text = member.mainhand.name
		curr_off_hand.equipment = member.mainhand
	else:
		if member.offhand != null:
			curr_off_hand.equipment_label.text = member.offhand.name
			curr_off_hand.equipment = member.offhand
		else:
			curr_off_hand.equipment_label.text = "EMPTY"
			curr_off_hand.equipment = null

	if member.headslot != null:
		curr_head.equipment_label.text = member.headslot.name
		curr_head.equipment = member.headslot
	else:
		curr_head.equipment_label.text = "EMPTY"
		curr_head.equipment = null
		
	if member.chestslot != null:
		curr_chest.equipment_label.text = member.chestslot.name
		curr_chest.equipment = member.chestslot
	else:
		curr_chest.equipment_label.text = "EMPTY"
		curr_chest.equipment = null

	if member.armslot != null:
		curr_arms.equipment_label.text = member.armslot.name
		curr_arms.equipment = member.armslot
	else:
		curr_arms.equipment_label.text = "EMPTY"
		curr_arms.equipment = null

	if member.legslot != null:
		curr_legs.equipment_label.text = member.legslot.name
		curr_legs.equipment = member.legslot
	else:
		curr_legs.equipment_label.text = "EMPTY"
		curr_legs.equipment = null

	if member.accy01 != null:
		curr_accy_1.equipment_label.text = member.accy01.name
		curr_accy_1.equipment = member.accy01
	else:
		curr_accy_1.equipment_label.text = "EMPTY"
		curr_accy_1.equipment = null

	if member.accy02 != null:
		curr_accy_2.equipment_label.text = member.accy02.name
		curr_accy_2.equipment = member.accy02
	else:
		curr_accy_2.equipment_label.text = "EMPTY"
		curr_accy_2.equipment = null



func hide_all_equip_differences() -> void:
	equip_preview_owner = null
	for child in equip_stat_grid_container.get_children():
		if child is EquipStats:
			child.hide_difference()
			child.reset_label_colors()

func cancel_equip_equipping()->void:
	curr_main_hand.grab_button_focus()
	
	menu_state = "EQUIP_EQUIP_SELECT"
	pass
	


func setup_equip_options_button_presses()->void:
	equip_equip_button.button.pressed.connect(equip_equip_button_pressed)
	equip_remove_button.button.pressed.connect(equip_remove_button_pressed)
	equip_rem_all_button.button.pressed.connect(equip_rem_all_button_pressed)
	
	
func equip_equip_button_pressed()->void:
	curr_main_hand.grab_button_focus()
	menu_state = "EQUIP_EQUIP_SELECT"
	pass
	
func equip_remove_button_pressed()->void:
	clear_equip_equipping_list()
	hide_equip_equipping_list()
	hide_all_equip_differences()

	equip_remove_button.is_active = true
	equip_equip_button.is_active = false
	curr_main_hand.grab_button_focus()
	menu_state = "EQUIP_MENU_REMOVE"
	pass

func equip_rem_all_button_pressed() -> void:
	last_selected_equip_option_button = equip_rem_all_button
	equip_rem_all_button.is_active = false
	equip_equip_button.is_active = false
	equip_remove_button.is_active = false
	update_equip_options_buttons_color()

	if current_selected_party_member == null:
		return

	clear_equip_equipping_list()
	hide_equip_equipping_list()
	hide_all_equip_differences()
	await get_tree().process_frame
	

	var res = Inventory.try_remove_all_equipment_to_inventory(current_selected_party_member)
	if res.ok == false:
		# play_error_sound()
		return
	if res.moved_count == 0:
		# play_error_sound()
		return

	update_current_equipment_buttons()

	menu_state = "EQUIP_OPTIONS"
	equip_equip_button.grab_button_focus()
	#focus_last_equip_option_button()


func make_equipping_buttons_list(eqtype : int, enter_list : bool = true)->void:
	if current_selected_party_member == null:
		return

	var member = current_selected_party_member

	var focused_slot = _get_focused_curr_equip_button()
	if focused_slot != null:
		equip_preview_owner = focused_slot

	if equip_preview_owner == null:
		equip_preview_owner = curr_main_hand

	if eqtype == Item.ItemType.OFFHAND:
		if member.mainhand != null and member.mainhand.two_hand == true:
			clear_equip_equipping_list()
			hide_equip_equipping_list()
			hide_all_equip_differences()
			if enter_list and last_curr_equip_slot_button != null:
				last_curr_equip_slot_button.is_active = false
			return

	if enter_list:
		last_curr_equip_slot_button = equip_preview_owner

	clear_equip_equipping_list()

	for islot in Inventory.current_inventory:
		if islot == null:
			continue
		if islot.item == null:
			continue

		var _item = islot.item
		if _item.type != eqtype:
			continue
		if not _item.can_be_used_by_member(member):
			continue

		make_equip_equipping_button(_item, islot, enter_list)

	var has_any = equip_equipping_v_box.get_child_count() > 0

	if enter_list:
		if last_curr_equip_slot_button != null:
			last_curr_equip_slot_button.is_active = has_any

	if has_any:
		show_equip_equipping_list()
		if enter_list:
			setup_equip_equipping_list_focus_neighbors()
			focus_first_equip_equipping()
			menu_state = "EQUIP_MENU_EQUIPPING"
	else:
		hide_equip_equipping_list()


func make_equip_equipping_button(_item : Item, _slot : InventorySlot, focusable : bool)->void:
	if _item == null:
		return
	if _slot == null:
		return

	var new_equip_button = EQUIP_ITEM_BUTTON.instantiate() as EquipItemButton
	equip_equipping_v_box.add_child(new_equip_button)

	new_equip_button.label.text = _item.name
	new_equip_button.item = _item
	new_equip_button.slot = _slot
	new_equip_button.curr_slot_scene = equip_preview_owner

	if focusable:
		new_equip_button.button.focus_mode = Control.FOCUS_ALL
	else:
		new_equip_button.button.focus_mode = Control.FOCUS_NONE



func show_equip_equipping_list()->void:
	equip_equipping_v_box.set_deferred("visible", true)

func hide_equip_equipping_list()->void:
	equip_equipping_v_box.set_deferred("visible", false)
	
func clear_equip_equipping_list() -> void:
	for child in equip_equipping_v_box.get_children():
		equip_equipping_v_box.remove_child(child)
		child.queue_free()
	
func equip_item(_item: Item, _slot: InventorySlot, curr_slot_scene: CurrentEquipButton) -> void:
	if current_selected_party_member == null:
		return
	if _slot == null:
		return
	if curr_slot_scene == null:
		return

	var slot_key = _slot_key_from_curr_button(curr_slot_scene)
	if slot_key == -1:
		# play_error_sound()
		return

	var res = Inventory.try_equip_from_inventory_slot(current_selected_party_member, _slot, slot_key)
	if res.ok == false:
		# play_error_sound()
		return

	update_current_equipment_buttons()

	clear_equip_equipping_list()
	hide_equip_equipping_list()

	menu_state = "EQUIP_EQUIP_SELECT"

	if last_curr_equip_slot_button != null:
		last_curr_equip_slot_button.is_active = false
	last_curr_equip_slot_button = curr_slot_scene
	curr_slot_scene.grab_button_focus()


func remove_equipped_item(curr_slot_scene: CurrentEquipButton) -> void:
	if current_selected_party_member == null:
		return
	if curr_slot_scene == null:
		return

	# Cache which list we should preview after the unequip.
	# Edge case: if the offhand is mirroring the mainhand due to two-handing,
	# the removed item is actually the weapon, so preview the WEAPON list.
	var preview_eqtype = _eqtype_from_curr_button(curr_slot_scene)
	var member = current_selected_party_member
	if curr_slot_scene == curr_off_hand and member != null:
		if member.two_handing == true and member.mainhand != null:
			preview_eqtype = Item.ItemType.WEAPON

	var slot_key = _slot_key_from_curr_button(curr_slot_scene)
	if slot_key == -1:
		return

	var res = Inventory.try_unequip_to_inventory(current_selected_party_member, slot_key)
	if res.ok == false:
		# play_error_sound()
		return

	update_current_equipment_buttons()

	# Refresh the equipping list preview so the player can immediately see the item
	# returned to inventory.
	if preview_eqtype != -1:
		make_equipping_buttons_list(preview_eqtype, false)

	curr_slot_scene.grab_button_focus()

func _return_equipped_item_to_inventory(item: Item) -> bool:
	if item == null:
		return false

	Inventory.add_item(item.item_id, 1)
	return true

func equip_equipping_completed()->void:
	for child in equip_options_h_box.get_children():
		child.is_active = false
		child.self_modulate = TRANS_COLOR
	for child in curr_equip_v_box.get_children():
		if child is CurrentEquipButton:
			child.is_active = false
			child.self_modulate = TRANS_COLOR
	for child in equip_stat_grid_container.get_children():
		if child is EquipStats:
			child.equip_stats_title.self_modulate = WHITE_COLOR
			child.equip_stats_base.self_modulate = WHITE_COLOR
			child.equip_plus_minus.set_deferred("visible", false)
			child.equip_stats_mod_value.set_deferred("visible", false)



func focus_first_equip_equipping()->void:
	for child in equip_equipping_v_box.get_children():
		child.grab_button_focus()

func setup_equip_equipping_list_focus_neighbors()->void:
	setup_vertical_focus_neighbors(equip_equipping_v_box)

func _get_focused_curr_equip_button() -> CurrentEquipButton:
	var node = get_viewport().gui_get_focus_owner()
	while node != null:
		if node is CurrentEquipButton:
			return node as CurrentEquipButton
		node = node.get_parent()
	return null

func update_equip_options_buttons_color() -> void:
	for child in equip_options_h_box.get_children():
		child.set_color()


func focus_last_equip_option_button() -> void:
	if last_selected_equip_option_button != null:
		last_selected_equip_option_button.grab_button_focus()
		return
	equip_equip_button.grab_button_focus()


func update_current_equipment_buttons() -> void:
	if current_selected_party_member == null:
		return

	hide_all_equip_differences()
	update_equip_menu_stats_labels(current_selected_party_member)
	update_equip_menu_equipment_labels(current_selected_party_member)

func _eqtype_from_curr_button(curr_slot_scene: CurrentEquipButton) -> int:
	if curr_slot_scene == curr_main_hand:
		return Item.ItemType.WEAPON
	if curr_slot_scene == curr_off_hand:
		return Item.ItemType.OFFHAND
	if curr_slot_scene == curr_head:
		return Item.ItemType.HEAD
	if curr_slot_scene == curr_chest:
		return Item.ItemType.CHEST
	if curr_slot_scene == curr_arms:
		return Item.ItemType.ARMS
	if curr_slot_scene == curr_legs:
		return Item.ItemType.LEGS
	if curr_slot_scene == curr_accy_1:
		return Item.ItemType.ACCESSORY
	if curr_slot_scene == curr_accy_2:
		return Item.ItemType.ACCESSORY

	return -1


#endregion equip menu

#region magic menu
#endregion magic menu

#region stats menu
func enter_stats_selection()->void:
	if !party_h_box_container.get_children().is_empty():
		stats_button.is_active = true
		last_top_button_focused = stats_button
		#Focus last/first top level stats button
		focus_last_top_level_stats()
		menu_state = "STATS_SELECTION"
	pass




func setup_stats_menu(_toplevelstats : TopLevelStats)->void:
	if _toplevelstats.party_member == null:
		return
	var _member = _toplevelstats.party_member
	stats_panel_container.self_modulate = _member.class_color
	stats_portrait.texture = _member.stats_sprite
	stats_name_label.text = _member.get_display_name()
	stats_class_label.text = _member.get_actor_class_name()
	stats_level_value.text = str(_member.level)
	
	CharDataKeeper.refresh_next_level_exp_for_member(_member)

	var level_cap : int = 99
	if CharDataKeeper != null:
		level_cap = CharDataKeeper.get_max_level()

	if _member.level >= level_cap:
		stats_next_lvl_value.text = "MAX"
	else:
		var remaining : int = _member.next_level_exp - _member.current_exp
		if remaining < 0:
			remaining = 0
		stats_next_lvl_value.text = str(remaining)
	
	
	if _member.mainhand == null:
		stats_main_hand_text.text = "EMPTY"
	else:
		stats_main_hand_text.text = _member.mainhand.name
		
	if _member.offhand == null:
		stats_off_hand_text.text = "EMPTY"
	else:
		if _member.two_handing == true:
			stats_off_hand_text.text = _member.mainhand.name
		else:
			stats_off_hand_text.text = _member.offhand.name
		
	if _member.headslot == null:
		stats_head_text.text = "EMPTY"
	else:
		stats_head_text.text = _member.headslot.name
		
	if _member.chestslot == null:
		stats_chest_text.text = "EMPTY"
	else:
		stats_chest_text.text = _member.chestslot.name
		
	if _member.armslot == null:
		stats_arms_text.text = "EMPTY"
	else:
		stats_arms_text.text = _member.armslot.name
		
	if _member.legslot == null:
		stats_legs_text.text = "EMPTY"
	else:
		stats_legs_text.text = _member.legslot.name
	
	if _member.accy01 == null:
		stats_accy_1_text.text = "EMPTY"
	else:
		stats_accy_1_text.text = _member.accy01.name
		
	if _member.accy02 == null:
		stats_accy_2_text.text = "EMPTY"
	else:
		stats_accy_2_text.text = _member.accy02.name
	
	stats_curr_hp_value.text = str(_member.current_hp)
	stats_curr_sp_value.text = str(_member.current_sp)
	stats_max_hp_value.text = str(_member.get_max_hp())
	stats_max_sp_value.text = str(_member.get_max_sp())
	stats_atk_value.text = str(_member.get_atk_value())
	stats_def_value.text = str(_member.get_def_value())
	stats_str_value.text = str(_member.get_strength())
	stats_stm_value.text = str(_member.get_stamina())
	stats_spd_value.text = str(_member.get_agility())
	stats_mag_value.text = str(_member.get_magic())


func open_stats_menu()->void:
	animation_player.play("stats_menu_show")
	menu_state = "STATS_OPEN"

	pass

func close_stats_menu()->void:
	animation_player.play("stats_menu_hide")
	menu_state = "STATS_SELECTION"
	focus_last_top_level_stats()
	pass

#endregion stats menu


#region quest menu
func open_quests_menu()->void:
	#plays menu open animation
	animation_player.play("quests_menu_show")
	#sets menu state to last_quests_menu_state ("QUESTS_CURRENT_QUESTS" by default, then changed later if user selects differently)
	menu_state = last_quests_menu_state
	last_top_button_focused = quests_button
	match last_quests_menu_state:
		"QUESTS_CURRENT_QUESTS":
			quests_current_button.is_active = true
			quests_current_button.self_modulate = ENABLED_COLOR
		"QUESTS_COMPLETED_QUESTS":
			quests_completed_button.is_active = true
			quests_completed_button.self_modulate = ENABLED_COLOR
	update_quests_list(last_quests_menu_state)
	select_first_quest_in_list()
	pass

func close_quests_menu()->void:
	#plays menu close animation
	animation_player.play("quests_menu_hide")
	clear_quests_list()
	quests_completed_button.is_active = false
	quests_current_button.is_active = false
	quests_current_button.self_modulate = TRANS_COLOR
	quests_completed_button.self_modulate = TRANS_COLOR
	pass

func open_current_quests()->void:
	clear_quests_list()
	#iterate through QuestManager.completed_quests and instantiate buttons in list
	for quest in QuestManager.current_quests:
		if quest != null:
			var new_button = QUEST_BUTTON.instantiate()
			quests_list_v_box.add_child(new_button)
			new_button.label.text = quest.quest_name
			new_button.quest = quest
	select_first_quest_in_list()
	pass

func open_completed_quests()->void:
	clear_quests_list()
	#iterate through QuestManager.completed_quests and instantiate buttons in list
	for quest in QuestManager.completed_quests:
		if quest != null:
			var new_button = QUEST_BUTTON.instantiate()
			quests_list_v_box.add_child(new_button)
			new_button.label.text = quest.quest_name
			new_button.quest = quest
	select_first_quest_in_list()
	pass


func select_first_quest_in_list()->void:
	if menu_state == "QUESTS_CURRENT_QUESTS":
		if QuestManager.current_quests.is_empty():
			quests_current_button.is_active = false
			quests_current_button.grab_button_focus()
			quest_desc_h_sep_1.visible = false
			quest_desc_h_sep_2.visible = false
			return
	elif menu_state == "QUESTS_COMPLETED_QUESTS":
		if QuestManager.completed_quests.is_empty():
			quests_completed_button.is_active = false
			quests_completed_button.grab_button_focus()
			quest_desc_h_sep_1.visible = false
			quest_desc_h_sep_2.visible = false
			return
	#find the first quest_button and focus it
	for child in quests_list_v_box.get_children():
		if child is QuestButton:
			child.grab_button_focus()
			break
		pass
	#setting focus should trigger focus_entered on the button to update the description
	pass

func cancel_to_quest_type_selection()->void:
	#unfocus current quest in list and focus either Current Quests or Complete Quests type selection button
	quests_completed_button.is_active = false
	quests_current_button.is_active = false
	quests_current_button.self_modulate = TRANS_COLOR
	quests_completed_button.self_modulate = TRANS_COLOR
	if last_quests_menu_state == "QUESTS_CURRENT_QUESTS":
		quests_current_button.grab_button_focus()
	elif last_quests_menu_state == "QUESTS_COMPLETED_QUESTS":
			quests_completed_button.grab_button_focus()
	menu_state = "QUESTS_SELECT_TYPE"
	clear_quest_description()
	#(each button should have an export variable to pass through to set last_quests_menu_state to be that when the button is pressed, clear quest list, update quest list, focus first in list)
	pass

func clear_quests_list()->void:
	#iterate through list, remove child, queue free
	for child in quests_list_v_box.get_children():
		quests_list_v_box.remove_child(child)
		child.queue_free()
	#clear description
	pass

func clear_quest_description()->void:
	quest_desc_h_sep_1.visible = false
	quest_desc_h_sep_2.visible = false
	quest_title.text = ""
	quest_desc.text = ""
	quest_step_desc.text = ""

func update_quests_list(type:String)->void: #type == last_quests_menu_state
	match type:
		"QUESTS_CURRENT_QUESTS":
			open_current_quests()
		"QUESTS_COMPLETED_QUESTS":
			open_completed_quests()
	setup_quests_focus_neighbors()

func update_quest_description(quest : Quest)->void:
	#passes quest held within quest_button to fill out the quest_description pane
	quest_desc_h_sep_1.visible = true
	quest_desc_h_sep_2.visible = true
	quest_title.text = quest.quest_name
	quest_desc.text = quest.description
	for step in quest.steps:
		if step.is_completed == true:
			continue
		else:
			quest_step_desc.text = step.description
			break


func setup_quests_focus_neighbors() -> void:
	var ilist := quests_list_v_box.get_children()
	var count := ilist.size()

	if count == 0:
		clear_quest_description()
		return

	# Only one entry, all neighbors point to itself
	if count == 1:
		var only_child = ilist[0]
		var btn = only_child.button
		var path = btn.get_path()
		btn.focus_neighbor_top = path
		btn.focus_neighbor_bottom = path
		btn.focus_neighbor_left = path
		btn.focus_neighbor_right = path
	else:
		# Two or more entries, use wraparound for top and bottom
		for i in range(count):
			
			var child = ilist[i]
			var btn = child.button

			var top_index := (i - 1 + count) % count
			var bottom_index := (i + 1) % count
			var top_btn = ilist[top_index].button
			var bottom_btn = ilist[bottom_index].button

			btn.focus_neighbor_top = top_btn.get_path()
			btn.focus_neighbor_bottom = bottom_btn.get_path()

			var self_path = btn.get_path()
			btn.focus_neighbor_left = self_path
			btn.focus_neighbor_right = self_path


#endregion quest menu

#region Options Menu

func open_options()->void:
	setup_options_menu()
	animation_player.play("options_show")
	menu_state = "OPTIONS_OPEN"
	last_top_button_focused = options_button
	opt_music_slider.button.grab_focus()
	options_button.is_active = true
	
func close_options()->void:
	animation_player.play("options_hide")


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
	opt_sort_order_button.pressed.connect(opt_sort_order_button_pressed)
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
	menu_mem_button.focus_neighbor_bottom = opt_sort_order_button.get_path()
	menu_mem_button.focus_neighbor_left = menu_mem_button.get_path()
	menu_mem_button.focus_neighbor_right = batt_mem_button.get_path()
	menu_mem_button.focus_previous = bm_speed.button.get_path()
	menu_mem_button.focus_next = batt_mem_button.get_path()
	
	batt_mem_button.focus_neighbor_top = bm_speed.button.get_path()
	batt_mem_button.focus_neighbor_bottom = opt_sort_order_button.get_path()
	batt_mem_button.focus_neighbor_left = menu_mem_button.get_path()
	batt_mem_button.focus_neighbor_right = batt_mem_button.get_path()
	batt_mem_button.focus_previous = menu_mem_button.get_path()
	batt_mem_button.focus_next = opt_sort_order_button.get_path()

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
func opt_sort_order_button_pressed()->void:
	open_sort_menu()
	pass

##Pops up controls config window
func opt_controls_button_pressed()->void:
	pass

##Pops up in-game stats window
func opt_in_game_stats_button_pressed()->void:
	pass

##pops up load game window
func load_game_button_pressed()->void:
	pass

##Pops up exit game confirmation window
func exit_game_button_pressed()->void:
	pass

func slider_active(_slider)->void:
	current_selected_slider = _slider
	menu_state = "OPTIONS_SLIDER"

func slider_inactive()->void:
	current_selected_slider = null
	menu_state = "OPTIONS_OPEN"
	
	
#endregion


#region SortOrderMenu

func open_sort_menu()->void:
	sort_order_positioner.set_deferred("visible", true)
	clear_sort_buttons()
	make_sort_buttons()
	setup_sort_order_focus_neighbors()
	focus_first_sort_button()
	animation_player.play("opt_sort_order_show")
	menu_state = "OPTIONS_SORT_ORDER"
	pass
	
func close_sort_menu()->void:
	clear_sort_buttons() ##get the buttons out of memory
	animation_player.play("opt_sort_order_hide")
	sort_selected_index = -1
	opt_sort_order_button.grab_focus()
	menu_state = "OPTIONS_OPEN"
	await animation_player.animation_finished
	sort_order_positioner.set_deferred("visible", false)
	pass


func clear_sort_buttons()->void:
	for child in sort_order_v_box.get_children():
		if child is SortOrderButton:
			sort_order_v_box.remove_child(child)
			child.queue_free()


func make_sort_buttons()->void:
	var count := Options.item_sort_order.size()
	for i in range(count):
		var category : String = Options.item_sort_order[i]

		var new_sort_button : SortOrderButton = SORT_ORDER_ENTRY.instantiate()
		
		# add to the VBox first so @onready runs
		sort_order_v_box.add_child(new_sort_button)

		# now the onready vars are valid
		new_sort_button.set_label_text(i + 1)      # int is fine here
		new_sort_button.set_button_text(category)

func setup_sort_order_focus_neighbors()->void:
	var slist := sort_order_v_box.get_children()
	var count := slist.size()

	if count == 0:
		return

	if count == 1:
		var only_child : SortOrderButton = slist[0]
		var btn : Button = only_child.sort_button
		var path : NodePath = btn.get_path()
		btn.focus_neighbor_top = path
		btn.focus_neighbor_bottom = path
		btn.focus_neighbor_left = path
		btn.focus_neighbor_right = path
		return

	for i in range(count):
		var entry : SortOrderButton = slist[i]
		var btn : Button = entry.sort_button

		var top_index : int = (i - 1 + count) % count
		var bottom_index : int = (i + 1) % count

		var top_btn : Button = (slist[top_index] as SortOrderButton).sort_button
		var bottom_btn : Button = (slist[bottom_index] as SortOrderButton).sort_button

		btn.focus_neighbor_top = top_btn.get_path()
		btn.focus_neighbor_bottom = bottom_btn.get_path()

		var self_path : NodePath = btn.get_path()
		btn.focus_neighbor_left = self_path
		btn.focus_neighbor_right = self_path



func focus_first_sort_button()->void:
	var slist := sort_order_v_box.get_children()
	if slist.size() == 0:
		return
	var first : SortOrderButton = slist[0]
	first.grab_button_focus()

func sort_order_button_pressed(button: SortOrderButton)->void:
	var slist := sort_order_v_box.get_children()
	var idx : int = slist.find(button)
	if idx == -1:
		return

	if menu_state == "OPTIONS_SORT_ORDER":
		# first selection
		sort_selected_index = idx

		for child in slist:
			if child is SortOrderButton:
				(child as SortOrderButton).set_selected(child == button)

		menu_state = "OPTIONS_SORT_ORDER_SORTING"

	elif menu_state == "OPTIONS_SORT_ORDER_SORTING":
		# second selection (or cancel if same)
		if idx == sort_selected_index:
			cancel_sort_selection()
			return

		_swap_item_sort_order(sort_selected_index, idx)
		cancel_sort_selection()

		# rebuild the list so labels stay in the right order
		clear_sort_buttons()
		make_sort_buttons()
		setup_sort_order_focus_neighbors()

		var new_list := sort_order_v_box.get_children()
		if idx >= 0 and idx < new_list.size():
			var new_button : SortOrderButton = new_list[idx]
			new_button.grab_button_focus()

func _swap_item_sort_order(a : int, b : int)->void:
	var order : Array = Options.item_sort_order.duplicate()

	if a < 0 or a >= order.size():
		return
	if b < 0 or b >= order.size():
		return

	var tmp = order[a]
	order[a] = order[b]
	order[b] = tmp

	Options.item_sort_order = order

func cancel_sort_selection()->void:
	sort_selected_index = -1
	var slist := sort_order_v_box.get_children()
	for child in slist:
		if child is SortOrderButton:
			(child as SortOrderButton).set_selected(false)
	menu_state = "OPTIONS_SORT_ORDER"



#endregion sort order menu


#endregion Options menu


#region Field Enemy Handling
##Stops processing of all enemies on the field
func field_enemy_processing_off()->void:
	if SceneManager.main_scene.current_field_scene:
		for fieldenemy in SceneManager.main_scene.current_field_scene.placed_enemies.get_children():
			if fieldenemy is FieldEnemy:
				fieldenemy.process_mode = Node.PROCESS_MODE_DISABLED
		for spawner in SceneManager.main_scene.current_field_scene.enemy_spawners.get_children():
			if spawner is EnemySpawner:
				for node in spawner.get_children():
					if node is FieldEnemy:
						node.process_mode = Node.PROCESS_MODE_DISABLED

##Enables processing of all enemies on the field
func field_enemy_processing_on()->void:
	if SceneManager.main_scene.current_field_scene:
		for fieldenemy in SceneManager.main_scene.current_field_scene.placed_enemies.get_children():
			if fieldenemy is FieldEnemy:
				fieldenemy.process_mode = Node.PROCESS_MODE_INHERIT
		for spawner in SceneManager.main_scene.current_field_scene.enemy_spawners.get_children():
			if spawner is EnemySpawner:
				for node in spawner.get_children():
					if node is FieldEnemy:
						node.process_mode = Node.PROCESS_MODE_INHERIT


#endregion Field Enemy Handling

#region Audio

##Plays error sound through GameMenu's AudioStreamPlayer[br]
##TODO Need to source a sound
func play_error_sound()->void:
	#audio_stream_player.play(ERROR_SFX)
	pass

#endregion


#region Input
func _unhandled_input(_event):
	if Input.is_action_just_pressed("test3"):
		if GameState.gamestate == GameState.State.FIELD:
			top_menu_open()
			focus_last_top_menu_button()
	#if GameMenu.current_selected_slider != null:
			#return
	if Input.is_action_just_pressed("cancel_input"):
		match menu_state:
			"TOP_MENU_CLOSED": #TOP_MENU_CLOSED
				return
			"TOP_MENU_OPEN":
				top_menu_close()

				menu_state = "TOP_MENU_CLOSED"
			"INVENTORY_OPTIONS":
				#close the inventory completely, open top menu
				close_inventory()
				close_to_top_menu()
			"USE_ITEMS":
				use_items_button.is_active = false
				update_inventory_options_buttons_color()
				focus_last_inventory_options_button()
				menu_state = "INVENTORY_OPTIONS"
			"USE_ITEMS_USING":
				last_selected_inventory_button.set_selected(false)
				await get_tree().process_frame
				last_selected_inventory_button.grab_button_focus()
				menu_state = "USE_ITEMS"
				pass
			"REORDER_ITEMS":
				reorder_items_button.is_active = false
				update_inventory_options_buttons_color()
				focus_last_inventory_options_button()
				menu_state = "INVENTORY_OPTIONS"
			"REORDER_ITEMS_REORDERING":
				var first_button := last_selected_inventory_button
				cancel_reorder_selection()
				if first_button != null and is_instance_valid(first_button):
					first_button.grab_button_focus()
				pass
				
			"EQUIP_PARTY_SELECT":
				close_to_top_menu()
				pass
			"EQUIP_OPTIONS":
				animation_player.play("equip_menu_hide")
				menu_state = "EQUIP_PARTY_SELECT"
				focus_last_top_level_stats()
				pass
				
			"EQUIP_EQUIP_SELECT":
				menu_state = "EQUIP_OPTIONS"
				for child in equip_options_h_box.get_children():
					child.is_active = false
					child.self_modulate = TRANS_COLOR
				for child in curr_equip_v_box.get_children():
					if child is CurrentEquipButton:
						child.is_active = false
						child.self_modulate = TRANS_COLOR
				clear_equip_equipping_list()
				hide_equip_equipping_list()
				hide_all_equip_differences()
				equip_equip_button.grab_button_focus()
				
				pass
			"EQUIP_MENU_REMOVE":
				##return to "EQUIP_OPTIONS"
				menu_state = "EQUIP_OPTIONS"
				equip_remove_button.is_active = false
				equip_remove_button.self_modulate = TRANS_COLOR
				equip_equip_button.grab_button_focus()
				pass
			"EQUIP_MENU_EQUIPPING":
				equip_equipping_completed()

				menu_state = "EQUIP_EQUIP_SELECT"
				
				last_curr_equip_slot_button.grab_button_focus()
				clear_equip_equipping_list()
				hide_equip_equipping_list()
				##return to last selected curre
				pass
				
			"STATS_SELECTION":
				menu_state = "TOP_MENU_OPEN"
				stats_button.is_active = false
				focus_last_top_menu_button()
			"STATS_OPEN":
				close_stats_menu()
				#menu_state = "STATS_SELECTION"
			"QUESTS_SELECT_TYPE":
				close_quests_menu()
				close_to_top_menu()
				pass
			"QUESTS_CURRENT_QUESTS":
				cancel_to_quest_type_selection()
				pass
			"QUESTS_COMPLETED_QUESTS":
				cancel_to_quest_type_selection()
				pass
			"OPTIONS_OPEN":
				##close the options menu, open the top menu
				close_options()
				close_to_top_menu()
			"OPTIONS_SLIDER":
				#refocuses the button attached to the slider
				#handled by the button itself
				pass
			"OPTIONS_SORT_ORDER":
				close_sort_menu()
			"OPTIONS_SORT_ORDER_SORTING":
				var idx := sort_selected_index
				cancel_sort_selection()
				if idx >= 0:
					var slist := sort_order_v_box.get_children()
					if idx < slist.size():
						var entry := slist[idx]
						if entry is SortOrderButton:
							(entry as SortOrderButton).grab_button_focus()
#endregion input


#region helpers
func _slot_key_from_curr_button(curr_slot_scene: CurrentEquipButton) -> int:
	if curr_slot_scene == curr_main_hand:
		return Inventory.EquipSlotKey.MAINHAND
	if curr_slot_scene == curr_off_hand:
		return Inventory.EquipSlotKey.OFFHAND
	if curr_slot_scene == curr_head:
		return Inventory.EquipSlotKey.HEAD
	if curr_slot_scene == curr_chest:
		return Inventory.EquipSlotKey.CHEST
	if curr_slot_scene == curr_arms:
		return Inventory.EquipSlotKey.ARMS
	if curr_slot_scene == curr_legs:
		return Inventory.EquipSlotKey.LEGS
	if curr_slot_scene == curr_accy_1:
		return Inventory.EquipSlotKey.ACCESSORY_1
	if curr_slot_scene == curr_accy_2:
		return Inventory.EquipSlotKey.ACCESSORY_2

	return -1

#endregion helpers
