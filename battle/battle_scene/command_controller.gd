class_name CommandController
extends Node
##command_controller.gd
##Figures out valid targets for an action and returns a chosen target list.
## Handles the player decision flow during a party member's turn.
## Shows or hides command UI, opens skill or item menus, runs targeting selection, and supports back or cancel.
## Produces a single ActionUse when the player's choice is confirmed and emits it for TurnManager to consume.
## Does not apply action effects and does not advance the battle loop.


var battle_scene : BattleScene = null
var pending_user : Battler = null
var pending_action : BattleAction = null
var current_turn_id : int = -1
var pending_data : Dictionary = {}
var _all_target_preview_targets : Array[Battler] = []


signal action_use_chosen(turn_id : int, use : ActionUse)

#region TurnID
## Stores the current TurnManager turn id so action confirmations emit with the correct id.
func begin_turn(turn_id : int)->void:
	current_turn_id = turn_id
#endregion TurnID

#region Command Button Functions
## Starts targeting for a standard BattleAction (attack style), initializing pending state and routing into the generic targeting flow.
func open_attack_targeting(attacker : Battler, action : BattleAction)->void:
	pending_user = attacker
	pending_action = action
	pending_data = {}
	_begin_targeting_for_action(action, "ACTION_SELECT")



## Starts DEFEND_TARGETING, enabling living party buttons, disabling enemies, building focus neighbors, and focusing the defender by default.
func open_defend_targeting(defender : Battler, action : BattleAction)->void:
	pending_user = defender
	pending_action = action
	pending_data = {}
	battle_scene.ui_state = "DEFEND_TARGETING"
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.faction == Battler.Faction.PARTY:
				if bat.actor_data.current_hp > 0:
					bat.ui_element.activate_button()
				elif bat.actor_data.current_hp <= 0:
					bat.ui_element.deactivate_button()
				pass
			if bat.faction == Battler.Faction.ENEMY:
				bat.ui_element.deactivate_button()
				pass
	_setup_battler_target_neighbors()
	defender.ui_element.grab_button_focus() #focus the defender by default



func open_skillitem_targeting(_user : Battler, _action : BattleAction)->void:
	
	pass
	
	pass
	
	
##Begins player targeting for a non-skill/non-item BattleAction using the BattleAction's own target settings.
##fallback_ui_state is where the UI should return if no valid targets exist.
func _begin_targeting_for_action(action : BattleAction, fallback_ui_state : String) -> void:
	if pending_user == null or action == null:
		return

	# Shapes that do not require target selection
	if action.target_shape == BattleAction.TargetShape.NONE:
		_confirm_action([])
		return
	if action.target_shape == BattleAction.TargetShape.SELF:
		_confirm_action([pending_user])
		return

	var valid_targets : Array[Battler] = _gather_valid_targets_for_action(action)
	if valid_targets.is_empty():
		GameMenu.play_error_sound()
		_end_targeting()
		battle_scene.ui_state = fallback_ui_state
		return

	# ALL mode is resolved during _confirm_action by expanding from an anchor selection
	if action.target_shape == BattleAction.TargetShape.ALL:
		pending_data["all_mode"] = true

	# Provide a default focus hint so _focus_default_target behaves consistently with skills/items
	var focus_hint: int = int(action.default_target_focus)
	if focus_hint == 0:
		if action.target_side == BattleAction.TargetSide.SAME_FACTION:
			focus_hint = 1
		elif action.target_side == BattleAction.TargetSide.OTHER_FACTION:
			focus_hint = 2
	pending_data["default_target_focus"] = focus_hint

	_activate_targets(valid_targets)
	battle_scene.ui_state = "ATTACK_TARGETING"
	_focus_default_target(valid_targets)

func _gather_valid_targets_for_action(action : BattleAction) -> Array[Battler]:
	var out : Array[Battler] = []
	if pending_user == null or action == null:
		return out

	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			var is_dead = bat.actor_data.current_hp <= 0
			if is_dead and not action.can_target_dead:
				continue

			var ok = false
			if action.target_side == BattleAction.TargetSide.ANY_FACTION:
				ok = true
			elif action.target_side == BattleAction.TargetSide.SAME_FACTION:
				ok = bat.faction == pending_user.faction
			elif action.target_side == BattleAction.TargetSide.OTHER_FACTION:
				ok = bat.faction != pending_user.faction

			if ok:
				out.append(bat)
	return out
	
func is_all_targeting_active() -> bool:
	if battle_scene == null:
		return false

	var is_targeting_state : bool = false
	if battle_scene.ui_state == "ATTACK_TARGETING":
		is_targeting_state = true
	elif battle_scene.ui_state == "SKILL_TARGETING":
		is_targeting_state = true
	elif battle_scene.ui_state == "ITEM_TARGETING":
		is_targeting_state = true

	if not is_targeting_state:
		return false

	if not pending_data.has("all_mode"):
		return false

	return bool(pending_data["all_mode"])



