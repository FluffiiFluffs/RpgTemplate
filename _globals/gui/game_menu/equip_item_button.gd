class_name EquipItemButton
extends PanelContainer
##Button instantiated and used to show current available equipment to be selected from Inventory.current_inventory (filtering done when menu is opened)

@onready var label : Label = %Label
@onready var button : Button = %Button

var item : Item = null
var slot : InventorySlot = null
var curr_slot_scene : CurrentEquipButton = null

func _ready()->void:
	button.pressed.connect(on_button_pressed)
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)
	
	
func on_button_pressed()->void:
	if item == null:
		return
	if slot == null:
		return

	if _ensure_curr_slot_scene() == false:
		return

	GameMenu.equip_item(item, slot, curr_slot_scene)
	
	
func grab_button_focus()->void:
	button.grab_focus()

func on_button_focus_entered() -> void:
	if GameMenu == null:
		return
	self_modulate = GameMenu.ENABLED_COLOR

	if item == null:
		return
	if GameMenu.current_selected_party_member == null:
		return

	if _ensure_curr_slot_scene() == false:
		return



	var member : PartyMemberData = GameMenu.current_selected_party_member
	var deltas = _get_stat_deltas_for_candidate(member, item, curr_slot_scene)

	for equip_stats in _get_all_equip_stats():
		_update_equip_stats_difference(equip_stats, deltas)


func on_button_focus_exited() -> void:
	if GameMenu == null:
		return
	self_modulate = GameMenu.TRANS_COLOR

	# Defer so another EquipItemButton can claim ownership first (no flicker).
	call_deferred("_deferred_hide_preview_if_still_owner")


func _deferred_hide_preview_if_still_owner() -> void:
	if GameMenu == null:
		return

	# If another equip button took over, do nothing.
	if GameMenu.equip_preview_owner != self:
		return

	# We are still the owner and we lost focus, so hide.
	GameMenu.equip_preview_owner = null
	_hide_all_equip_differences()



##Returns all EquipStats nodes in the equip menu.
##Primary source is EquipStatGridContainer, fallback is CurrEquipVBox.
func _get_all_equip_stats() -> Array[EquipStats]:
	var out : Array[EquipStats] = []
	if GameMenu == null:
		return out

	if GameMenu.equip_stat_grid_container != null:
		for child in GameMenu.equip_stat_grid_container.get_children():
			if child is EquipStats:
				out.append(child)
		return out

	# Fallback (in case hierarchy changes).
	if GameMenu.curr_equip_v_box != null:
		for child in GameMenu.curr_equip_v_box.get_children():
			if child is EquipStats:
				out.append(child)
	return out


##Calculates stat deltas (equipped candidate vs current equipment) for the selected member.
##Deltas are total stat deltas (after buffs percent), using the member getters.
func _get_stat_deltas_for_candidate(member : PartyMemberData, candidate : Item, slot_scene : CurrentEquipButton) -> Dictionary:
	var out : Dictionary = {
		"HP": 0,
		"SP": 0,
		"ATK": 0,
		"DEF": 0,
		"STR": 0,
		"STM": 0,
		"SPD": 0,
		"MAG": 0,
		"LCK": 0,

	}
	if member == null:
		return out
	if candidate == null:
		return out
	if slot_scene == null:
		return out
	if GameMenu == null:
		return out

	# Snapshot current totals.
	var curr_hp = member.get_max_hp()
	var curr_sp = member.get_max_sp()
	var curr_atk = member.get_atk_value()
	var curr_def = member.get_def_value()
	var curr_str = member.get_strength()
	var curr_stm = member.get_stamina()
	var curr_spd = member.get_agility()
	var curr_mag = member.get_magic()
	var curr_lck = member.get_luck()


	# Snapshot current equipment state.
	var old_head = member.headslot
	var old_chest = member.chestslot
	var old_arms = member.armslot
	var old_legs = member.legslot
	var old_accy01 = member.accy01
	var old_accy02 = member.accy02
	var old_mainhand = member.mainhand
	var old_offhand = member.offhand
	var old_two_handing = member.two_handing

	var applied = true
	match slot_scene:
		GameMenu.curr_main_hand:
			member.mainhand = candidate
			member.two_handing = candidate.two_hand
			# Match equip_item preview: two hand main clears offhand.
			if member.two_handing == true:
				member.offhand = null
		GameMenu.curr_off_hand:
			member.offhand = candidate
			member.two_handing = false
		GameMenu.curr_head:
			member.headslot = candidate
		GameMenu.curr_chest:
			member.chestslot = candidate
		GameMenu.curr_arms:
			member.armslot = candidate
		GameMenu.curr_legs:
			member.legslot = candidate
		GameMenu.curr_accy_1:
			member.accy01 = candidate
		GameMenu.curr_accy_2:
			member.accy02 = candidate
		_:
			applied = false

	if applied == true:
		var new_hp = member.get_max_hp()
		var new_sp = member.get_max_sp()
		var new_atk = member.get_atk_value()
		var new_def = member.get_def_value()
		var new_str = member.get_strength()
		var new_stm = member.get_stamina()
		var new_spd = member.get_agility()
		var new_mag = member.get_magic()
		var new_lck = member.get_luck()

		out["HP"] = new_hp - curr_hp
		out["SP"] = new_sp - curr_sp
		out["ATK"] = new_atk - curr_atk
		out["DEF"] = new_def - curr_def
		out["STR"] = new_str - curr_str
		out["STM"] = new_stm - curr_stm
		out["SPD"] = new_spd - curr_spd
		out["MAG"] = new_mag - curr_mag
		out["LCK"] = new_lck - curr_lck

	# Restore original equipment state.
	member.headslot = old_head
	member.chestslot = old_chest
	member.armslot = old_arms
	member.legslot = old_legs
	member.accy01 = old_accy01
	member.accy02 = old_accy02
	member.mainhand = old_mainhand
	member.offhand = old_offhand
	member.two_handing = old_two_handing

	return out


##Updates a single EquipStats widget using the computed deltas dictionary.
func _update_equip_stats_difference(equip_stats : EquipStats, deltas : Dictionary) -> void:
	if equip_stats == null:
		return
	if deltas == null:
		return

	var key = equip_stats.stats_title
	if not deltas.has(key):
		equip_stats.hide_difference()
		equip_stats.reset_label_colors()
		return

	var delta = int(deltas[key])
	var magnitude = abs(delta)
	var is_positive = true
	if delta < 0:
		is_positive = false

	equip_stats.show_difference()
	equip_stats.update_plus_minus(is_positive)
	equip_stats.update_mod_value(magnitude)

	# Only colorize when there is an actual change.
	if magnitude == 0:
		equip_stats.reset_label_colors()
	else:
		equip_stats.set_label_colors()



func _exit_tree() -> void:
	# Safety: if this button is freed while owning the preview, clear it.
	if GameMenu != null and GameMenu.equip_preview_owner == self:
		GameMenu.equip_preview_owner = null
		_hide_all_equip_differences()


func _hide_all_equip_differences() -> void:
	for equip_stats in _get_all_equip_stats():
		equip_stats.hide_difference()
		equip_stats.reset_label_colors()

func _ensure_curr_slot_scene() -> bool:
	if curr_slot_scene != null:
		return true
	if GameMenu == null:
		return false

	if GameMenu.equip_preview_owner != null:
		curr_slot_scene = GameMenu.equip_preview_owner
		return true

	if GameMenu.last_curr_equip_slot_button != null:
		curr_slot_scene = GameMenu.last_curr_equip_slot_button
		return true

	return false
