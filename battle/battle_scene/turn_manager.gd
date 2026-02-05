class_name TurnManager
extends Node
## Owns the battle turn loop.
## Builds and sorts turn order at the start of each round, selects the next acting battler, and advances turns.
## Requests an ActionUse from CommandController for party turns or from enemy logic for enemy turns.
## Calls ActionResolver to execute the ActionUse, then checks victory or defeat and proceeds to the next turn.
## Does not do combat math and does not directly apply action effects.

var battle_scene : BattleScene = null
var _turn_id_counter : int = 0

#region TurnID
func _next_turn_id()->int:
	_turn_id_counter += 1
	return _turn_id_counter

func _await_party_action_use(turn_id : int)->ActionUse:
	while true:
		var result = await battle_scene.command_controller.action_use_chosen
		var rid : int = result[0] #resultid
		var use : ActionUse = result[1]
		if rid == turn_id:
			return use
	return null

#endregion TurnID

#region Round Progression

##Advances to the next battler's turn or sets up the next round.
##battle_state = "ROUND_SETUP", sorts turn order. updates turn order UI
func round_next_setup()->void:
	battle_scene.battle_state = "ROUND_SETUP"
	sort_turn_order() #clears turn_order[], adds battlers to turn_order[]
	
	battle_scene.update_turn_order_ui() #updates the UI to show the new order
	await get_tree().process_frame #waits a frame for safety, there's a lot of looping going on
	battler_turn_next()
	pass
	
#endregion Round Progression