func on_battler_focus_changed(anchor : Battler) -> void:
	if anchor == null:
		return
	if not is_all_targeting_active():
		return

	var preview : Array[Battler] = _get_all_target_preview(anchor)
	if preview.is_empty():
		return

	if _arrays_have_same_battlers(_all_target_preview_targets, preview):
		return

	_clear_all_target_preview_visuals()
	_all_target_preview_targets = preview.duplicate()
	_apply_all_target_preview_visuals(_all_target_preview_targets)


func _get_all_target_preview(anchor : Battler) -> Array[Battler]:
	if anchor == null:
		return []

	if pending_data.has("skill"):
		var skill = pending_data["skill"] as Skill
		if skill != null:
			return _build_all_targets_for_skill(skill, anchor)

	if pending_data.has("item_slot"):
		var slot = pending_data["item_slot"] as InventorySlot
		if slot != null and slot.item != null:
			return _build_all_targets_for_item(slot.item, anchor)

	if pending_action != null:
		return _build_all_targets_for_action(pending_action, anchor)

	return []


func _apply_all_target_preview_visuals(targets : Array[Battler]) -> void:
	for bat in targets:
		if bat == null:
			continue
		_set_ui_element_all_target_highlight(bat.ui_element, true)


func _clear_all_target_preview_visuals() -> void:
	for bat in _all_target_preview_targets:
		if bat == null:
			continue
		_set_ui_element_all_target_highlight(bat.ui_element, false)


func _clear_all_target_preview_state() -> void:
	_clear_all_target_preview_visuals()
	_all_target_preview_targets.clear()


func _set_ui_element_all_target_highlight(ui, enabled : bool) -> void:
	if ui == null:
		return

	if ui is BattleEnemy:
		var be = ui as BattleEnemy
		if enabled:
			be.animation_player.play("focused")
		else:
			be.animation_player.play("unfocused")
		return

	if ui is BattleStats:
		var bs = ui as BattleStats
		if enabled:
			bs.animation_player.play("flash")
		else:
			bs.animation_player.play("RESET")
		return


func _arrays_have_same_battlers(a : Array[Battler], b : Array[Battler]) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if a[i] != b[i]:
			return false
	return true


##Button pressed function for when an enemy's button (selected) in battle.
##TODO This needs to be changed to support skills and items as well!
func on_enemy_pressed(target : Battler)->void:
	pending_user.ui_element.last_enemy_selected = target
	match battle_scene.ui_state:
		"ATTACK_TARGETING":
			_confirm_action([target])
		"DEFEND_TARGETING":
			#shouldn't do anything, party shouldn't be able to defend the enemy
			pass
		"SKILL_TARGETING":
			_confirm_action([target])
		"ITEM_TARGETING":
			_confirm_action([target])

func on_party_pressed(target : Battler)->void:
	match battle_scene.ui_state:
		"ATTACK_TARGETING":
			_confirm_action([target])
		"DEFEND_TARGETING":
			_confirm_action([target])
			pass
		"SKILL_TARGETING":
			_confirm_action([target])
		"ITEM_TARGETING":
			_confirm_action([target])


	
func _confirm_action(targets : Array[Battler])->void:
	var final_targets : Array[Battler] = targets

	if pending_data.has("all_mode") and pending_data["all_mode"] == true:
		pending_data.erase("all_mode")

		var skill = null
		if pending_data.has("skill"):
			skill = pending_data["skill"] as Skill
		if skill != null and not targets.is_empty():
			final_targets = _build_all_targets_for_skill(skill, targets[0])

		var slot = null
		if pending_data.has("item_slot"):
			slot = pending_data["item_slot"] as InventorySlot
		if slot != null and slot.item != null and not targets.is_empty():
			final_targets = _build_all_targets_for_item(slot.item, targets[0])

		# BattleAction ALL expansion (non-skill/non-item)
		if skill == null and slot == null and pending_action != null and not targets.is_empty():
			final_targets = _build_all_targets_for_action(pending_action, targets[0])


	var use = ActionUse.new(pending_user, pending_action, final_targets, pending_data)
	
	#plays default animation for target (not sure if needed)
	for tar in final_targets:
		tar.ui_element.animation_player.play("RESET")
	
	#Disables all buttons for enemy/party selection
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			bat.ui_element.deactivate_button()

	if battle_scene.acting_battler != null and battle_scene.acting_battler.ui_element is BattleStats:
		battle_scene.acting_battler.ui_element.show_commands = false
	battle_scene.skill_window.visible = false
	battle_scene.item_window.visible = false
	_end_targeting()

	if current_turn_id < 0:
		printerr("CommandController: current_turn_id not set for this turn")
		return

	action_use_chosen.emit(current_turn_id, use)

