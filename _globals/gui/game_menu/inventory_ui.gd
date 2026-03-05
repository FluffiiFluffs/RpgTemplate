class_name InventoryUI extends Control



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
@onready var hider: PanelContainer = %Hider
@onready var inventory_positioner_left: Control = %InventoryPositionerLeft
@onready var inventory_positioner_right: Control = %InventoryPositionerRight
@onready var item_list_panel: PanelContainer = %ItemListPanel


func _ready()->void:
	hider.queue_free()	#this is only here for editor spacing purposes
	#region initialize positions and visiblity
	visible = true
	item_list_panel.visible = false
	item_list_panel.position = Vector2(-200, 0)
	description_panel.visible = false
	description_panel.position = Vector2(200, 0)
	
	
	#endregion initialize positions and visibility


#region Inventory
##Instantiates item buttons under items_list_v_box
func open_inventory()->void:
	GameMenu.top_level.items_button.is_active = true
	#clears the items list, so it can generate a new one
	clear_items_list()
	#generates list of items
	generate_items_list()
	#Sets up focus neighbors for inventory screen
	setup_inventory_focus_neighbors()
	update_inventory_options_buttons_color()
	#Grabs focus of the first inventory item if it's there, otherwise focuses exit button
	call_deferred("focus_first_inventory_item")
	
	await inventory_show() #play inventory open animation
	GameMenu.menu_state = "USE_ITEMS" #inventory open
	use_items_button.is_active = true
	GameMenu.last_selected_inventory_options_button = use_items_button
	GameMenu.last_top_button_focused = GameMenu.top_level.items_button
	pass
	
func inventory_show()->void:
	GameMenu.menu_is_animating = true
	await GameMenu.top_level.top_level_bottom_only() #Shows just the party's stats box area
	item_list_panel.position = Vector2(-200, 0)
	description_panel.position = Vector2(200, 0)
	item_list_panel.visible = true
	description_panel.visible = true
	var tween = create_tween().set_parallel()
	tween.tween_property(item_list_panel, "position", Vector2(0,0), 0.15)
	tween.tween_property(description_panel, "position", Vector2(0, 0), 0.15)
	await tween.finished
	GameMenu.menu_is_animating = false


func inventory_hide()->void:
	GameMenu.menu_is_animating = true
	item_list_panel.position = Vector2(0,0)
	description_panel.position = Vector2(0,0)
	var tween = create_tween().set_parallel()
	tween.tween_property(item_list_panel, "position", Vector2(-200,0), 0.15)
	tween.tween_property(description_panel, "position", Vector2(200, 0), 0.15)
	await tween.finished
	item_list_panel.visible = false
	description_panel.visible = false
	await GameMenu.top_level.top_level_bottom_only_return()
	GameMenu.menu_is_animating = false
	
	
	
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
	var new_inventory_item_button : InventoryItemButton = GameMenu.INVENTORY_ITEM_BUTTON.instantiate()
	items_list_v_box.add_child(new_inventory_item_button)
	new_inventory_item_button.item = _item
	new_inventory_item_button.islot = islot
	new_inventory_item_button.self_modulate = GameMenu.TRANS_COLOR
	new_inventory_item_button.item_button.text = str(_item.name)
	new_inventory_item_button.item_qty_label.text = str(islot.quantity)
	
	new_inventory_item_button.item_button.pressed.connect(
		func()->void:
		select_item(new_inventory_item_button)
		new_inventory_item_button.self_modulate = GameMenu.ENABLED_COLOR
		AudioManager.play_ui_confirm())
		
	new_inventory_item_button.item_button.focus_entered.connect(func button_focused()->void:
		update_item_description(islot)
		if not new_inventory_item_button.is_selected:
			new_inventory_item_button.self_modulate = GameMenu.WHITE_COLOR
		)
		
	new_inventory_item_button.item_button.focus_exited.connect(func button_unfocused()->void:
		if not new_inventory_item_button.is_selected:
			new_inventory_item_button.self_modulate = GameMenu.TRANS_COLOR
		)

