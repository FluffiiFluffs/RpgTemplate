class_name EquipUI extends Control


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

func _ready()->void:
	
	#region initialize positions and visibility
	visible = true
	equip_panel_container.visible = false
	equip_panel_container.position = Vector2(0, 0)
	
	
	#endregion initialize positions and visibility




#region Equip Menu
func enter_equip_selection()->void:
	if !GameMenu.top_level.party_h_box_container.get_children().is_empty():
		GameMenu.top_level.equip_button.is_active = true
		equip_equip_button.is_active = true
		GameMenu.equip.equip_equip_button.self_modulate = GameMenu.ENABLED_COLOR
		GameMenu.last_top_button_focused = GameMenu.top_level.equip_button
		GameMenu.top_level.focus_last_top_level_stats()
		GameMenu.menu_state = "EQUIP_PARTY_SELECT"

## Hides top of top_level and brings down the equip menu
func equip_menu_show()->void:
	GameMenu.menu_is_animating = true
	await GameMenu.top_level.top_level_bottom_only()
	equip_panel_container.position = Vector2(0, 0)
	equip_panel_container.visible = true
	var tween = create_tween()
	tween.tween_property(equip_panel_container, "position", Vector2(0,224), 0.15)
	await tween.finished
	GameMenu.menu_is_animating = false
	

## Hides equip menu and brings down top of top_level
func equip_menu_hide()->void:
	GameMenu.menu_is_animating = true
	equip_panel_container.position = Vector2(0,224)
	
	var tween = create_tween()
	tween.tween_property(equip_panel_container, "position", Vector2(0,0), 0.15)
	await tween.finished
	await GameMenu.top_level.top_level_bottom_only_return()
	equip_panel_container.visible = false
	GameMenu.menu_is_animating = false






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
	GameMenu.equip_preview_owner = null
	for child in equip_stat_grid_container.get_children():
		if child is EquipStats:
			child.hide_difference()
			child.reset_label_colors()

func cancel_equip_equipping()->void:
	curr_main_hand.grab_button_focus()
	
	GameMenu.menu_state = "EQUIP_EQUIP_SELECT"
	pass
	


func setup_equip_options_button_presses()->void:
	equip_equip_button.button.pressed.connect(equip_equip_button_pressed)
	equip_remove_button.button.pressed.connect(equip_remove_button_pressed)
	equip_rem_all_button.button.pressed.connect(equip_rem_all_button_pressed)
	
	
func equip_equip_button_pressed()->void:
	curr_main_hand.grab_button_focus()
	GameMenu.menu_state = "EQUIP_EQUIP_SELECT"
	pass
	
func equip_remove_button_pressed()->void:
	clear_equip_equipping_list()
	hide_equip_equipping_list()
	hide_all_equip_differences()

	equip_remove_button.is_active = true
	equip_equip_button.is_active = false
	curr_main_hand.grab_button_focus()
	GameMenu.menu_state = "EQUIP_MENU_REMOVE"
	pass

func equip_rem_all_button_pressed() -> void:
	GameMenu.last_selected_equip_option_button = equip_rem_all_button
	equip_rem_all_button.is_active = false
	equip_equip_button.is_active = false
	equip_remove_button.is_active = false
	update_equip_options_buttons_color()

	if GameMenu.current_selected_party_member == null:
		return

	clear_equip_equipping_list()
	hide_equip_equipping_list()
	hide_all_equip_differences()
	await get_tree().process_frame
	

	var res = Inventory.try_remove_all_equipment_to_inventory(GameMenu.current_selected_party_member)
	if res.ok == false:
		# play_error_sound()
		return
	if res.moved_count == 0:
		# play_error_sound()
		return

	update_current_equipment_buttons()

	GameMenu.menu_state = "EQUIP_OPTIONS"
	equip_equip_button.grab_button_focus()
	#focus_last_equip_option_button()