func _build_all_targets_for_skill(skill : Skill, anchor : Battler) -> Array[Battler]:
	if skill == null or anchor == null:
		return []

	# For ANY_FACTION, use the anchor to decide which faction receives the ALL application
	if skill.target_side == Skill.TargetSide.ANY_FACTION:
		var out : Array[Battler] = []
		for bat in battle_scene.battlers.get_children():
			if bat is Battler:
				var is_dead = bat.actor_data.current_hp <= 0
				if is_dead and not skill.can_target_dead:
					continue
				if bat.faction == anchor.faction:
					out.append(bat)
		return out

	# SAME_FACTION and OTHER_FACTION are already unambiguous from the user
	return _gather_valid_targets(skill.target_side, skill.can_target_dead)

func _build_all_targets_for_item(item : Item, anchor : Battler) -> Array[Battler]:
	if item == null or anchor == null:
		return []

	# BOTH_FACTIONS means everyone (subject to can_target_dead)
	if item.target_side == Item.TargetSide.BOTH_FACTIONS:
		var out : Array[Battler] = []
		for bat in battle_scene.battlers.get_children():
			if bat is Battler:
				var is_dead = bat.actor_data.current_hp <= 0
				if is_dead and not item.can_target_dead:
					continue
				out.append(bat)
		return out

	# ANY_FACTION uses the anchor faction for ALL
	if item.target_side == Item.TargetSide.ANY_FACTION:
		var out2 : Array[Battler] = []
		for bat in battle_scene.battlers.get_children():
			if bat is Battler:
				var is_dead2 = bat.actor_data.current_hp <= 0
				if is_dead2 and not item.can_target_dead:
					continue
				if bat.faction == anchor.faction:
					out2.append(bat)
		return out2

	# SAME_FACTION and OTHER_FACTION are unambiguous from the user
	return _gather_valid_item_targets(item)

func _build_all_targets_for_action(action : BattleAction, anchor : Battler) -> Array[Battler]:
	if action == null or anchor == null or pending_user == null:
		return []

	# ANY_FACTION uses the anchor faction to decide which side receives the ALL application
	if action.target_side == BattleAction.TargetSide.ANY_FACTION:
		var out : Array[Battler] = []
		for bat in battle_scene.battlers.get_children():
			if bat is Battler:
				var is_dead = bat.actor_data.current_hp <= 0
				if is_dead and not action.can_target_dead:
					continue
				if bat.faction == anchor.faction:
					out.append(bat)
		return out

	# SAME_FACTION and OTHER_FACTION are unambiguous from the user
	return _gather_valid_targets_for_action(action)



func _confirm_action_other()->void:
	for bat in  battle_scene.battlers.get_children():
		if bat is Battler:
			bat.ui_element.deactivate_button()
		if battle_scene.acting_battler.ui_element is BattleStats:
			battle_scene.acting_battler.ui_element.show_commands = false

##Sets pending_user and pending_action to null
func _end_targeting()->void:
	_clear_all_target_preview_state()
	battle_scene.disable_all_ui_element_buttons()
	pending_user = null
	pending_action = null
	pending_data = {}
	pass


##Shows skill window based upon the skills available to the party member
func show_skill_window(battler: Battler)->void:
	#if the actor has no skills, don't do anything!
	if battler.actor_data.skills.is_empty():
		#TODO play an error sound
		return
	
	#sets state
	battle_scene.ui_state = "SKILL_MENU_OPEN"
	
	#Clears the skills window so it can be built again
	for child in battle_scene.skill_grid_container.get_children():
		child.queue_free()
		
	await get_tree().process_frame
	#propagate skills for current party member
	for skill in battler.actor_data.skills:
		var new_button : BattleSkillButton = battle_scene.BATTLE_SKILL_BUTTON.instantiate()
		battle_scene.skill_grid_container.add_child(new_button)
		new_button.battler = battle_scene.acting_battler
		new_button.skill = skill
		new_button.is_active = false
		new_button.setup()
	battle_scene.skill_window.visible = true
	
	setup_itemskill_button_neighbors(battle_scene.skill_grid_container)
	var skillgcontainer : GridContainer = battle_scene.skill_grid_container
	#focus last battle skill if options set to do so
	#if skill is unable to be used, focus first
	#if options is not set, focus first skill
	if Options.battle_menu_memory == true:
		#If there is no last skill used, focus the first skill. Default is ""
		if battler.ui_element.last_skill_selected == "":
			focus_first_element(skillgcontainer)
			return
		else: #There IS a last_skill_selected
			#find the skill's name
			var _skill : Skill = find_skill_by_name(battler, battler.ui_element.last_skill_selected)
			#find the button with that skill
			var _skillbutton : BattleSkillButton = find_button_by_skill(_skill)
			#If the skill can't be used again
			if _skillbutton.button.disabled == true:
				focus_first_element(skillgcontainer)
			else: #if the skill CAN be used again
				#focus the skill's button
				_skillbutton.grab_button_focus()
	else: #options memory set to false
		focus_first_element(skillgcontainer)
			
			
	pass