##does various things depending on what state the menu is in. used for InventoryItemButtons
func select_item(item_button : InventoryItemButton)->void:
	match GameMenu.menu_state:
		"REORDER_ITEMS":
			#stores first item selected
			GameMenu.last_selected_inventory_button = item_button
			#marks the selection as selected
			var ilist := items_list_v_box.get_children()
			for child in ilist:
				if child is InventoryItemButton:
					(child as InventoryItemButton).set_selected(child == item_button)
			GameMenu.menu_state = "REORDER_ITEMS_REORDERING"
			
		"REORDER_ITEMS_REORDERING":
			#picks second item and swaps or cancels out if the same item is selected
			if item_button == GameMenu.last_selected_inventory_button:
				cancel_reorder_selection()
				return
			var ilist := items_list_v_box.get_children()
			var from_index : int = ilist.find(GameMenu.last_selected_inventory_button)
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
			if GameMenu.top_level.party_h_box_container.get_children().is_empty():
				GameMenu.play_error_sound() # no party present, testing edge case
				return

			# get the item from this button
			var slot = item_button.islot
			if slot == null or slot.item == null:
				GameMenu.play_error_sound()
				return
			var item : Item = slot.item

			# if the item has no effects, reject immediately
			if item.effects.is_empty():
				# TODO: play "cannot use this" sound
				GameMenu.play_error_sound()
				return

			# find the first TopLevelStats whose member can be targeted
			var first_valid_stats : TopLevelStats = null

			for child in GameMenu.top_level.party_h_box_container.get_children():
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
				GameMenu.play_error_sound()
				return

			# store selected item button globally so TopLevelStats can read it
			GameMenu.last_selected_inventory_button = item_button

			# mark selection on the inventory list, so focus exit does not clear the highlight
			var ilist = items_list_v_box.get_children()
			for child in ilist:
				if child is InventoryItemButton:
					(child as InventoryItemButton).set_selected(child == item_button)

			# we are now in the "choose target" phase
			GameMenu.menu_state = "USE_ITEMS_USING"

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
	GameMenu.last_selected_inventory_options_button = use_items_button
	GameMenu.menu_state = "USE_ITEMS"
	
func on_items_sort_button_pressed()->void:
	if Inventory.current_inventory.is_empty():
		return

	Inventory.sort_inventory_by_current_options()
	update_items_list()
	focus_first_inventory_item()  # this will trigger update_item_description for that slot
	GameMenu.last_selected_inventory_options_button = use_items_button
	use_items_button.is_active = true
	update_inventory_options_buttons_color()
	GameMenu.menu_state = "USE_ITEMS"

func on_items_reorder_button_pressed()->void:
	#not enough items, don't do anything
	if Inventory.current_inventory.size() < 2:
		return
	#Clears previous selection, enter reorder state
	cancel_reorder_selection()
	GameMenu.menu_state = "REORDER_ITEMS"
	GameMenu.last_selected_inventory_options_button = reorder_items_button
	reorder_items_button.is_active = true
	update_inventory_options_buttons_color()
	focus_first_inventory_item()

func update_inventory_options_buttons_color()->void:
	for child in inventory_options_h_box.get_children():
		child.set_color()
	
	
func cancel_reorder_selection()->void:
	if GameMenu.last_selected_inventory_button != null:
		GameMenu.last_selected_inventory_button.self_modulate = GameMenu.WHITE_COLOR
	GameMenu.last_selected_inventory_button = null
	var ilist := items_list_v_box.get_children()
	for child in ilist:
		if child is InventoryItemButton:
			(child as InventoryItemButton).set_selected(false)
	GameMenu.menu_state = "REORDER_ITEMS"
	
func on_items_exit_pressed()->void:
	close_inventory()
	GameMenu.menu_state = "TOP_MENU_OPEN"
	GameMenu.top_level.focus_last_top_menu_button()