#region Turn Progression
func battler_turn_next() -> void:
	# Enter battler turn state
	battle_scene.battle_state = "BATTLER_TURN"

	# If there is no queued turn order, advance the round and exit
	if battle_scene.turn_order.is_empty():
		round_next_setup()
		return

	# Select the acting battler for this turn
	battle_scene.acting_battler = battle_scene.turn_order[0]

	# Allocate a unique id for this battler turn before status ticking
	var turn_id : int = _next_turn_id()
	if battle_scene.status_system != null:
		battle_scene.status_system.current_turn_id = turn_id

	# Tick or expire statuses that occur at the start of the battler's turn
	var did_tick : bool = false
	if battle_scene.status_system != null:
		did_tick = await battle_scene.status_system.on_turn_start(battle_scene.acting_battler)

	# If statuses changed HP (or otherwise require UI refresh), update and handle any death
	if did_tick:
		if battle_scene.acting_battler.ui_element is BattleStats:
			var stats : BattleStats = battle_scene.acting_battler.ui_element as BattleStats
			await stats.hp_changed()

		# If the battler died from start of turn ticks, resolve death before continuing
		if battle_scene.acting_battler.actor_data.current_hp <= 0:
			await battle_scene.action_resolver.check_for_death(battle_scene.acting_battler, battle_scene.acting_battler)

			# Wait until notify queue is finished before advancing the turn
			await battle_scene.notify_finished

			if battle_scene.battle_state == "BATTLE_END":
				return

			# Continue to the next battler turn safely (avoid coroutine recursion)
			call_deferred("battler_turn_next")
			return

	# Cache the next battler for UI preview purposes
	if battle_scene.turn_order.size() > 1:
		battle_scene.next_battler = battle_scene.turn_order[1]
	else:
		battle_scene.next_battler = null

	# Forced action (confuse later) takes precedence over command selection
	var forced_use : ActionUse = null
	if battle_scene.status_system != null:
		forced_use = battle_scene.status_system.get_forced_action_use(battle_scene.acting_battler)

	if forced_use != null:
		battle_scene.ui_state = "NOTIFYING"
		battle_scene.hide_party_commands()

		await battle_scene.action_resolver.execute_action_use(forced_use)

		if battle_scene.battle_state == "BATTLE_END":
			return

		battler_turn_done()
		return

	# If any status blocks taking a turn, skip cleanly
	var can_act : bool = true
	if battle_scene.status_system != null:
		can_act = battle_scene.status_system.can_battler_act(battle_scene.acting_battler)

	if not can_act:
		battle_scene.ui_state = "NOTIFYING"
		battle_scene.hide_party_commands()
		battler_turn_done()
		return

	# Build an ActionUse either from player input or enemy AI
	var use : ActionUse = null

	match battle_scene.acting_battler.faction:
		Battler.Faction.PARTY:
			# If statuses allow acting but block command selection, skip the turn here
			var can_select : bool = true
			if battle_scene.status_system != null:
				can_select = battle_scene.status_system.can_battler_select_commands(battle_scene.acting_battler)

			if not can_select:
				battle_scene.ui_state = "NOTIFYING"
				battle_scene.hide_party_commands()
				battler_turn_done()
				return

			# Enter command selection flow for this battler turn
			battle_scene.command_controller.begin_turn(turn_id)
			party_turn()
			use = await _await_party_action_use(turn_id)

		Battler.Faction.ENEMY:
			# Enemy AI selects the action immediately
			use = enemy_turn()

		_:
			printerr("battler_turn_next(): " + str(battle_scene.acting_battler.actor_data.char_resource.char_name) + " has no faction set!")
			battler_turn_done()
			return

	# If no action was produced, fail safe and advance
	if use == null:
		printerr("battler_turn_next(): ActionUse is null")
		battler_turn_done()
		return
		
	# Slow rank 3: chance for the selected action to fail (roll occurs after selection)
	var slow_status : StatusEffectSlow = null
	if battle_scene.status_system != null:
		var found_slow : StatusEffect = StatusSystem.find_status(battle_scene.acting_battler, StatusEffectSlow)
		if found_slow is StatusEffectSlow:
			slow_status = found_slow as StatusEffectSlow

	if slow_status != null and slow_status.is_max_stack():
		if randf() < slow_status.action_fail_chance_at_max:
			battle_scene.ui_state = "NOTIFYING"
			battle_scene.hide_party_commands()

			var name_text : String = "Someone"
			if battle_scene.acting_battler.actor_data != null and battle_scene.acting_battler.actor_data.char_resource != null:
				name_text = battle_scene.acting_battler.actor_data.char_resource.char_name

			battle_scene.battle_notify_ui.queue_notification(name_text + " is too slow to act.")
			await battle_scene.notify_finished
			battler_turn_done()
			return



	# Execute the chosen action
	await battle_scene.action_resolver.execute_action_use(use)

	if battle_scene.battle_state == "BATTLE_END":
		return

	# Haste rank 3: grant one extra action (attack or free skill) against the same target.
	await _try_execute_haste_bonus_action(use)

	if battle_scene.battle_state == "BATTLE_END":
		return

	# Close out this battler turn and advance
	battler_turn_done()



##Routine for when it is an enemy's turn.
func enemy_turn()->ActionUse:
	battle_scene.ui_state = "NOTIFYING"
	#use enemy AI to determine what to do #TODO Make enemy AI somehow
	#play messages (called from battleaction)
	var enemy = battle_scene.acting_battler
	var use : ActionUse = null
	var ed = enemy.actor_data as EnemyData
	if ed != null:
		use = ed.ai.choose_action_use(enemy,battle_scene)
		
	if use == null:
		use =_fallback_enemy_attack(enemy)
	return use

func _fallback_enemy_attack(enemy : Battler) -> ActionUse:
	if enemy == null:
		return null
	var target : Battler = null
	var alive : Array[Battler] = []
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.faction == Battler.Faction.PARTY and bat.actor_data.current_hp > 0:
				alive.append(bat)
	if alive.is_empty():
		return null
	target = alive[randi_range(0, alive.size() - 1)]
	var action : BattleAction = null
	if enemy.actor_data != null and enemy.actor_data.battle_actions != null:
		for act in enemy.actor_data.battle_actions.battle_actions:
			if act is BattleActionAttack:
				action = act
				break
	return ActionUse.new(enemy, action, [target])
	
	
	
	
	
