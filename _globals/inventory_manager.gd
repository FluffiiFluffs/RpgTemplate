##inventory_manager.gd
##global Inventory
extends Node2D

##All the items in the game so they're easily accessed
@export var all_items : Array[Item]
##What items are in the current inventory
@export var current_inventory : Array[InventorySlot]
##Default amount of slot to show in the UI
@export var default_slots : int = 12
##How many slots are in the inventory, can be expanded later by adding InventorySlot to current_inventory[]
@export var current_slots : int = 12
#How many slots have an item in them
@export var slots_filled : int = 0

signal inventory_changed
signal equipment_changed(member:PartyMemberData)

enum EquipResultCode {
	OK,
	INVALID_ARGS,
	INVENTORY_SLOT_NOT_FOUND,
	NO_QUANTITY,
	NO_ITEM,
	SLOT_MISMATCH,
	CLASS_LOCKED,
	OFFHAND_LOCKED_BY_TWO_HAND,
}

enum EquipSlotKey {
	MAINHAND,
	OFFHAND,
	HEAD,
	CHEST,
	ARMS,
	LEGS,
	ACCESSORY_1,
	ACCESSORY_2
}


func _ready()->void:
	pass
	
##For new game selection
func clear_slots() -> void:
	current_inventory.clear()
	slots_filled = 0
	#current_slots = default_slots

##For adding a new slot with an item.[br]
##If Options.multi_stacks is true: 
##Makes a new new stack if qty is higher than the max_stack_size of the item being added
func add_slot_by_id(_item_id : StringName, qty : int)->void:
	var item : Item = find_item(_item_id)
	if item == null: 
		printerr("InventoryManager: " + str(_item_id) + " not found in all_items!")
		return
	if qty <= 0:
		printerr("InventoryManager: Tried to add " + str(qty) + " of " + str(_item_id))
		return
	var new_slot : InventorySlot = InventorySlot.new()
	new_slot.item = item
	new_slot.quantity = qty
	new_slot.stringname = _item_id
	current_inventory.append(new_slot)
	if new_slot.quantity > item.max_stack_size:
		if Options.multi_stacks == true:
			if item.unique == false:
				var overflow : int = new_slot.quantity - item.max_stack_size
				new_slot.quantity = item.max_stack_size
				add_slot_by_id(_item_id, overflow)
			else:
				new_slot.quantity = item.max_stack_size
		else:
			new_slot.quantity = item.max_stack_size
	pass

##Adds an item to the inventory.[br]Checks if there'a already a stack and adds it to that.[br]If no stack is found, then it creates a stack(s).[br]
func add_item(item_id : StringName, qty : int)->void:
	var item : Item = find_item(item_id) as Item
	if item == null: 
		printerr("InventoryManager: " + str(item_id) + " not found in all_items!")
		return
	if qty <= 0:
		printerr("InventoryManager: Tried to add " + str(qty) + " of " + str(item_id))
		return
	# Handle unique items first
	if item.unique:
		# Look for the one allowed stack
		for s in current_inventory:
			if s.stringname == item_id:
				var new_quantity : int = s.quantity + qty
				s.quantity = clampi(new_quantity, 0, item.max_stack_size)
				return

		# No stack yet, create one but clamp to max
		var clamped_qty : int = min(qty, item.max_stack_size)
		add_slot_by_id(item_id, clamped_qty)
		return

	# From here on, item is not unique
	var item_was_found : bool = false
	var slot : InventorySlot = null

	#If current_inventory isn't empty
	if !current_inventory.is_empty():
		#Loop over current_inventory and try to find the item
		for s in current_inventory:
			if s.stringname == item_id:
				if s.quantity == item.max_stack_size: # stack full, keep looking
					continue
				else: # partial stack found
					item_was_found = true
					slot = s
					break
	else: #Nothing in inventory, make a new item slot
		add_slot_by_id(item_id, qty)
		return

	if item_was_found == true:
		var new_quantity : int = slot.quantity + qty
		if new_quantity > item.max_stack_size:
			var difference : int = item.max_stack_size - slot.quantity
			slot.quantity += difference
			var difference_quantity : int = qty - difference 
			if Options.multi_stacks == true:
				add_slot_by_id(item_id, difference_quantity)
		else:
			slot.quantity = new_quantity
	else:
		add_slot_by_id(item_id, qty)


