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
	battle_scene.battle_state = "BATTLER_TURN"

	if battle_scene.turn_order.is_empty():
		round_next_setup()
		return

	battle_scene.acting_battler = battle_scene.turn_order[0]

	var turn_id : int = _next_turn_id()
	battle_scene.status_system.current_turn_id = turn_id

	var did_tick : bool = await battle_scene.status_system.on_turn_start(battle_scene.acting_battler)

	if did_tick:
		if battle_scene.acting_battler.ui_element is BattleStats:
			var stats : BattleStats = battle_scene.acting_battler.ui_element as BattleStats
			await stats.hp_changed()

		if battle_scene.acting_battler.actor_data.current_hp <= 0:
			await battle_scene.action_resolver.check_for_death(battle_scene.acting_battler, battle_scene.acting_battler)
			await battle_scene.notify_finished

			if battle_scene.battle_state == "BATTLE_END":
				return

			call_deferred("battler_turn_next")
			return

	if battle_scene.turn_order.size() > 1:
		battle_scene.next_battler = battle_scene.turn_order[1]
	else:
		battle_scene.next_battler = null

	var directive : Dictionary = battle_scene.status_system.get_turn_directive(battle_scene.acting_battler)

	var forced_use : ActionUse = null
	if directive.has("forced_action_use"):
		forced_use = directive["forced_action_use"] as ActionUse

	if forced_use != null:
		battle_scene.ui_state = "NOTIFYING"
		battle_scene.hide_party_commands()

		await battle_scene.action_resolver.execute_action_use(forced_use)

		if battle_scene.battle_state == "BATTLE_END":
			return

		battler_turn_done()
		return

	var can_execute : bool = true
	if directive.has("can_execute_action"):
		can_execute = bool(directive["can_execute_action"])

	if not can_execute:
		battle_scene.ui_state = "NOTIFYING"
		battle_scene.hide_party_commands()
		battler_turn_done()
		return

	var use : ActionUse = null

	match battle_scene.acting_battler.faction:
		Battler.Faction.PARTY:
			var can_select : bool = true
			if directive.has("can_select_commands"):
				can_select = bool(directive["can_select_commands"])

			if not can_select:
				battle_scene.ui_state = "NOTIFYING"
				battle_scene.hide_party_commands()
				battler_turn_done()
				return

			battle_scene.command_controller.begin_turn(turn_id)
			party_turn()
			use = await _await_party_action_use(turn_id)

		Battler.Faction.ENEMY:
			use = enemy_turn()

		_:
			printerr("battler_turn_next(): " + str(battle_scene.acting_battler.actor_data.get_display_name()) + " has no faction set!")
			battler_turn_done()
			return

	if use == null:
		printerr("battler_turn_next(): ActionUse is null")
		battler_turn_done()
		return

	var cancel_selected : bool = battle_scene.status_system.on_action_selected(battle_scene.acting_battler, use)
	if cancel_selected:
		battle_scene.ui_state = "NOTIFYING"
		battle_scene.hide_party_commands()
		await battle_scene.notify_finished
		battler_turn_done()
		return

	await battle_scene.action_resolver.execute_action_use(use)

	if battle_scene.battle_state == "BATTLE_END":
		return

	var bonus_use : ActionUse = battle_scene.status_system.get_post_action_bonus_use(use)
	if bonus_use != null:
		assert(bonus_use.user != null)
		assert(bonus_use.user.actor_data != null)

		var name_text : String = bonus_use.user.actor_data.get_display_name()
		battle_scene.battle_notify_ui.queue_notification(name_text + " acts again.")
		await battle_scene.notify_finished

		await battle_scene.action_resolver.execute_action_use(bonus_use)

		if battle_scene.battle_state == "BATTLE_END":
			return

	battler_turn_done()

##Routine for when it is an enemy's turn.

func enemy_turn() -> ActionUse:
	battle_scene.ui_state = "NOTIFYING"

	var enemy : Battler = battle_scene.acting_battler
	var use : ActionUse = null

	var ed : EnemyData = enemy.actor_data as EnemyData
	if ed != null:
		use = ed.ai.choose_action_use(enemy, battle_scene)

	if use == null:
		use = _fallback_enemy_attack(enemy)

	return use


func _fallback_enemy_attack(enemy : Battler) -> ActionUse:
	var target : Battler = Targeting.pick_random_living_enemy(enemy, battle_scene)

	var action : BattleAction = null
	if enemy.actor_data != null and enemy.actor_data.battle_actions != null:
		for act in enemy.actor_data.battle_actions.battle_actions:
			if act is BattleActionAttack:
				action = act
				break

	return ActionUse.new(enemy, action, [target])


func party_turn() -> void:
	battle_scene.ui_state = "ACTION_SELECT"

	var pmember : Battler = battle_scene.acting_battler
	var pmbstats : BattleStats = pmember.ui_element as BattleStats
	pmbstats.show_commands = true
	pmbstats.last_command_button_selected.grab_button_focus()
#endregion Turn Progression

#region TURN END
func battler_turn_done()->void:
	# End of turn status hook
	battle_scene.status_system.on_turn_end(battle_scene.acting_battler)

	# Remove the acting battler only if it is still at index 0.
	# If the acting battler died during its own action, check_for_death() may have already removed it.
	if not battle_scene.turn_order.is_empty():
		if battle_scene.turn_order[0] == battle_scene.acting_battler:
			battle_scene.turn_order.remove_at(0)

	battle_scene.update_turn_order_ui()

	# Always evaluate victory or defeat before starting a new round.
	var endbattle : int = check_for_end_battle()
	if endbattle == 1:
		battle_scene.end_of_battle_normal_defeat()
		return
	if endbattle == 2:
		battle_scene.end_of_battle_normal_victory()
		return

	# Continue turn flow
	if battle_scene.turn_order.is_empty():
		round_next_setup()
		return

	battler_turn_next()


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
