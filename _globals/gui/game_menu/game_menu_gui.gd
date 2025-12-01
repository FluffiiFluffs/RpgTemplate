##game_menu_gui.gd
##global GameMenu
extends CanvasLayer



@onready var animation_player : AnimationPlayer = %AnimationPlayer
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
@onready var system_button : TopMenuButton = %SystemButton

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
#endregion

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

##Inventory screen: focuses items list so items can be used
@onready var use_items_button : InventoryOptionsButton = %UseItemsButton
##Inventory screen: sorts items automatically
@onready var sort_items_button : InventoryOptionsButton = %SortItemsButton
##Inventory screen: focuses item list so items can be reordered
@onready var reorder_items_button : InventoryOptionsButton  = %ReorderItemsButton
##Inventory screen: exits to the top menu
@onready var exit_items_button : InventoryOptionsButton  = %ExitItemsButton





#endregion


const INVENTORY_ITEM_BUTTON = preload("uid://bhfhqwlqdj6ki")
const DISABLED_COLOR = Color(0.41, 0.41, 0.41, 1.0)
const ENABLED_COLOR = Color(0.945, 0.704, 0.0, 1.0)

@export_enum("TOP_MENU_CLOSED","TOP_MENU_OPEN", "INVENTORY_OPTIONS", "USE_ITEMS", "SELECT_PARTY_MEMBER", "REORDER_ITEMS", "SELECT_ITEM", "EQUIP", "MAGIC", "STATS", "QUEST", "SYSTEM") var menu_state : int = 0

##Used to store the button that was focused before moving to another menu so it can be refocused when the menus is closed
var last_top_button_focused : TopMenuButton = null
##Stores button that is curretly focused by the UI
var current_button_focused : Button = null
var current_focused_inventory_button : InventoryItemButton = null
var current_focused_party_member : int = 0

signal select()


func _ready()->void:
	last_top_button_focused = items_button
	setup_top_menu_button_presses()
	setup_top_menu_button_neighbors()
	setup_inventory_options_buttons()

	


#region Top Menu
func top_menu_open()->void:
	animation_player.play("top_menu_show")
	#play top menu animation open
	menu_state = 1
	pass
	
func top_menu_close()->void:
	animation_player.play("top_menu_hide")
	#play top menu animation closed
	menu_state = 0
	pass

##Connects button presses for each button under ButtonHBox
func setup_top_menu_button_presses()->void:
	items_button.button.pressed.connect(on_top_items_button_pressed)
	equip_button.button.pressed.connect(on_top_equip_button_pressed)
	magic_button.button.pressed.connect(on_top_magic_button_pressed)
	stats_button.button.pressed.connect(on_top_stats_button_pressed)
	quests_button.button.pressed.connect(on_top_quests_button_pressed)
	system_button.button.pressed.connect(on_top_system_button_pressed)
	pass

func setup_top_menu_button_neighbors() -> void:
	var items_btn  : Button = items_button.button
	var equip_btn  : Button = equip_button.button
	var magic_btn  : Button = magic_button.button
	var stats_btn  : Button = stats_button.button
	var quests_btn : Button = quests_button.button
	var system_btn : Button = system_button.button

	# Items
	items_btn.focus_neighbor_top    = items_btn.get_path()
	items_btn.focus_neighbor_bottom = items_btn.get_path()
	items_btn.focus_neighbor_left   = system_btn.get_path()
	items_btn.focus_neighbor_right  = equip_btn.get_path()
	items_btn.focus_previous   = system_btn.get_path()
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
	quests_btn.focus_neighbor_right  = system_btn.get_path()
	quests_btn.focus_previous   = stats_btn.get_path()
	quests_btn.focus_next  = system_btn.get_path()

	# System
	system_btn.focus_neighbor_top    = system_btn.get_path()
	system_btn.focus_neighbor_bottom = system_btn.get_path()
	system_btn.focus_neighbor_left   = quests_btn.get_path()
	system_btn.focus_neighbor_right  = items_btn.get_path()
	system_btn.focus_previous   = quests_btn.get_path()
	system_btn.focus_next  = items_btn.get_path()	

func focus_last_top_menu_button()->void:
	last_top_button_focused.button.grab_focus()

func on_top_items_button_pressed()->void:
	open_inventory()
	pass
func on_top_equip_button_pressed()->void:
	pass
func on_top_magic_button_pressed()->void:
	pass
func on_top_stats_button_pressed()->void:
	pass