func find_skill_by_name(_battler : Battler, _name : String)->Skill:
	var batskills = _battler.actor_data.skills
	for skill in batskills:
		if skill.name == _name:
			return skill
	return null


##Return the button containing the skill provided
func find_button_by_skill(_skill : Skill)->BattleSkillButton:
	if !battle_scene.skill_grid_container.get_children().is_empty():
		for child in battle_scene.skill_grid_container.get_children():
			if child is BattleSkillButton:
				if child.skill == _skill:
					return child
	return null
	
func focus_first_element(gcontainer : GridContainer)->void:
	if gcontainer == null:
		return
	for child in gcontainer.get_children():
		if child is BattleSkillButton:
			if child.button.disabled:
				continue
		if child is BattleItemButton:
			if child.button.disabled:
				continue
		if child.has_method("grab_button_focus"):
			child.grab_button_focus()
			return

		
	
func hide_skill_window()->void:
	#hide skill window
	battle_scene.skill_window.visible = false
	#skill menu was cancelled out of by user
	if battle_scene.ui_state == "SKILL_MENU_OPEN": 
		battle_scene.ui_state = "ACTION_SELECT"
		
		pass
	#the window is hidden and should be cleaned up
	for child in battle_scene.skill_grid_container.get_children():
		child.queue_free()


func setup_itemskill_button_neighbors(gcontainer : GridContainer)->void:
	if gcontainer == null:
		return

	var children := gcontainer.get_children()
	var count : int = children.size()
	if count == 0:
		return

	var cols : int = gcontainer.columns
	if cols <= 0:
		cols = 4

	var btns : Array[Button] = []
	btns.resize(count)

	for i in range(count):
		btns[i] = _extract_entry_button(children[i])

	# Count focusable
	var focusable_count : int = 0
	var only_btn : Button = null
	for b in btns:
		if _is_focusable_button(b):
			focusable_count += 1
			only_btn = b

	if focusable_count == 0:
		return

	if focusable_count == 1:
		var p : NodePath = only_btn.get_path()
		only_btn.focus_neighbor_top = p
		only_btn.focus_neighbor_bottom = p
		only_btn.focus_neighbor_left = p
		only_btn.focus_neighbor_right = p
		only_btn.focus_previous = p
		only_btn.focus_next = p
		return

	@warning_ignore("integer_division")
	var rows : int = int((count + cols - 1) / cols)

	for i in range(count):
		var btn := btns[i]
		if not _is_focusable_button(btn):
			continue

		@warning_ignore("integer_division")
		var row : int = i / cols
		var col : int = i % cols

		var row_start : int = row * cols
		var row_len : int = min(cols, count - row_start)

		var left_i : int = _find_in_row(btns, row_start, row_len, i, -1)
		var right_i : int = _find_in_row(btns, row_start, row_len, i, 1)
		var up_i : int = _find_in_col(btns, cols, rows, row, col, -1)
		var down_i : int = _find_in_col(btns, cols, rows, row, col, 1)

		btn.focus_neighbor_left = btns[left_i].get_path()
		btn.focus_neighbor_right = btns[right_i].get_path()
		btn.focus_neighbor_top = btns[up_i].get_path()
		btn.focus_neighbor_bottom = btns[down_i].get_path()

		btn.focus_previous = btn.focus_neighbor_left
		btn.focus_next = btn.focus_neighbor_right


func _extract_entry_button(entry : Node) -> Button:
	if entry == null:
		return null

	# Safe property read if the script defines `var button`
	var v = entry.get("button")
	if v != null and v is Button:
		return v as Button

	# Common cases: UniqueName `%Button`, or a direct child named `Button`
	var n := entry.get_node_or_null("%Button")
	if n != null and n is Button:
		return n as Button

	n = entry.get_node_or_null("Button")
	if n != null and n is Button:
		return n as Button

	# Fallback: first Button anywhere in the subtree
	return _find_first_button(entry)


func _find_first_button(node : Node) -> Button:
	for c in node.get_children():
		if c is Button:
			return c as Button
		var found := _find_first_button(c)
		if found != null:
			return found
	return null


func _is_focusable_button(btn : Button)->bool:
	if btn == null:
		return false
	if btn.disabled:
		return false
	if not btn.is_visible_in_tree():
		return false
	if btn.focus_mode == Control.FOCUS_NONE:
		return false
	return true