##Routine for when it is a party member's turn. 
func party_turn()->void:
	battle_scene.ui_state = "ACTION_SELECT"
	#Pops up commands for the acting party member's BattleStats window
	var pmember = battle_scene.acting_battler
	var pmbstats = pmember.ui_element as BattleStats
	pmbstats.show_commands = true
	pmbstats.last_command_button_selected.grab_button_focus()
	
	#allow player to select their command choice
	#command choice recorded into variable
	#command choice emits turn_choice_finished signal
	#battler_turn_next() continues to process
	#
	pass


func _try_execute_haste_bonus_action(original_use : ActionUse) -> void:
	if original_use == null:
		return

	var user : Battler = original_use.user
	if user == null:
		return
	if user.actor_data == null:
		return
	if user.actor_data.current_hp <= 0:
		return

	if battle_scene == null or battle_scene.status_system == null:
		return

	var found_haste : StatusEffect = StatusSystem.find_status(user, StatusEffectHaste)
	var haste_status : StatusEffectHaste = null
	if found_haste is StatusEffectHaste:
		haste_status = found_haste as StatusEffectHaste

	if haste_status == null:
		return
	if not haste_status.is_max_stack():
		return

	# Haste bonus actions never trigger for item usage.
	if original_use.action_type == BattleAction.ActionType.USE_ITEM:
		return

	# Requirement scope: single target actions only.
	if original_use.targets == null or original_use.targets.size() != 1:
		return

	var anchor_target : Battler = original_use.first_target()
	if anchor_target == null:
		return
	if anchor_target.actor_data == null:
		return

	var qualifies_offensive : bool = false
	var qualifies_beneficial : bool = false

	if original_use.action_type == BattleAction.ActionType.NORMAL_ATTACK:
		qualifies_offensive = true
	elif original_use.action_type == BattleAction.ActionType.USE_SKILL:
		if original_use.data == null:
			return
		if not original_use.data.has("skill"):
			return
		var skill : Skill = original_use.data["skill"] as Skill
		if skill == null:
			return
		if skill.target_shape != Skill.TargetShape.SINGLE:
			return

		# Decide beneficial vs offensive by keying off the actual chosen target.
		if anchor_target.faction == user.faction:
			qualifies_beneficial = true
		else:
			qualifies_offensive = true
	else:
		return

	if not qualifies_offensive and not qualifies_beneficial:
		return

	var bonus_target : Battler = null
	if qualifies_offensive:
		bonus_target = anchor_target
		if bonus_target.actor_data.current_hp <= 0:
			bonus_target = _pick_random_alive_other_faction_target(user)
			if bonus_target == null:
				return
	elif qualifies_beneficial:
		bonus_target = _pick_random_alive_same_faction_target(user)
		if bonus_target == null:
			return

	if battle_scene.battle_notify_ui != null:
		var name_text : String = "Someone"
		if user.actor_data.char_resource != null:
			name_text = user.actor_data.char_resource.char_name
		battle_scene.battle_notify_ui.queue_notification(name_text + " acts again.")
		await battle_scene.notify_finished

	var bonus_data : Dictionary = {}
	if original_use.data != null:
		bonus_data = original_use.data.duplicate(true)

	if original_use.action_type == BattleAction.ActionType.USE_SKILL:
		bonus_data["free_cost"] = true

	var bonus_use : ActionUse = ActionUse.new(user, original_use.action, [bonus_target], bonus_data)
	await battle_scene.action_resolver.execute_action_use(bonus_use)



func _pick_random_alive_other_faction_target(user : Battler) -> Battler:
	if battle_scene == null or battle_scene.battlers == null:
		return null
	if user == null:
		return null

	var alive : Array[Battler] = []
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.actor_data == null:
				continue
			if bat.actor_data.current_hp <= 0:
				continue
			if bat.faction == user.faction:
				continue
			alive.append(bat)

	if alive.is_empty():
		return null

	return alive[randi_range(0, alive.size() - 1)]