##Items being used will call this function. Items being sold will call this function as well. 
func remove_item(item_id : StringName, qty : int) -> void:
	# Ignore nonsense calls
	if qty <= 0:
		return
	var item := find_item(item_id)
	var item_name := ""
	if item != null:
		item_name = item.name
	else:
		item_name = String(item_id)
	# First, count how many of this item we have across all stacks
	var total_quantity : int = 0
	for slot in current_inventory:
		if slot.stringname == item_id:
			total_quantity += slot.quantity

	# Guard against removing more than total amount in inventory
	if total_quantity < qty:
		printerr(
			"InventoryManager: trying to remove "
			+ str(qty)
			+ " of "
			+ item_name
			+ " but only "
			+ str(total_quantity)
			+ " in inventory."
		)
		return

	# We know we have enough, so actually remove
	var remaining : int = qty

	for slot in current_inventory:
		if remaining <= 0:
			break

		if slot.stringname != item_id:
			continue

		if slot.quantity > remaining:
			# This stack covers the rest
			slot.quantity -= remaining
			remaining = 0
		else:
			# Use up this stack completely
			remaining -= slot.quantity
			slot.quantity = 0
	print("InventoryManager: Removed " + str(qty) + " " + str(item_name) + " from inventory")
	# Clean up any stacks that hit zero quantity
	for i in range(current_inventory.size() - 1, -1, -1):
		if current_inventory[i].quantity <= 0:
			current_inventory.remove_at(i)


#region Helper functions
##Checks if the player has at least a set quantity of an item[br]
##Use for quests
func has_item(item_id : StringName, min_qty : int = 1) -> bool:
	return get_total_quantity(item_id) >= min_qty

##Checks if the item can be removed. True if can, false if not.
func can_remove_item(slot : InventorySlot, qty : int) -> bool:
	if slot == null:
		printerr("InventoryManager: Attempted removal from null slot")
		return false
	if qty <= 0:
		printerr("InventoryManager: Attempted removal with quantity " + str(qty))
		return false
	return slot.quantity >= qty
	
##Finds item by item_id and returns the Item
func find_item(_item_id : StringName) -> Item:
	for item in all_items:
		if item.item_id == _item_id:
			return item
	return null

##Gets total quantity of items in the inventory by item_id
func get_total_quantity(item_id : StringName) -> int:
	var total := 0
	for slot in current_inventory:
		if slot.stringname == item_id:
			total += slot.quantity
	return total



##Checks if an item can be added to the inventory (If enough slots or not). If inventory is not infinite type.
func can_add_item(item_id : StringName, qty : int) -> bool:
	var item := find_item(item_id)
	if item == null:
		return false
	if qty <= 0:
		return false

	if item.unique:
		# Already has the unique item at full stack
		for slot in current_inventory:
			if slot.stringname == item_id:
				return slot.quantity < item.max_stack_size
		# Unique item not in inventory yet; needs one free slot
		return has_free_slot()
	
	# Not unique. First, check if we can fill partial stacks
	var remaining := qty
	for slot in current_inventory:
		if slot.stringname != item_id:
			continue
		var free_space := item.max_stack_size - slot.quantity
		if free_space > 0:
			if remaining <= free_space:
				return true
			remaining -= free_space

 	#If we still have remaining quantity, we may need new stacks
	while remaining > 0:
		if !has_free_slot():
			return false
		remaining -= item.max_stack_size
	
	return true


#Checks if there is a free slot in the inventory, if not infinite
func has_free_slot() -> bool:
	return current_inventory.size() < current_slots

func _get_item_sort_category(item : Item)->String:
	if item == null:
		return "TOOL"

	match item.type:
		Item.ItemType.HPHEAL:
			return "HPHEAL"
		Item.ItemType.SPHEAL:
			return "SPHEAL"
		Item.ItemType.STATUSHEAL:
			return "STATUSHEAL"
		Item.ItemType.TOOL:
			return "TOOL"
		Item.ItemType.KEY:
			return "KEY"
		Item.ItemType.WEAPON, Item.ItemType.OFFHAND, Item.ItemType.HEAD, Item.ItemType.CHEST, Item.ItemType.ARMS, Item.ItemType.LEGS, Item.ItemType.ACCESSORY:
			return "EQUIPMENT"
		_:
			return "TOOL"

func _get_category_index(category : String)->int:
	var idx : int = Options.item_sort_order.find(category)
	if idx == -1:
		return Options.item_sort_order.size()
	return idx


func _compare_slots_by_sort_order(a : InventorySlot, b : InventorySlot)->bool:
	if a.item == null or b.item == null:
		return false

	var a_index : int = _get_category_index(_get_item_sort_category(a.item))
	var b_index : int = _get_category_index(_get_item_sort_category(b.item))

	if a_index == b_index:
		return a.item.sort_id < b.item.sort_id

	return a_index < b_index