# delta is -1 for left, 1 for right. Wraps within the row and skips disabled.
func _find_in_row(btns : Array[Button], row_start : int, row_len : int, from_i : int, delta : int)->int:
	if row_len <= 1:
		return from_i

	var col : int = from_i - row_start
	for _step in range(row_len):
		col += delta
		if col < 0:
			col = row_len - 1
		elif col >= row_len:
			col = 0

		var idx : int = row_start + col
		if _is_focusable_button(btns[idx]):
			return idx

	return from_i


# row_delta is -1 for up, 1 for down. Wraps across rows.
# Targets same column when possible, clamps for short rows, skips disabled.
func _find_in_col(btns : Array[Button], cols : int, rows : int, from_row : int, from_col : int, row_delta : int)->int:
	var count : int = btns.size()

	for _step in range(rows):
		var r : int = from_row + (row_delta * (_step + 1))
		while r < 0:
			r += rows
		while r >= rows:
			r -= rows

		var row_start : int = r * cols
		if row_start >= count:
			continue

		var row_len : int = min(cols, count - row_start)
		var target_col : int = from_col
		if target_col >= row_len:
			target_col = row_len - 1

		# Try preferred col, then scan outward inside that row.
		var center_i : int = row_start + target_col
		if _is_focusable_button(btns[center_i]):
			return center_i

		for offset in range(1, row_len):
			var left_col : int = target_col - offset
			if left_col >= 0:
				var li : int = row_start + left_col
				if _is_focusable_button(btns[li]):
					return li

			var right_col : int = target_col + offset
			if right_col < row_len:
				var ri : int = row_start + right_col
				if _is_focusable_button(btns[ri]):
					return ri

	# Fallback
	var from_i : int = (from_row * cols) + from_col
	if from_i >= 0 and from_i < count and _is_focusable_button(btns[from_i]):
		return from_i

	# Last resort: first focusable
	for i in range(count):
		if _is_focusable_button(btns[i]):
			return i

	return 0

##Shows item list. Only shows battle-usable items.
func show_item_window(battler : Battler)->void:
	if !Inventory.current_inventory.is_empty(): #items present, go ahead and open
		#clears old item entires
		for child in battle_scene.item_grid_container.get_children():
			child.queue_free()
		await get_tree().process_frame
		for itslt in Inventory.current_inventory:
			if itslt.item != null:
				if itslt.item.scope == Item.UseScope.BATTLE_ONLY or itslt.item.scope == Item.UseScope.ALL: #item can be used in battle
					if !itslt.item.effects.is_empty(): #item has effects. redundant safety check
						#makes the button
						var new_button : BattleItemButton = battle_scene.BATTLE_ITEM_BUTTON.instantiate()
						battle_scene.item_grid_container.add_child(new_button)
						new_button.battler = battler
						new_button.itemslot = itslt
						new_button.setup()
						new_button.is_active = false
				
		battle_scene.ui_state = "ITEM_MENU_OPEN" #sets ui_state
		battle_scene.item_window.visible = true #show the item window
		battle_scene.disable_all_ui_element_buttons() #disable ui element buttons just in case
		var itemgcontainer : GridContainer = battle_scene.item_grid_container
		setup_itemskill_button_neighbors(itemgcontainer) #sets up neighbors
		
		#focus last battle item if options set to do so
		#if item is unable to be used, focus first
		#if options is not set, focus first item
		if Options.battle_menu_memory == true:
			#If there is no last item used, focus the first item. Default is ""
			if battler.ui_element.last_item_selected == null:
				focus_first_element(itemgcontainer)
				return
			else: #There IS a last_item_selected
				#find the button with that item
				var _islot : InventorySlot = battler.ui_element.last_item_selected
				var _itembutton : BattleItemButton = find_button_by_item(_islot)
				
				_itembutton.grab_button_focus()
		else: #options memory set to false
			focus_first_element(itemgcontainer)		

	else: #there's no items, don't do anything
		battle_scene.item_window.visible = false #hide it just in case
		#play error sound
		return
		
		
	#propagate items list
	#show item window
	#change battle state to item window open
	pass
##TODO FINISH THIS FUNCTION
func find_button_by_item(_islot : InventorySlot)->BattleItemButton:
	var item : Item = _islot.item
	for child in battle_scene.item_grid_container.get_children():
		if child is BattleItemButton:
			if child.itemslot.item == item:
				return child
	return null


func hide_item_window()->void:
	#hide item window
	#change of battle state should be handled depending on the UI action taken
		#if cancelled out, then go back to the previous action selection state
		#if item is used, then go into action playing state
			#consume the battler's turn
	pass

##Attempts to run from battle immediately. Uses PartyMember's stats to attempt this
func attempt_to_run(runner : Battler, action : BattleAction)->void:
	runner.ui_element.show_commands = false
	_end_targeting()
	action_use_chosen.emit(current_turn_id, ActionUse.new(runner, action, []))
	
	pass