func close_inventory()->void:
	#play inventory close animation
	#animation_player.play("inventory_hide")
	await inventory_hide()
	GameMenu.menu_state = "TOP_MENU_OPEN" #back to top level
	#Clear items list
	clear_items_list()
	for child in inventory_options_h_box.get_children():
		child.is_active = false
	for child in GameMenu.top_level.top_menu_button_h_box.get_children():
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
			slot_00_can_use_label.modulate = GameMenu.ENABLED_COLOR
		else:
			slot_00_can_use_label.modulate = GameMenu.DISABLED_COLOR
		
		if (equip_flags & Item.EquipClass.THIEF) != 0:
			slot_01_can_use_label.modulate = GameMenu.ENABLED_COLOR
		else:
			slot_01_can_use_label.modulate = GameMenu.DISABLED_COLOR
			
		if (equip_flags & Item.EquipClass.MAGE) != 0:
			slot_02_can_use_label.modulate = GameMenu.ENABLED_COLOR
		else:
			slot_02_can_use_label.modulate = GameMenu.DISABLED_COLOR
		
		if (equip_flags & Item.EquipClass.HEALER) != 0:
			slot_03_can_use_label.modulate = GameMenu.ENABLED_COLOR
		else:
			slot_03_can_use_label.modulate = GameMenu.DISABLED_COLOR
		
		if _item.hp_bonus != 0:
			hp_bonus_h_box.modulate = GameMenu.ENABLED_COLOR
			hp_bonus_value.text = str(_item.hp_bonus)
		else:
			hp_bonus_h_box.modulate = GameMenu.DISABLED_COLOR
			hp_bonus_value.text = "0"
		
		if _item.sp_bonus != 0:
			sp_bonus_h_box.modulate = GameMenu.ENABLED_COLOR
			sp_bonus_value.text = str(_item.sp_bonus)
		else:
			sp_bonus_h_box.modulate = GameMenu.DISABLED_COLOR
			sp_bonus_value.text = "0"
		
		if _item.atk_bonus != 0:
			atk_bonus_h_box.modulate = GameMenu.ENABLED_COLOR
			atk_bonus_value.text = str(_item.atk_bonus)
		else:
			atk_bonus_h_box.modulate = GameMenu.DISABLED_COLOR
			atk_bonus_value.text = "0"
		
		if _item.def_bonus != 0:
			def_bonus_h_box.modulate = GameMenu.ENABLED_COLOR
			def_bonus_value.text = str(_item.def_bonus)
		else:
			def_bonus_h_box.modulate = GameMenu.DISABLED_COLOR
			def_bonus_value.text = "0"
			
		if _item.strength_bonus != 0:
			strength_bonus_h_box.modulate = GameMenu.ENABLED_COLOR
			strength_bonus_value.text = str(_item.strength_bonus)
		else:
			strength_bonus_h_box.modulate = GameMenu.DISABLED_COLOR
			strength_bonus_value.text = "0"

		if _item.stamina_bonus != 0:
			stamina_bonus_h_box.modulate = GameMenu.ENABLED_COLOR
			stamina_bonus_value.text = str(_item.stamina_bonus)
		else:
			stamina_bonus_h_box.modulate = GameMenu.DISABLED_COLOR
			stamina_bonus_value.text = "0"
		if _item.agility_bonus != 0:
			agility_bonus_h_box.modulate = GameMenu.ENABLED_COLOR
			agility_bonus_value.text = str(_item.agility_bonus)
		else:
			agility_bonus_h_box.modulate = GameMenu.DISABLED_COLOR
			agility_bonus_value.text = "0"
		
		if _item.magic_bonus != 0:
			magic_bonus_h_box.modulate = GameMenu.ENABLED_COLOR
			magic_bonus_value.text = str(_item.magic_bonus)
		else:
			magic_bonus_h_box.modulate = GameMenu.DISABLED_COLOR
			magic_bonus_value.text = "0"
	pass

func focus_inventory_options()->void:
	use_items_button.button.grab_focus()

func focus_last_inventory_options_button()->void:
	GameMenu.last_selected_inventory_options_button.grab_button_focus()

func _swap_inventory_slots(a : int, b : int)->void:
	var inv = Inventory.current_inventory
	if a < 0 or a >= inv.size(): #safety check
		return
	if b < 0 or b >= inv.size(): #safety check
		return
	var tmp = inv[a]
	inv[a] = inv[b]
	inv[b] = tmp

func force_close_for_load() -> void:
	# Hide both panels, no tweens.
	item_list_panel.visible = false
	description_panel.visible = false

	item_list_panel.position = Vector2(-200, 0)
	description_panel.position = Vector2(200, 0)

	# Clear instantiated entries and reset option highlights.
	clear_items_list()

	for child in inventory_options_h_box.get_children():
		if child is InventoryOptionsButton:
			child.is_active = false

	update_inventory_options_buttons_color()

#endregion inventory