func on_top_quests_button_pressed()->void:
	pass
func on_top_system_button_pressed()->void:
	pass

##Loads party member information into the appropriate slot
func load_party()->void:
	pass


#endregion


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
	menu_state = 3 #inventory open
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


##Generates the inventory list
func generate_items_list()->void:
	#generate items list
	for i in Inventory.current_inventory:
		make_button(i)

func make_button(invslot : InventorySlot) -> void:
	var islot = invslot
	var _item = islot.item
	var new_inventory_item_button : InventoryItemButton = INVENTORY_ITEM_BUTTON.instantiate()
	items_list_v_box.add_child(new_inventory_item_button)
	new_inventory_item_button.item = _item
	new_inventory_item_button.item_button.text = str(_item.name)
	new_inventory_item_button.item_qty_label.text = str(islot.quantity)
	new_inventory_item_button.item_button.pressed.connect(select_item) #need to do this later
	new_inventory_item_button.item_button.focus_entered.connect(func button_focused()->void:
		new_inventory_item_button.self_modulate = new_inventory_item_button.focus_color
		update_item_description(islot)
		)
	new_inventory_item_button.item_button.focus_exited.connect(func button_unfocused()->void:
		new_inventory_item_button.self_modulate = new_inventory_item_button.unfocus_color
		)


func select_item(item_button : InventoryItemButton)->void:
	if !item_button.item.effects.is_empty():
		current_focused_inventory_button = item_button
		
	
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
	last_top_button_focused = items_button
	menu_state = 3
	
func on_items_sort_button_pressed()->void:
	pass
func on_items_reorder_button_pressed()->void:
	pass
func on_items_exit_pressed()->void:
	close_inventory()
	menu_state = 1
	focus_last_top_menu_button()

func close_inventory()->void:
	#play inventory close animation
	animation_player.play("inventory_hide")
	menu_state = 1 #back to top level
	#Clear items list
	clear_items_list()
	pass
	
	
func update_items_list()->void:
	#gets Inventory.current_inventory and populates ItemsListVBox
	
	pass

##Clears all items in the items list under items_list_v_box
func clear_items_list()->void:
	for child in items_list_v_box.get_children():
		items_list_v_box.remove_child(child)
		child.queue_free()
	
	pass

func update_item_description(islot:InventorySlot)->void:
	#If nothing, hide it
	if islot == null:
		description_panel.set_deferred("visible", false)
	else:
	#grab focus item's name, sprite, description, can_equip, bonus_stats
	#sets item texture, name, type, quantity, description
		var _item = islot.item
		desc_item_texture.texture = _item.menu_sprite
		desc_item_name.text = str(_item.name)
		desc_type_text.text = _item.ItemType.keys()[_item.type]
		desc_qty_text.text = str(islot.quantity)
		desc_text_label.text = _item.description
		if _item.type > 3:
			desc_equip_container.set_deferred("visible", true)
		else: 
			desc_equip_container.set_deferred("visible", false)
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
	
func sort_pressed()->void:
	#pop up menu
		#sort
		#configure sort order
	pass

func popup_sort_menu()->void:
	pass


func reorder_pressed()->void:
	#Insert item above selected item (or below?)
	pass
	
func use_button_pressed()->void:
	#focus first item in item list
	pass

func use_item()->void:
	#update items list
	pass

func focus_inventory_options()->void:
	use_items_button.button.grab_focus()


#endregion

#@export_enum("TOP_MENU_CLOSED","TOP_MENU_OPEN", "INVENTORY_OPTIONS", "INVENTORY_LIST", "EQUIP", "MAGIC", "STATS", "QUEST", "SYSTEM") var menu_state : int = 0
func _unhandled_input(_event):
	if Input.is_action_just_pressed("test3"):
		top_menu_open()
		focus_last_top_menu_button()
	if Input.is_action_just_pressed("confirm_input"):
		pass
	if Input.is_action_just_pressed("cancel_input"):
		match menu_state:
			0: #TOP_MENU_CLOSED
				return
			1: #TOP_MENU_OPEN
				top_menu_close()
				menu_state = 0
			2: #INVENTORY_OPTIONS
				#close the inventory completely
				close_inventory()
				menu_state = 1
				focus_last_top_menu_button()
			3: #INVENTORY_LIST
				focus_inventory_options()
				menu_state = 2
			4: 
				pass
			5: 
				pass
			6:
				pass
				