func sort_inventory_by_current_options()->void:
	if current_inventory.is_empty():
		return
	current_inventory.sort_custom(Callable(self, "_compare_slots_by_sort_order"))


static func _get_equipped_item(member: PartyMemberData, slot_key: int) -> Item:
	if slot_key == EquipSlotKey.MAINHAND:
		return member.mainhand
	if slot_key == EquipSlotKey.OFFHAND:
		return member.offhand
	if slot_key == EquipSlotKey.HEAD:
		return member.headslot
	if slot_key == EquipSlotKey.CHEST:
		return member.chestslot
	if slot_key == EquipSlotKey.ARMS:
		return member.armslot
	if slot_key == EquipSlotKey.LEGS:
		return member.legslot
	if slot_key == EquipSlotKey.ACCESSORY_1:
		return member.accy01
	if slot_key == EquipSlotKey.ACCESSORY_2:
		return member.accy02
	return null


static func _set_equipped_item(member: PartyMemberData, slot_key: int, item: Item) -> void:
	if slot_key == EquipSlotKey.MAINHAND:
		member.mainhand = item
		return
	if slot_key == EquipSlotKey.OFFHAND:
		member.offhand = item
		return
	if slot_key == EquipSlotKey.HEAD:
		member.headslot = item
		return
	if slot_key == EquipSlotKey.CHEST:
		member.chestslot = item
		return
	if slot_key == EquipSlotKey.ARMS:
		member.armslot = item
		return
	if slot_key == EquipSlotKey.LEGS:
		member.legslot = item
		return
	if slot_key == EquipSlotKey.ACCESSORY_1:
		member.accy01 = item
		return
	if slot_key == EquipSlotKey.ACCESSORY_2:
		member.accy02 = item
		return
func _expected_item_type_for_slot(slot_key: int) -> int:
	match slot_key:
		EquipSlotKey.MAINHAND:
			return Item.ItemType.WEAPON
		EquipSlotKey.OFFHAND:
			return Item.ItemType.OFFHAND
		EquipSlotKey.HEAD:
			return Item.ItemType.HEAD
		EquipSlotKey.CHEST:
			return Item.ItemType.CHEST
		EquipSlotKey.ARMS:
			return Item.ItemType.ARMS
		EquipSlotKey.LEGS:
			return Item.ItemType.LEGS
		EquipSlotKey.ACCESSORY_1, EquipSlotKey.ACCESSORY_2:
			return Item.ItemType.ACCESSORY
		_:
			return -1

func _enforce_equipment_invariants(member: PartyMemberData) -> void:
	if member == null:
		return

	if member.mainhand != null:
		if member.mainhand.two_hand == true:
			# Two hand weapon locks offhand, keep UI and data consistent
			member.two_handing = true
			member.offhand = null
		else:
			member.two_handing = false
	else:
		member.two_handing = false


func try_equip_from_inventory_slot(member: PartyMemberData, inv_slot: InventorySlot, slot_key: int) -> Dictionary:
	var result = {
		"ok": false,
		"code": EquipResultCode.INVALID_ARGS,
		"message_key": &"equip_error_invalid_args",
		"old_item": null,
		"new_item": null,
		"slot_key": slot_key
	}

	if member == null:
		return result
	if inv_slot == null:
		return result

	var inv_index = current_inventory.find(inv_slot)
	if inv_index == -1:
		result.code = EquipResultCode.INVENTORY_SLOT_NOT_FOUND
		result.message_key = &"equip_error_slot_missing"
		return result

	if inv_slot.quantity <= 0:
		result.code = EquipResultCode.NO_QUANTITY
		result.message_key = &"equip_error_no_quantity"
		return result

	var chosen_item = inv_slot.item
	if chosen_item == null:
		result.code = EquipResultCode.NO_ITEM
		result.message_key = &"equip_error_no_item"
		return result

	var expected_type = _expected_item_type_for_slot(slot_key)
	if expected_type == -1:
		result.code = EquipResultCode.INVALID_ARGS
		result.message_key = &"equip_error_invalid_slot"
		return result

	if chosen_item.type != expected_type:
		result.code = EquipResultCode.SLOT_MISMATCH
		result.message_key = &"equip_error_slot_mismatch"
		return result

	# Offhand blocked while two hand is equipped
	if slot_key == EquipSlotKey.OFFHAND:
		if member.mainhand != null:
			if member.mainhand.two_hand == true:
				result.code = EquipResultCode.OFFHAND_LOCKED_BY_TWO_HAND
				result.message_key = &"equip_error_offhand_locked"
				return result

	# Class restriction hook
	if member.has_method("can_equip_item"):
		var can_equip = member.can_equip_item(chosen_item)
		if can_equip == false:
			result.code = EquipResultCode.CLASS_LOCKED
			result.message_key = &"equip_error_class_locked"
			return result

	var old_item = _get_equipped_item(member, slot_key)

	# Commit equipment
	_set_equipped_item(member, slot_key, chosen_item)

	# If equipping a two hand weapon, forcibly unequip offhand into inventory
	if slot_key == EquipSlotKey.MAINHAND:
		if chosen_item.two_hand == true:
			if member.offhand != null:
				add_item(member.offhand.item_id, 1)
				member.offhand = null

	_enforce_equipment_invariants(member)

	# Commit inventory changes
	if inv_slot.quantity > 1:
		inv_slot.quantity -= 1
		if old_item != null:
			add_item(old_item.item_id, 1)
	else:
		# quantity == 1
		if old_item != null:
			inv_slot.item = old_item
			inv_slot.stringname = old_item.item_id
			inv_slot.quantity = 1
		else:
			current_inventory.erase(inv_slot)

	result.ok = true
	result.code = EquipResultCode.OK
	result.message_key = &"equip_ok"
	result.old_item = old_item
	result.new_item = chosen_item

	emit_signal("equipment_changed", member)
	emit_signal("inventory_changed")

	return result