#endregion Command Button Functions



#region Targeting


func setup_enemy_targeting(_hbox : HBoxContainer) -> void:
	var ilist := battle_scene.enemy_h_box.get_children()
	var count := ilist.size()
	var first_pmember : BattleStats = null
	for child in battle_scene.party_h_box.get_children():
		if child is BattleStats:
			first_pmember = child
			break
	

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
		btn.focus_neighbor_bottom = first_pmember.button.get_path()
		btn.focus_neighbor_left = left_btn.get_path()
		btn.focus_neighbor_right = right_btn.get_path()
		btn.focus_previous = left_btn.get_path()
		btn.focus_next = right_btn.get_path()
		
func setup_party_targeting()->void:
	var ilist := battle_scene.party_h_box.get_children()
	var count := ilist.size()
	var first_enemy : BattleEnemy = null
	for child in battle_scene.enemy_h_box.get_children():
		if child is BattleEnemy:
			first_enemy = child
			break
	

		# Two or more entries, use wraparound for top and bottom
	for i in range(count):
		
		var child = ilist[i] as BattleStats
		var btn = child.button

		var left_index := (i - 1 + count) % count
		var right_index := (i + 1) % count
		var left_btn = ilist[left_index].button
		var right_btn = ilist[right_index].button

		var self_path = btn.get_path()
		btn.focus_neighbor_top = first_enemy.button.get_path()
		btn.focus_neighbor_bottom = self_path
		btn.focus_neighbor_left = left_btn.get_path()
		btn.focus_neighbor_right = right_btn.get_path()
		btn.focus_previous = left_btn.get_path()
		btn.focus_next = right_btn.get_path()
		
		
func target_first_enemy()->void:
	for child in battle_scene.enemy_h_box.get_children():
		if child is BattleEnemy:
			child.grab_button_focus()
			break
			

#endregion Targeting


#region Item and Skill Use
func begin_use_skill(user : Battler, skill : Skill) -> void:
	if user == null or skill == null:
		return
	pending_user = user
	pending_action = battle_scene.BATTLEACTION_SKILL
	var focus_hint : int = int(skill.default_target_focus)

	if focus_hint == int(Skill.DefaultTargetFocus.AUTO):
		# If the skill explicitly restricts a side, use that restriction as the focus hint.
		if skill.target_side == Skill.TargetSide.SAME_FACTION:
			focus_hint = int(Skill.DefaultTargetFocus.SAME_FACTION)
		elif skill.target_side == Skill.TargetSide.OTHER_FACTION:
			focus_hint = int(Skill.DefaultTargetFocus.OTHER_FACTION)
		else:
			# ANY_FACTION: pick a sensible default like FF6.
			if skill.intent == Skill.Intent.BENEFICIAL:
				focus_hint = int(Skill.DefaultTargetFocus.SAME_FACTION)
			elif skill.intent == Skill.Intent.HARMFUL:
				focus_hint = int(Skill.DefaultTargetFocus.OTHER_FACTION)
			elif skill.intent == Skill.Intent.MIXED:
				focus_hint = int(Skill.DefaultTargetFocus.OTHER_FACTION)
			else:
				# UTILITY
				focus_hint = int(Skill.DefaultTargetFocus.SAME_FACTION)

	pending_data = {
		"skill": skill,
		"default_target_focus": focus_hint,
	}


	_begin_targeting_for_skill(skill)


func begin_use_item(user : Battler, slot : InventorySlot) -> void:
	if user == null or slot == null or slot.item == null:
		return
	pending_user = user
	pending_action = battle_scene.BATTLEACTION_ITEM
	pending_data = {
		"item_slot": slot,
		"default_target_focus": int(slot.item.default_target_focus),
	}

	_begin_targeting_for_item(slot.item)

	
func _begin_targeting_for_skill(skill : Skill) -> void:
	if skill == null:
		return

	# Optional completeness: block NONE
	if skill.target_shape == Skill.TargetShape.NONE:
		GameMenu.play_error_sound()
		_end_targeting()
		battle_scene.ui_state = "SKILL_MENU_OPEN"
		return

	if skill.target_shape == Skill.TargetShape.SELF:
		# Keep targeting UX consistent: require the player to confirm SELF by selecting the user.
		# All other battlers remain visible but are disabled.
		var self_list : Array[Battler] = [pending_user]
		var self_valid = _filter_targets_by_skill_effects(skill, self_list)
		if self_valid.is_empty():
			GameMenu.play_error_sound()
			_end_targeting()
			battle_scene.ui_state = "SKILL_MENU_OPEN"
			return

		_activate_targets(self_valid)
		battle_scene.ui_state = "SKILL_TARGETING"
		_focus_default_target(self_valid)
		return


	var valid_targets : Array[Battler] = _gather_valid_targets(skill.target_side, skill.can_target_dead)
	valid_targets = _filter_targets_by_skill_effects(skill, valid_targets)

	if valid_targets.is_empty():
		GameMenu.play_error_sound()
		_end_targeting()
		battle_scene.ui_state = "SKILL_MENU_OPEN"
		return

	if skill.target_shape == Skill.TargetShape.ALL:
		pending_data["all_mode"] = true
		_activate_targets(valid_targets)
		battle_scene.ui_state = "SKILL_TARGETING"
		_focus_default_target(valid_targets)
		return

	_activate_targets(valid_targets)
	battle_scene.ui_state = "SKILL_TARGETING"
	_focus_default_target(valid_targets)


