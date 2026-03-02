##game_menu_gui.gd
##global GameMenu
extends CanvasLayer
##Runs the game menu in its entirety. 


#region Menu Component Scene Variables
@onready var top_level: TopLevelUI = %TopLevel
@onready var inventory: InventoryUI = %Inventory
@onready var equip: EquipUI = %Equip
@onready var skills: SkillsUI = %Skills
@onready var stats: StatsUI = %Stats
@onready var quests: QuestsUI = %Quests
@onready var options: OptionsUI = %Options
@onready var sort_order: SortOrderUI = %SortOrder
#endregion Menu Component Scene Variables


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

var menu_is_animating : bool = false


#endregion general variables

#region ready function
func _ready()->void:
	#top_level.unhide_all_positioners()
	last_top_button_focused = top_level.items_button
	top_level.setup_top_menu_button_presses()
	setup_horizontal_focus_neighbors(top_level.top_menu_button_h_box)
	inventory.setup_inventory_options_buttons()
	setup_horizontal_focus_neighbors(quests.quests_type_h_box)
	setup_horizontal_focus_neighbors(equip.equip_options_h_box)
	setup_vertical_focus_neighbors(equip.curr_equip_v_box)
	equip.setup_equip_options_button_presses()
	top_level.setup_selector()
	options.setup_options_menu()
	options.setup_options_focus()
	options.setup_options_buttons_presses()
	visible = true
#endregion ready function




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
			top_level.top_menu_open()
			top_level.focus_last_top_menu_button()
	#if GameMenu.current_selected_slider != null:
			#return
	if Input.is_action_just_pressed("cancel_input"):
		match menu_state:
			"TOP_MENU_CLOSED": #TOP_MENU_CLOSED
				return
			"TOP_MENU_OPEN":
				top_level.top_menu_close()

				menu_state = "TOP_MENU_CLOSED"
			"INVENTORY_OPTIONS":
				#close the inventory completely, open top menu
				inventory.close_inventory()
				top_level.close_to_top_menu()
			"USE_ITEMS":
				inventory.use_items_button.is_active = false
				inventory.update_inventory_options_buttons_color()
				inventory.focus_last_inventory_options_button()
				menu_state = "INVENTORY_OPTIONS"
			"USE_ITEMS_USING":
				last_selected_inventory_button.set_selected(false)
				await get_tree().process_frame
				last_selected_inventory_button.grab_button_focus()
				menu_state = "USE_ITEMS"
				pass
			"REORDER_ITEMS":
				inventory.reorder_items_button.is_active = false
				inventory.update_inventory_options_buttons_color()
				inventory.focus_last_inventory_options_button()
				menu_state = "INVENTORY_OPTIONS"
			"REORDER_ITEMS_REORDERING":
				var first_button := last_selected_inventory_button
				inventory.cancel_reorder_selection()
				if first_button != null and is_instance_valid(first_button):
					first_button.grab_button_focus()
				pass
				
			"EQUIP_PARTY_SELECT":
				top_level.close_to_top_menu()
				pass
			"EQUIP_OPTIONS":
				#animation_player.play("equip_menu_hide")
				equip.equip_menu_hide()
				menu_state = "EQUIP_PARTY_SELECT"
				top_level.focus_last_top_level_stats()
				pass
				
			"EQUIP_EQUIP_SELECT":
				menu_state = "EQUIP_OPTIONS"
				for child in equip.equip_options_h_box.get_children():
					child.is_active = false
					child.self_modulate = TRANS_COLOR
				for child in equip.curr_equip_v_box.get_children():
					if child is CurrentEquipButton:
						child.is_active = false
						child.self_modulate = TRANS_COLOR
				equip.clear_equip_equipping_list()
				equip.hide_equip_equipping_list()
				equip.hide_all_equip_differences()
				equip.equip_equip_button.grab_button_focus()
				
				pass
			"EQUIP_MENU_REMOVE":
				##return to "EQUIP_OPTIONS"
				menu_state = "EQUIP_OPTIONS"
				equip.equip_remove_button.is_active = false
				equip.equip_remove_button.self_modulate = TRANS_COLOR
				equip.equip_equip_button.grab_button_focus()
				pass
			"EQUIP_MENU_EQUIPPING":
				equip.equip_equipping_completed()

				menu_state = "EQUIP_EQUIP_SELECT"
				
				last_curr_equip_slot_button.grab_button_focus()
				equip.clear_equip_equipping_list()
				equip.hide_equip_equipping_list()
				##return to last selected curre
				pass
				
			"STATS_SELECTION":
				menu_state = "TOP_MENU_OPEN"
				top_level.stats_button.is_active = false
				top_level.focus_last_top_menu_button()
			"STATS_OPEN":
				stats.close_stats_menu()
				#menu_state = "STATS_SELECTION"
			"QUESTS_SELECT_TYPE":
				quests.close_quests_menu()
				GameMenu.top_level.close_to_top_menu()
				pass
			"QUESTS_CURRENT_QUESTS":
				quests.cancel_to_quest_type_selection()
				pass
			"QUESTS_COMPLETED_QUESTS":
				quests.cancel_to_quest_type_selection()
				pass
			"OPTIONS_OPEN":
				##close the options menu, open the top menu
				options.close_options()
				top_level.close_to_top_menu()
			"OPTIONS_SLIDER":
				#refocuses the button attached to the slider
				#handled by the button itself
				pass
			"OPTIONS_SORT_ORDER":
				sort_order.close_sort_menu()
			"OPTIONS_SORT_ORDER_SORTING":
				var idx := sort_selected_index
				sort_order.cancel_sort_selection()
				if idx >= 0:
					var slist = sort_order.sort_order_v_box.get_children()
					if idx < slist.size():
						var entry = slist[idx]
						if entry is SortOrderButton:
							(entry as SortOrderButton).grab_button_focus()
#endregion input


#region helpers
func _slot_key_from_curr_button(curr_slot_scene: CurrentEquipButton) -> int:
	if curr_slot_scene == equip.curr_main_hand:
		return Inventory.EquipSlotKey.MAINHAND
	if curr_slot_scene == equip.curr_off_hand:
		return Inventory.EquipSlotKey.OFFHAND
	if curr_slot_scene == equip.curr_head:
		return Inventory.EquipSlotKey.HEAD
	if curr_slot_scene == equip.curr_chest:
		return Inventory.EquipSlotKey.CHEST
	if curr_slot_scene == equip.curr_arms:
		return Inventory.EquipSlotKey.ARMS
	if curr_slot_scene == equip.curr_legs:
		return Inventory.EquipSlotKey.LEGS
	if curr_slot_scene == equip.curr_accy_1:
		return Inventory.EquipSlotKey.ACCESSORY_1
	if curr_slot_scene == equip.curr_accy_2:
		return Inventory.EquipSlotKey.ACCESSORY_2

	return -1

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


#endregion helpers