func try_unequip_to_inventory(member: PartyMemberData, slot_key: int) -> Dictionary:
	var result = {
		"ok": false,
		"code": EquipResultCode.INVALID_ARGS,
		"message_key": &"unequip_error_invalid_args",
		"old_item": null,
		"slot_key": slot_key
	}
	var actual_slot_key = slot_key
	if slot_key == EquipSlotKey.OFFHAND:
		if member.mainhand != null and member.mainhand.two_hand == true:
			actual_slot_key = EquipSlotKey.MAINHAND
			
	if member == null:
		return result

	var old_item = _get_equipped_item(member, actual_slot_key)
	if old_item == null:
		result.code = EquipResultCode.OK
		result.message_key = &"unequip_nothing"
		result.ok = true
		return result

	_set_equipped_item(member, actual_slot_key, null)
	add_item(old_item.item_id, 1)

	_enforce_equipment_invariants(member)

	result.ok = true
	result.code = EquipResultCode.OK
	result.message_key = &"unequip_ok"
	result.old_item = old_item

	emit_signal("equipment_changed", member)
	emit_signal("inventory_changed")

	return result


func try_remove_all_equipment_to_inventory(member: PartyMemberData) -> Dictionary:
	var result = {
		"ok": false,
		"code": EquipResultCode.INVALID_ARGS,
		"message_key": &"rem_all_error_invalid_args",
		"moved_count": 0
	}

	if member == null:
		return result

	var moved := 0

	# Cache the mainhand before we start clearing, so we can avoid a two hand mirror edge case.
	var cached_mainhand: Item = _get_equipped_item(member, EquipSlotKey.MAINHAND)

	var keys = [
		EquipSlotKey.MAINHAND,
		EquipSlotKey.OFFHAND,
		EquipSlotKey.HEAD,
		EquipSlotKey.CHEST,
		EquipSlotKey.ARMS,
		EquipSlotKey.LEGS,
		EquipSlotKey.ACCESSORY_1,
		EquipSlotKey.ACCESSORY_2
	]

	for k in keys:
		var item: Item = _get_equipped_item(member, k)
		if item == null:
			continue

		# Safety: if OFFHAND is mirroring a two hand mainhand, do not add it twice.
		if k == EquipSlotKey.OFFHAND and cached_mainhand != null:
			if cached_mainhand.two_hand == true and item == cached_mainhand:
				_set_equipped_item(member, k, null)
				continue

		_set_equipped_item(member, k, null)
		add_item(item.item_id, 1)
		moved += 1

	_enforce_equipment_invariants(member)

	result.ok = true
	result.code = EquipResultCode.OK
	result.message_key = &"rem_all_ok"
	result.moved_count = moved

	emit_signal("equipment_changed", member)
	emit_signal("inventory_changed")

	return result


#endregion






















#func _unhandled_input(_event):
	#if Input.is_action_just_pressed("test3"):
		#print("inventory_manager: current_inventory = " + str(current_inventory))
	#if Input.is_action_just_pressed("test4"):
		#for i in 200:
			#add_item("apple", 10)
	#if Input.is_action_just_pressed("test5"):
		#clear_slots()
	#
