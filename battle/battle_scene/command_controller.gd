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


signal action_use_chosen(turn_id : int, use : ActionUse)

#region TurnID
func begin_turn(turn_id : int)->void:
	current_turn_id = turn_id
#endregion TurnID

#region Command Button Functions
func open_attack_targeting(attacker : Battler, action : BattleAction)->void:
	pending_user = attacker
	pending_action = action
	pending_data = {}
	
	battle_scene.ui_state = "ACTION_TARGETING"
	
	#Enables targeting (can target anyone, even self)
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.actor_data.current_hp > 0:
				bat.ui_element.activate_button()

	#If menu memory is on, targets last enemy selected. If it can't happen, then the first enemy is focused.
	if Options.battle_menu_memory:
		if pending_user.ui_element.last_enemy_selected != null:
			if pending_user.ui_element.last_enemy_selected.actor_data.current_hp > 0:
				pending_user.ui_element.last_enemy_selected.ui_element.grab_button_focus()
			else:
				target_first_enemy()
		else:
			target_first_enemy()
	else:
		target_first_enemy()

##Opens targeting, passes who is defending, and the defense action
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
	defender.ui_element.grab_button_focus() #focus the defender by default

func open_skillitem_targeting(user : Battler, action : BattleAction)->void:
	
	pass
	
	pass
##Button pressed function for when an enemy's button (selected) in battle.
##TODO This needs to be changed to support skills and items as well!
func on_enemy_pressed(target : Battler)->void:
	pending_user.ui_element.last_enemy_selected = target
	match battle_scene.ui_state:
		"ACTION_TARGETING":
			_confirm_action([target])
		"DEFEND_TARGETING":
			#shouldn't do anything, party shouldn't be able to defend the enemy
			pass

func on_party_pressed(target : Battler)->void:
	match battle_scene.ui_state:
		"ACTION_TARGETING":
			_confirm_action([target])
		"DEFEND_TARGETING":
			_confirm_action([target])
			pass


	
func _confirm_action(targets : Array[Battler])->void:
	var final_targets : Array[Battler] = targets

	if pending_data.has("all_mode") and pending_data["all_mode"] == true:
		pending_data.erase("all_mode")

		var skill = null
		if pending_data.has("skill"):
			skill = pending_data["skill"] as Skill

		if skill != null and not targets.is_empty():
			final_targets = _build_all_targets_for_skill(skill, targets[0])

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



func _confirm_action_other()->void:
	for bat in  battle_scene.battlers.get_children():
		if bat is Battler:
			bat.ui_element.deactivate_button()
		if battle_scene.acting_battler.ui_element is BattleStats:
			battle_scene.acting_battler.ui_element.show_commands = false

##Sets pending_user and pending_action to null
func _end_targeting()->void:
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
##Focuses first skill in the menu
func focus_first_element(gcontainer : GridContainer)->void:
	if !gcontainer.get_children().is_empty():
		for child in gcontainer.get_children():
			child.grab_button_focus()
			break
			
		
	
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


##TODO FINISH THIS FUNCTION
func setup_itemskill_button_neighbors(gcontainer : GridContainer)->void:
	pass

##Shows item list. Only shows battle-usable items.
func show_item_window(battler : Battler)->void:
	if !Inventory.current_inventory.is_empty(): #items present, go ahead and open
		for itslt in Inventory.current_inventory:
			if itslt.item != null:
				if itslt.item.scope == Item.UseScope.BATTLE_ONLY or itslt.item.scope == Item.UseScope.ALL: #item can be used in battle
					if !itslt.item.effects.is_empty(): #item has effects. redundant safety check
						#makes the button
						var new_button : BattleItemButton = battle_scene.BATTLE_ITEM_BUTTON.instantiate()
						battle_scene.item_grid_container.add_child(new_button)
						new_button.itemslot = itslt
						new_button.setup()
						new_button.is_active = false
				
		battle_scene.ui_state = "ITEM_WINDOW_OPEN" #sets ui_state
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
	pending_data = { "skill": skill }

	_begin_targeting_for_skill(skill)


func begin_use_item(user : Battler, slot : InventorySlot) -> void:
	if user == null or slot == null or slot.item == null:
		return
	pending_user = user
	pending_action = battle_scene.BATTLEACTION_ITEM
	pending_data = { "item_slot": slot }

	_begin_targeting_for_item(slot.item)
	
func _begin_targeting_for_skill(skill : Skill) -> void:
	if skill.target_shape == Skill.TargetShape.SELF:
		_confirm_action([pending_user])
		return

	var valid_targets : Array[Battler] = _gather_valid_targets(skill.target_side, skill.can_target_dead)

	if valid_targets.is_empty():
		GameMenu.play_error_sound()
		_end_targeting()
		battle_scene.ui_state = "ACTION_SELECT"
		if battle_scene.acting_battler != null and battle_scene.acting_battler.ui_element is BattleStats:
			var stats = battle_scene.acting_battler.ui_element as BattleStats
			stats.show_commands = true
			stats.last_button_selected.grab_button_focus()
		return

	if skill.target_shape == Skill.TargetShape.ALL:
		pending_data["all_mode"] = true
		_activate_targets(valid_targets)
		battle_scene.ui_state = "ACTION_TARGETING"
		_focus_default_target(valid_targets)
		return

	_activate_targets(valid_targets)
	battle_scene.ui_state = "ACTION_TARGETING"
	_focus_default_target(valid_targets)

func _begin_targeting_for_item(item : Item) -> void:
	if item == null:
		return

	# Mirror Skill behavior for basic shapes
	if item.target_shape == Item.TargetShape.NONE:
		GameMenu.play_error_sound()
		_end_targeting()
		battle_scene.ui_state = "ACTION_SELECT"
		if battle_scene.acting_battler != null and battle_scene.acting_battler.ui_element is BattleStats:
			var stats = battle_scene.acting_battler.ui_element as BattleStats
			stats.show_commands = true
			stats.last_button_selected.grab_button_focus()
		return

	if item.target_shape == Item.TargetShape.SELF:
		_confirm_action([pending_user])
		return

	var valid_targets : Array[Battler] = _gather_valid_item_targets(item)

	if valid_targets.is_empty():
		GameMenu.play_error_sound()
		_end_targeting()
		battle_scene.ui_state = "ACTION_SELECT"
		if battle_scene.acting_battler != null and battle_scene.acting_battler.ui_element is BattleStats:
			var stats2 = battle_scene.acting_battler.ui_element as BattleStats
			stats2.show_commands = true
			stats2.last_button_selected.grab_button_focus()
		return

	if item.target_shape == Item.TargetShape.ALL:
		_confirm_action(valid_targets)
		return

	_activate_targets(valid_targets)
	battle_scene.ui_state = "ACTION_TARGETING"
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


func _activate_targets(valid : Array[Battler]) -> void:
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			bat.ui_element.deactivate_button()

	for bat in valid:
		bat.ui_element.activate_button()

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

	valid[0].ui_element.grab_button_focus()

	


#endregion Item and Skill Use
