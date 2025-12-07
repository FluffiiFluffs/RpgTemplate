##game_menu_gui.gd
##global GameMenu
extends CanvasLayer


#region Top Level variables
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
@onready var mp_bonus_h_box : HBoxContainer = %MPBonusHBox
##Value of MP Bonus
@onready var mp_bonus_value : Label = %MPBonusValue
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
@onready var speed_bonus_h_box : HBoxContainer = %SpeedBonusHBox
##Hbox of STR Bonus. Modulates based on bit value of item
@onready var stamina_bonus_h_box : HBoxContainer = %StaminaBonusHBox
##Value of STM Bonus
@onready var stamina_bonus_value : Label = %StaminaBonusValue
##Value of SPD bonus
@onready var speed_bonus_value : Label = %SpeedBonusValue
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



#region Options Menu
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
@onready var sort_order_positioner : Control = %SortOrderPositioner
#endregion Options Menu

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
const DISABLED_COLOR = Color("696969ff") 
const ENABLED_COLOR = Color("f1b400ff")
const TRANS_COLOR = Color("00000000")
const WHITE_COLOR = Color("ffffffff")
#endregion constants

#region Variables

@export_enum("TOP_MENU_CLOSED","TOP_MENU_OPEN", "INVENTORY_OPTIONS", "USE_ITEMS", "USE_ITEMS_USING", "SELECT_PARTY_MEMBER", "REORDER_ITEMS", "REORDER_ITEMS_REORDERING", "SELECT_ITEM", "EQUIP", "MAGIC", "STATS", "QUEST", "OPTIONS_MENU", "OPTIONS_SLIDER", "OPTIONS_SORT_ORDER", "OPTIONS_SORT_ORDER_SORTING") var menu_state : String = "TOP_MENU_CLOSED"

##Used to store the button that was focused before moving to another menu so it can be refocused when the menus is closed
var last_top_button_focused : TopMenuButton = null
##Stores button that is curretly focused by the UI
#var current_button_focused : Button = null #not used since more specific things are needed
var last_selected_inventory_options_button : InventoryOptionsButton = null
var last_selected_inventory_button : InventoryItemButton = null
#var current_focused_party_member : int = 0 #not used since the party member is held within the top_level_stats scene

var current_selected_slider : Control = null ##holds reference to the slider scene so it can refocus the button later

@export  var sort_selected_index : int = -1

#endregion variables


func _ready()->void:
	last_top_button_focused = items_button
	setup_top_menu_button_presses()
	setup_top_menu_button_neighbors()
	setup_inventory_options_buttons()
	setup_selector()
	setup_options_menu()
	setup_options_focus()
	connect_options_buttons()
	sort_order_positioner.visible = true
	


#region Top Menu
##Open top menu
func top_menu_open()->void:
	clear_top_level_stats_containers()
	setup_top_level_stats()
	visible = true
	animation_player.play("top_menu_show")
	#play top menu animation open
	menu_state = "TOP_MENU_OPEN"
	GameState.gamestate = 3 #in gamemenu
	pass

##Closes top menu
func top_menu_close()->void:
	GameState.gamestate = 1 #back to field state
	visible = false
	animation_player.play("top_menu_hide")
	#play top menu animation closed
	menu_state = "TOP_MENU_CLOSED"
	pass

##Connects button presses for each button under ButtonHBox
func setup_top_menu_button_presses()->void:
	items_button.button.pressed.connect(on_top_items_button_pressed)
	equip_button.button.pressed.connect(on_top_equip_button_pressed)
	magic_button.button.pressed.connect(on_top_magic_button_pressed)
	stats_button.button.pressed.connect(on_top_stats_button_pressed)
	quests_button.button.pressed.connect(on_top_quests_button_pressed)
	options_button.button.pressed.connect(on_top_options_button_pressed)
	pass