func _pick_random_alive_same_faction_target(user : Battler) -> Battler:
	if battle_scene == null or battle_scene.battlers == null:
		return null
	if user == null:
		return null

	var alive : Array[Battler] = []
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.actor_data == null:
				continue
			if bat.actor_data.current_hp <= 0:
				continue
			if bat.faction != user.faction:
				continue
			alive.append(bat)

	if alive.is_empty():
		return null

	return alive[randi_range(0, alive.size() - 1)]


#endregion Turn Progression

#region TURN END
func battler_turn_done()->void:
	if battle_scene.turn_order.is_empty():
		round_next_setup()
		return
	
	battle_scene.turn_order.remove_at(0)
	battle_scene.update_turn_order_ui()
	var endbattle : int = check_for_end_battle()
	if endbattle == 1: #party defeated, game over
		battle_scene.end_of_battle_normal_defeat()
		pass
	else:
		if endbattle == 2: #enemies defeated, victory
			battle_scene.end_of_battle_normal_victory()
			pass
		else: #at least one remaining on each side, battle continues.
			battler_turn_next()

	pass
##Returns int value based on if an entire faction of battlers is dead. If neither is true, returns 0.[br]
##Value 1 or 2 will break out of the battle loop into victory.
func check_for_end_battle()->int:
	var party_count : int = 0
	var enemy_count : int = 0
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.actor_data.current_hp > 0:
				if bat.faction == Battler.Faction.PARTY:
					party_count += 1
				if bat.faction == Battler.Faction.ENEMY:
					enemy_count += 1
	if party_count == 0:
		return 1
	elif party_count != 0:
		if enemy_count == 0:
			return 2
	return 0 #0 = continue with battle


#check to see if all enemies or party is dead
	#if so start end of battle sequence
	#if not go to next turn (next turn handles if there is no more battlers in the turn_order array)

#endregion TURN END



#region Turn Order Building and Sorting
##Clears turn_order[] of all entries
func clear_turn_order()->void:
	battle_scene.turn_order.clear()

##Sorts turn order array based on agility, stamina, current hp, and then tie_roll
##calls compare_battlers_for_turn_order within sort_custom()
func sort_turn_order()->void:
	clear_turn_order()
	battle_scene.battlers.add_battlers_to_turn_order()

	remove_dead_from_turn_order()
	battle_scene.turn_order.sort_custom(self.compare_battlers_for_turn_order)
	
	
	
##Removes dead battlers from turn_order array
func remove_dead_from_turn_order()->void:
	for i in range(battle_scene.turn_order.size() -1, -1, -1):
		var bat = battle_scene.turn_order[i]
		if bat == null:
			battle_scene.turn_order.remove_at(i)
			continue
		
		if bat.actor_data.current_hp <= 0:
			battle_scene.turn_order.remove_at(i)
		#status conditions should keep the actor in the turn_order array, so don't do that here

##Returns true if first battler should be placed before second battler in turn_order[]
##Agility > Stamina > HP > tie_roll
##Tie roll is guaranteed to be unique via check_tie_rolls()
func compare_battlers_for_turn_order(first : Battler, second : Battler)->bool:
	#print("SORTING")`
	var first_agility = first.actor_data.get_agility()
	var second_agility = second.actor_data.get_agility()
	if first_agility != second_agility:
		return first_agility > second_agility
	
	var first_stamina = first.actor_data.get_stamina()
	var second_stamina = second.actor_data.get_stamina()
	if first_stamina != second_stamina:
		return first_stamina > second_stamina
	
	var first_hp = first.actor_data.current_hp
	var second_hp = second.actor_data.current_hp
	if first_hp != second_hp:
		return first_hp > second_hp
	
	
	return first.tie_roll > second.tie_roll

##Checks to see if the battle is done.
func check_battle_end()->void:
	pass	
	
#endregion Turn Order Building and Sorting