func _begin_targeting_for_item(item : Item) -> void:
	if item == null:
		return

	if item.target_shape == Item.TargetShape.NONE:
		GameMenu.play_error_sound()
		_end_targeting()
		battle_scene.ui_state = "ITEM_MENU_OPEN"
		return

	if item.target_shape == Item.TargetShape.SELF:
		# Keep targeting UX consistent: require the player to confirm SELF by selecting the user.
		# All other battlers remain visible but are disabled.
		var self_list : Array[Battler] = [pending_user]
		var self_valid = _filter_targets_by_item_effects(item, self_list)
		if self_valid.is_empty():
			GameMenu.play_error_sound()
			_end_targeting()
			battle_scene.ui_state = "ITEM_MENU_OPEN"
			return

		_activate_targets(self_valid)
		battle_scene.ui_state = "ITEM_TARGETING"
		_focus_default_target(self_valid)
		return


	var valid_targets : Array[Battler] = _gather_valid_item_targets(item)
	valid_targets = _filter_targets_by_item_effects(item, valid_targets)

	if valid_targets.is_empty():
		GameMenu.play_error_sound()
		_end_targeting()
		battle_scene.ui_state = "ITEM_MENU_OPEN"
		return

	if item.target_shape == Item.TargetShape.ALL:
		pending_data["all_mode"] = true
		_activate_targets(valid_targets)
		battle_scene.ui_state = "ITEM_TARGETING"
		_focus_default_target(valid_targets)
		return

	_activate_targets(valid_targets)
	battle_scene.ui_state = "ITEM_TARGETING"
	_focus_default_target(valid_targets)


func _gather_valid_targets(side : int, can_target_dead : bool) -> Array[Battler]:
	var out : Array[Battler] = []
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			var is_dead = bat.actor_data.current_hp <= 0
			if is_dead and not can_target_dead:
				continue

			var ok = false
			if side == Skill.TargetSide.ANY_FACTION:
				ok = true
			elif side == Skill.TargetSide.SAME_FACTION:
				ok = bat.faction == pending_user.faction
			elif side == Skill.TargetSide.OTHER_FACTION:
				ok = bat.faction != pending_user.faction

			if ok:
				out.append(bat)
	return out


func _gather_valid_item_targets(item : Item) -> Array[Battler]:
	var out : Array[Battler] = []

	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			var is_dead = bat.actor_data.current_hp <= 0
			if is_dead and not item.can_target_dead:
				continue

			var ok = false
			if item.target_side == Item.TargetSide.BOTH_FACTIONS:
				ok = true
			elif item.target_side == Item.TargetSide.ANY_FACTION:
				ok = true
			elif item.target_side == Item.TargetSide.SAME_FACTION:
				ok = bat.faction == pending_user.faction
			elif item.target_side == Item.TargetSide.OTHER_FACTION:
				ok = bat.faction != pending_user.faction

			if ok:
				out.append(bat)

	return out

func _make_battle_effect_context() -> EffectContext:
	var ctx = EffectContext.new()
	ctx.mode = EffectContext.Mode.BATTLE
	ctx.user_actor = null
	if pending_user != null:
		ctx.user_actor = pending_user.actor_data
	ctx.battle_scene = battle_scene
	if battle_scene != null:
		ctx.status_system = battle_scene.status_system
	return ctx


func _filter_targets_by_skill_effects(skill : Skill, candidates : Array[Battler]) -> Array[Battler]:
	if skill == null:
		return []
	if pending_user == null:
		return []

	var ctx = _make_battle_effect_context()
	var effects = skill.get_effects_for_context(ctx)
	if effects.is_empty():
		return []

	var out : Array[Battler] = []
	for bat in candidates:
		if bat == null:
			continue

		var ok_for_this_target = false
		for effect in effects:
			if effect == null:
				continue
			if effect.can_apply_to_battler(ctx, bat):
				ok_for_this_target = true
				break

		if ok_for_this_target:
			out.append(bat)

	return out