##Sets up TopMenuButton neighbors (manual/static, for now)
func setup_top_menu_button_neighbors() -> void:
	var items_btn  : Button = items_button.button
	var equip_btn  : Button = equip_button.button
	var magic_btn  : Button = magic_button.button
	var stats_btn  : Button = stats_button.button
	var quests_btn : Button = quests_button.button
	var options_btn : Button = options_button.button

	# Items
	items_btn.focus_neighbor_top    = items_btn.get_path()
	items_btn.focus_neighbor_bottom = items_btn.get_path()
	items_btn.focus_neighbor_left   = options_btn.get_path()
	items_btn.focus_neighbor_right  = equip_btn.get_path()
	items_btn.focus_previous   = options_btn.get_path()
	items_btn.focus_next  = equip_btn.get_path()
	
	# Equip
	equip_btn.focus_neighbor_top    = equip_btn.get_path()
	equip_btn.focus_neighbor_bottom = equip_btn.get_path()
	equip_btn.focus_neighbor_left   = items_btn.get_path()
	equip_btn.focus_neighbor_right  = magic_btn.get_path()
	equip_btn.focus_previous   = items_btn.get_path()
	equip_btn.focus_next  = magic_btn.get_path()

	# Magic
	magic_btn.focus_neighbor_top    = magic_btn.get_path()
	magic_btn.focus_neighbor_bottom = magic_btn.get_path()
	magic_btn.focus_neighbor_left   = equip_btn.get_path()
	magic_btn.focus_neighbor_right  = stats_btn.get_path()
	magic_btn.focus_previous   = equip_btn.get_path()
	magic_btn.focus_next  = stats_btn.get_path()

	# Stats
	stats_btn.focus_neighbor_top    = stats_btn.get_path()
	stats_btn.focus_neighbor_bottom = stats_btn.get_path()
	stats_btn.focus_neighbor_left   = magic_btn.get_path()
	stats_btn.focus_neighbor_right  = quests_btn.get_path()
	stats_btn.focus_previous   = magic_btn.get_path()
	stats_btn.focus_next  = quests_btn.get_path()

	# Quests
	quests_btn.focus_neighbor_top    = quests_btn.get_path()
	quests_btn.focus_neighbor_bottom = quests_btn.get_path()
	quests_btn.focus_neighbor_left   = stats_btn.get_path()
	quests_btn.focus_neighbor_right  = options_btn.get_path()
	quests_btn.focus_previous   = stats_btn.get_path()
	quests_btn.focus_next  = options_btn.get_path()

	# System
	options_btn.focus_neighbor_top    = options_btn.get_path()
	options_btn.focus_neighbor_bottom = options_btn.get_path()
	options_btn.focus_neighbor_left   = quests_btn.get_path()
	options_btn.focus_neighbor_right  = items_btn.get_path()
	options_btn.focus_previous   = quests_btn.get_path()
	options_btn.focus_next  = items_btn.get_path()	

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
	pass
##Allows user to select a party member (top_level_stats.button) and then opens an equip page based on that.
func on_top_equip_button_pressed()->void:
	pass
##Allows user to select a party member (top_level_stats.button) and then opens a magic page based on that
func on_top_magic_button_pressed()->void:
	pass
##Allows user to select party member (top_level_stats.button) and then opens a status page based on that
func on_top_stats_button_pressed()->void:
	pass
##Opens up quests page
func on_top_quests_button_pressed()->void:
	pass
##Opens the options page
func on_top_options_button_pressed()->void:
	open_options()
	pass

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

	var pmember = stats_box.party_member
	if pmember == null:
		return

	# name
	stats_box.char_name_label.text = pmember.char_resource.char_name

	# class color
	var class_col = return_class_color(pmember.char_resource.char_class)
	stats_box.set_class_color(class_col)

	# border color should match HP state
	if pmember.current_hp <= 0:
		stats_box.set_border_color_when_dead()
	else:
		stats_box.set_border_color_to_class()

	# HP and MP bars
	stats_box.hp_progress_bar.max_value = pmember.get_max_hp()
	stats_box.hp_progress_bar.value = pmember.current_hp
	stats_box.mp_progress_bar.max_value = pmember.get_max_mp()
	stats_box.mp_progress_bar.value = pmember.current_mp

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

#endregion top menu


#region Inventory
##Instantiates item buttons under items_list_v_box
func open_inventory()->void:
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
		
		if _item.mp_bonus != 0:
			mp_bonus_h_box.modulate = ENABLED_COLOR
			mp_bonus_value.text = str(_item.mp_bonus)
		else:
			mp_bonus_h_box.modulate = DISABLED_COLOR
			mp_bonus_value.text = "0"
		
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
		if _item.speed_bonus != 0:
			speed_bonus_h_box.modulate = ENABLED_COLOR
			speed_bonus_value.text = str(_item.speed_bonus)
		else:
			speed_bonus_h_box.modulate = DISABLED_COLOR
			speed_bonus_value.text = "0"
		
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


#region Options Menu

func open_options()->void:
	setup_options_menu()
	animation_player.play("options_show")
	menu_state = "OPTIONS_MENU"
	last_top_button_focused = options_button
	opt_music_slider.button.grab_focus()
	
func close_options()->void:
	animation_player.play("options_hide")
	menu_state = "TOP_MENU_OPEN"

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
	
func connect_options_buttons()->void:
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
	else:
		Options.always_run = true
		m_type_label.text = "ALWAYS RUN"

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
	menu_state = "OPTIONS_MENU"

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
	menu_state = "OPTIONS_MENU"
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

#region Audio

##Plays error sound through GameMenu's AudioStreamPlayer[br]
##TODO Need to source a sound
func play_error_sound()->void:
	#audio_stream_player.play(ERROR_SFX)
	pass

#endregion

func _unhandled_input(_event):
	if Input.is_action_just_pressed("test3"):
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
				menu_state = "TOP_MENU_OPEN"
				focus_last_top_menu_button()
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
			"OPTIONS_MENU":
				##close the options menu, open the top menu
				close_options()
				focus_last_top_menu_button()
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