func make_equipping_buttons_list(eqtype : int, enter_list : bool = true)->void:
	if GameMenu.current_selected_party_member == null:
		return

	var member = GameMenu.current_selected_party_member

	var focused_slot = _get_focused_curr_equip_button()
	if focused_slot != null:
		GameMenu.equip_preview_owner = focused_slot

	if GameMenu.equip_preview_owner == null:
		GameMenu.equip_preview_owner = curr_main_hand

	if eqtype == Item.ItemType.OFFHAND:
		if member.mainhand != null and member.mainhand.two_hand == true:
			clear_equip_equipping_list()
			hide_equip_equipping_list()
			hide_all_equip_differences()
			if enter_list and GameMenu.last_curr_equip_slot_button != null:
				GameMenu.last_curr_equip_slot_button.is_active = false
			return

	if enter_list:
		GameMenu.last_curr_equip_slot_button = GameMenu.equip_preview_owner

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
		if GameMenu.last_curr_equip_slot_button != null:
			GameMenu.last_curr_equip_slot_button.is_active = has_any

	if has_any:
		show_equip_equipping_list()
		if enter_list:
			setup_equip_equipping_list_focus_neighbors()
			focus_first_equip_equipping()
			GameMenu.menu_state = "EQUIP_MENU_EQUIPPING"
	else:
		hide_equip_equipping_list()


func make_equip_equipping_button(_item : Item, _slot : InventorySlot, focusable : bool)->void:
	if _item == null:
		return
	if _slot == null:
		return

	var new_equip_button = GameMenu.EQUIP_ITEM_BUTTON.instantiate() as EquipItemButton
	equip_equipping_v_box.add_child(new_equip_button)

	new_equip_button.label.text = _item.name
	new_equip_button.item = _item
	new_equip_button.slot = _slot
	new_equip_button.curr_slot_scene = GameMenu.equip_preview_owner

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
	if GameMenu.current_selected_party_member == null:
		return
	if _slot == null:
		return
	if curr_slot_scene == null:
		return

	var slot_key = GameMenu._slot_key_from_curr_button(curr_slot_scene)
	if slot_key == -1:
		# play_error_sound()
		return

	var res = Inventory.try_equip_from_inventory_slot(GameMenu.current_selected_party_member, _slot, slot_key)
	if res.ok == false:
		# play_error_sound()
		return

	update_current_equipment_buttons()

	clear_equip_equipping_list()
	hide_equip_equipping_list()

	GameMenu.menu_state = "EQUIP_EQUIP_SELECT"

	if GameMenu.last_curr_equip_slot_button != null:
		GameMenu.last_curr_equip_slot_button.is_active = false
	GameMenu.last_curr_equip_slot_button = curr_slot_scene
	curr_slot_scene.grab_button_focus()


func remove_equipped_item(curr_slot_scene: CurrentEquipButton) -> void:
	if GameMenu.current_selected_party_member == null:
		return
	if curr_slot_scene == null:
		return

	# Cache which list we should preview after the unequip.
	# Edge case: if the offhand is mirroring the mainhand due to two-handing,
	# the removed item is actually the weapon, so preview the WEAPON list.
	var preview_eqtype = _eqtype_from_curr_button(curr_slot_scene)
	var member = GameMenu.current_selected_party_member
	if curr_slot_scene == curr_off_hand and member != null:
		if member.two_handing == true and member.mainhand != null:
			preview_eqtype = Item.ItemType.WEAPON

	var slot_key = GameMenu._slot_key_from_curr_button(curr_slot_scene)
	if slot_key == -1:
		return

	var res = Inventory.try_unequip_to_inventory(GameMenu.current_selected_party_member, slot_key)
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
		child.self_modulate = GameMenu.TRANS_COLOR
	for child in curr_equip_v_box.get_children():
		if child is CurrentEquipButton:
			child.is_active = false
			child.self_modulate = GameMenu.TRANS_COLOR
	for child in equip_stat_grid_container.get_children():
		if child is EquipStats:
			child.equip_stats_title.self_modulate = GameMenu.WHITE_COLOR
			child.equip_stats_base.self_modulate = GameMenu.WHITE_COLOR
			child.equip_plus_minus.set_deferred("visible", false)
			child.equip_stats_mod_value.set_deferred("visible", false)



func focus_first_equip_equipping()->void:
	for child in equip_equipping_v_box.get_children():
		child.grab_button_focus()

func setup_equip_equipping_list_focus_neighbors()->void:
	GameMenu.setup_vertical_focus_neighbors(equip_equipping_v_box)

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
	if GameMenu.last_selected_equip_option_button != null:
		GameMenu.last_selected_equip_option_button.grab_button_focus()
		return
	equip_equip_button.grab_button_focus()


func update_current_equipment_buttons() -> void:
	if GameMenu.current_selected_party_member == null:
		return

	hide_all_equip_differences()
	update_equip_menu_stats_labels(GameMenu.current_selected_party_member)
	update_equip_menu_equipment_labels(GameMenu.current_selected_party_member)

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