func _filter_targets_by_item_effects(item : Item, candidates : Array[Battler]) -> Array[Battler]:
	if item == null:
		return []
	if pending_user == null:
		return []

	var ctx = _make_battle_effect_context()
	ctx.source_item = item

	var effects = item.get_effects_for_context(ctx)
	if effects.is_empty():
		return []

	var out : Array[Battler] = []
	for bat in candidates:
		if bat == null:
			continue

		var ok_for_this_target = false
		for effect in effects:
			if effect == null:
				continue
			if effect.can_apply_to_battler(ctx, bat):
				ok_for_this_target = true
				break

		if ok_for_this_target:
			out.append(bat)

	return out





func _activate_targets(valid : Array[Battler]) -> void:
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			bat.ui_element.deactivate_button()

	for bat in valid:
		bat.ui_element.activate_button()
	_setup_battler_target_neighbors()


func _focus_default_target(valid : Array[Battler]) -> void:
	if valid.is_empty():
		return

	if Options.battle_menu_memory:
		if pending_user != null and pending_user.ui_element is BattleStats:
			var stats = pending_user.ui_element as BattleStats
			if stats.last_enemy_selected != null:
				if valid.has(stats.last_enemy_selected):
					stats.last_enemy_selected.ui_element.grab_button_focus()
					return

	var focus_hint : int = 0
	if pending_data.has("default_target_focus"):
		focus_hint = int(pending_data["default_target_focus"])

	if pending_user != null:
		if focus_hint == 2:
			for bat in valid:
				if bat.faction != pending_user.faction:
					bat.ui_element.grab_button_focus()
					return
		elif focus_hint == 1:
			for bat2 in valid:
				if bat2.faction == pending_user.faction:
					bat2.ui_element.grab_button_focus()
					return

	valid[0].ui_element.grab_button_focus()

##Sets focus neighbors for battler selection (party/enemy buttons) based on which buttons are currently focusable.
##This is required for skills/items that allow selecting either faction (ANY_FACTION), especially in ALL targeting mode.
## Reserved entry point for non menu skill item targeting. No call sites in the template.
func _setup_battler_target_neighbors() -> void:
	var enemy_buttons : Array[Button] = []
	for child in battle_scene.enemy_h_box.get_children():
		var btn = _extract_entry_button(child)
		if btn != null:
			enemy_buttons.append(btn)

	var party_buttons : Array[Button] = []
	for child2 in battle_scene.party_h_box.get_children():
		var btn2 = _extract_entry_button(child2)
		if btn2 != null:
			party_buttons.append(btn2)

	var enemy_focusable : Array[int] = []
	for i in range(enemy_buttons.size()):
		if _is_focusable_button(enemy_buttons[i]):
			enemy_focusable.append(i)

	var party_focusable : Array[int] = []
	for j in range(party_buttons.size()):
		if _is_focusable_button(party_buttons[j]):
			party_focusable.append(j)

	# Horizontal wrapping within each row (skips disabled/hidden)
	_setup_row_neighbors(enemy_buttons, enemy_focusable)
	_setup_row_neighbors(party_buttons, party_focusable)

	# Vertical linkage between rows when both have at least one focusable target
	var has_enemy = not enemy_focusable.is_empty()
	var has_party = not party_focusable.is_empty()
	var first_enemy : Button = null
	var first_party : Button = null
	if has_enemy:
		first_enemy = enemy_buttons[enemy_focusable[0]]
	if has_party:
		first_party = party_buttons[party_focusable[0]]

	if has_enemy:
		for idx in enemy_focusable:
			var b = enemy_buttons[idx]
			var self_path = b.get_path()
			b.focus_neighbor_top = self_path
			if has_party and first_party != null:
				b.focus_neighbor_bottom = first_party.get_path()
			else:
				b.focus_neighbor_bottom = self_path

	if has_party:
		for idx2 in party_focusable:
			var b2 = party_buttons[idx2]
			var self_path2 = b2.get_path()
			b2.focus_neighbor_bottom = self_path2
			if has_enemy and first_enemy != null:
				b2.focus_neighbor_top = first_enemy.get_path()
			else:
				b2.focus_neighbor_top = self_path2

func _setup_row_neighbors(buttons : Array[Button], focusable_indices : Array[int]) -> void:
	if focusable_indices.is_empty():
		return

	var count = focusable_indices.size()
	for k in range(count):
		var idx = focusable_indices[k]
		var left_idx = focusable_indices[(k - 1 + count) % count]
		var right_idx = focusable_indices[(k + 1) % count]
		var btn = buttons[idx]
		var left_btn = buttons[left_idx]
		var right_btn = buttons[right_idx]
		btn.focus_neighbor_left = left_btn.get_path()
		btn.focus_neighbor_right = right_btn.get_path()
		btn.focus_previous = left_btn.get_path()
		btn.focus_next = right_btn.get_path()



#endregion Item and Skill Use
