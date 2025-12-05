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
		Item.ItemType.HEAL:
			return "HEAL"
		Item.ItemType.MPHEAL:
			return "MPHEAL"
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
