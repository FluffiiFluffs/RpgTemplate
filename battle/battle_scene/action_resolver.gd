class_name ActionResolver
extends Node
##action_resolver.gd
##Advances phases and determines what happens in what order.
## Executes an ActionUse through the action pipeline.
## Applies universal rules in a consistent order: permission checks, status hooks, calculator calls, and state changes.
## Coordinates battle messaging for the action and emits action lifecycle signals.
## Does not choose the acting battler, does not handle turn order, and does not drive player input.	

var battle_scene : BattleScene = null


#region Intro
##Shows the intro message for the battle. Intro message changes for how many enemies are in the enemy_group. Picks a random enemy's name as the "leader".
func show_intro_message()->void:
	battle_scene.battle_state = "INTRO_MESSAGE"
	var enemy_array : Array[Battler] = []
	var enemy_name : String = ""
	var randmindex : int = 0
	var rmessages : Array[String] = []
	for bat in battle_scene.battlers.get_children():
		if bat.faction == Battler.Faction.ENEMY:
			enemy_array.append(bat)
			
	var renemyindex : int = randi_range(0, enemy_array.size() - 1)
	enemy_name = enemy_array[renemyindex].actor_data.char_resource.char_name

	
	if enemy_array.size() == 1: #if there's only one enemy
		rmessages = [
		enemy_name + " approaches.",
		enemy_name + " suddenly attacks.",
		enemy_name + " moves forward aggressively!",
		]
		randmindex = randi_range(0, rmessages.size() - 1)
	elif enemy_array.size() > 1: #if there's more than one enemy

		rmessages = [
		enemy_name + " and its allies approach!",
		enemy_name + " and cohorts suddenly attack!",
		enemy_name + " and others moves forward aggressively!",
		]
		randmindex = randi_range(0, rmessages.size() - 1)
	randmindex = randi_range(0, rmessages.size() - 1)
	var rand_message : String = rmessages[randmindex]
	
	battle_scene.battle_notify_ui.queue_notification(rand_message)
	await battle_scene.notify_finished
#endregion Intro

#region Action Execution
##Executes the ActionUse that is provided as an argument. Top level function that determines what to do based upon actionuse.action_type
func execute_action_use(use: ActionUse)->void:
	battle_scene.battle_state = "ACTION_EXECUTE"
	battle_scene.ui_state = "NOTIFYING"
	match use.action_type:
		BattleAction.ActionType.NORMAL_ATTACK:
			await _execute_normal_attack(use)
		BattleAction.ActionType.RUN:
			await _execute_run(use)
		BattleAction.ActionType.DEFEND:
			await _execute_defend(use)

		null:
			printerr("Null action!")
		_:
			printerr("Unknown action type")
#
#func _execute_normal_attack(use : ActionUse)->void:
	#var from = use.user
	#var to = use.first_target() #attack only hits one target
	#var from_name = from.actor_data.char_resource.char_name
	#var to_name = to.actor_data.char_resource.char_name
	##Announce
	#battle_scene.battle_notify_ui.queue_notification(from_name + " attacks " + to_name + ".")
	#
	#var dmg = battle_scene.action_calculator.normal_attack(from, use.action, to)
	#
	#if dmg == -1:
		#battle_scene.battle_notify_ui.queue_notification(from_name + "'s attack missed!")
		#await battle_scene.notify_finished
		#return
		#
	#
	#to.actor_data.current_hp = clampi(to.actor_data.current_hp - dmg, 0, to.actor_data.get_max_hp())
#
	## play hit anim if the target UI supports it
	#if to.ui_element != null and to.ui_element.has_method("play_normal_hit"):
		#to.ui_element.play_normal_hit()
#
	## update party UI if the target is a party member
	#if to.ui_element is BattleStats:
		#var stats = to.ui_element as BattleStats
		#await stats.hp_changed()
#
	#battle_scene.battle_notify_ui.queue_notification(to_name + " takes " + str(dmg) + " damage.")
	#check_for_death(to, from)
	#
	#await battle_scene.notify_finished
	
func _execute_normal_attack(use : ActionUse)->void:
	var attacker = use.user
	var original_target = use.first_target()
	if attacker == null or original_target == null:
		printerr("ActionResolver: normal attack missing attacker or target")
		return

	var attacker_name = attacker.actor_data.char_resource.char_name
	var original_name = original_target.actor_data.char_resource.char_name

	var final_target : Battler = battle_scene.status_system.resolve_incoming_target(attacker, use.action, original_target)
	var final_name = final_target.actor_data.char_resource.char_name

	battle_scene.battle_notify_ui.queue_notification(attacker_name + " attacks " + original_name + ".")
	if final_target != original_target:
		battle_scene.battle_notify_ui.queue_notification(final_name + " intercepts the attack.")

	var dmg = battle_scene.action_calculator.normal_attack(attacker, use.action, final_target)
	if dmg == -1:
		battle_scene.battle_notify_ui.queue_notification(attacker_name + "'s attack missed!")
		await battle_scene.notify_finished
		return

	dmg = battle_scene.status_system.modify_incoming_physical_damage(attacker, use.action, original_target, final_target, dmg)

	final_target.actor_data.current_hp = clampi(final_target.actor_data.current_hp - dmg, 0, final_target.actor_data.get_max_hp())

	if final_target.ui_element != null and final_target.ui_element.has_method("play_normal_hit"):
		final_target.ui_element.play_normal_hit()

	#if final_target.ui_element is BattleStats:
		#var stats = final_target.ui_element as BattleStats
		#await stats.hp_changed()

	battle_scene.battle_notify_ui.queue_notification(final_name + " takes " + str(dmg) + " damage.")

	await battle_scene.notify_finished

	if final_target.ui_element is BattleStats:
		var stats = final_target.ui_element as BattleStats
		await stats.hp_changed()
	check_for_death(final_target, attacker)


	
	
##Plays notification the battler is dead. Removes battler from turn_order[]. Deactivates selection button (though this should be enabled/disabled as needed).
func check_for_death(to : Battler, from :  Battler)->void:
	#checks to see if the battler died after being hit by an attack
	if to.actor_data.current_hp <= 0:
		battle_scene.battle_notify_ui.queue_notification(to.actor_data.char_resource.char_name + " falls to the ground!")
		to.ui_element.deactivate_button() #redundant, this should happen when targeting is pulled up
		
		#If the killed battler was an enemy, then distribute exp/money/loot(items)
		if to.faction == Battler.Faction.ENEMY:
			var enemy = to.actor_data
			if enemy is EnemyData:
				if enemy.experience != 0:
					battle_scene.exp_earned += enemy.experience #add exp to pool
				if enemy.money != 0:
					battle_scene.money_earned += enemy.money #add money to pool
				for ld in enemy.loot_table:
					if ld is LootDrop:
						var getloot = ld.roll()
						if getloot:
							battle_scene.loot_earned.append(ld.loot) #add items to pool
		elif to.faction == Battler.Faction.PARTY:
			print("THE PARTY IS DEAD")
			pass
		#remove the battler from turn_order[]
		while battle_scene.turn_order.has(to):
			battle_scene.turn_order.erase(to) #actual removal from the list
			battle_scene.update_turn_order_ui() #Updates the UI to match
		

func _execute_run(use : ActionUse)->void:
	var runner = use.user
	var runner_name = runner.actor_data.char_resource.char_name
	#battle_scene.battle_notify_ui.queue_notification(runner_name + " attempts to run!")
	#await battle_scene.notify_finished
	var success = battle_scene.action_calculator.run_success(runner)
	if success:
		if runner is Battler:
			if runner.faction == Battler.Faction.PARTY:
				battle_scene.battle_state = "BATTLE_END"
				battle_scene.battle_notify_ui.queue_notification(runner_name.capitalize() + " escaped from battle!")
				await battle_scene.notify_finished
				SceneManager.main_scene.end_battle_run()
				return
			elif runner.faction == Battler.Faction.ENEMY:
				#remove enemy from turn_order
				#remove enemy battler from battlers
				#update_turn_order_ui
				#proceed to next turn
				return
	else: #success is false
		battle_scene.battle_notify_ui.queue_notification(runner_name + " failed to escape!")
		await battle_scene.notify_finished
				

func _execute_defend(use : ActionUse) -> void:
	var defender : Battler = use.user
	var protected : Battler = use.first_target()
	if defender == null or protected == null:
		printerr("ActionResolver: defend missing defender or target")
		return

	var defender_name : String = defender.actor_data.char_resource.char_name
	var protected_name : String = protected.actor_data.char_resource.char_name

	# Clear existing defend link on the defender (also removes its linked Defended)
	battle_scene.status_system.remove_status_by_class(defender, StatusEffectDefending)

	# If the protected battler is already linked to someone else, clear that link too
	var existing_defended : StatusEffect = StatusSystem.find_status(protected, StatusEffectDefended)
	if existing_defended != null:
		var defended_status : StatusEffectDefended = existing_defended as StatusEffectDefended
		var old_defender : Battler = defended_status.defender
		battle_scene.status_system.remove_status(protected, defended_status)
		if old_defender != null and old_defender != defender:
			battle_scene.status_system.remove_status_by_class(old_defender, StatusEffectDefending)

	# Create fresh per application instances
	var defending : StatusEffectDefending = StatusEffectDefending.new()
	defending.protected = protected
	battle_scene.status_system.add_status(defender, defending, defender)

	var defended : StatusEffectDefended = StatusEffectDefended.new()
	defended.defender = defender
	battle_scene.status_system.add_status(protected, defended, defender)

	if defender == protected:
		battle_scene.battle_notify_ui.queue_notification(defender_name + " assumes a defensive stance.")
	else:
		battle_scene.battle_notify_ui.queue_notification(defender_name + " moves to defend " + protected_name + ".")

	await battle_scene.notify_finished


#endregion Action Execution






##region Round and Turn Loop
###Advances to the next battler's turn or sets up the next round.
###battle_state = "ROUND_SETUP", sorts turn order. updates turn order UI
#func round_next_setup()->void:
	#battle_scene.battle_state = "ROUND_SETUP"
	#battle_scene.sort_turn_order() #clears turn_order[], adds battlers to turn_order[]
	#
	#battle_scene.update_turn_order_ui() #updates the UI to show the
	#await get_tree().process_frame #waits a frame for safety, there's a lot of looping going on
	#battler_turn_next()
	#pass
#
#
#
#
###Advances to the next battler's turn or sets up the next round.
#func battler_turn_next()->void:
	#battle_scene.battle_state = "BATTLER_TURN"
	#if battle_scene.turn_order.is_empty(): #If the turn order array is empty
		#round_next_setup() #Setup the next round
		#return
	#battle_scene.acting_battler = battle_scene.turn_order[0]
	#if battle_scene.turn_order.size() > 1:
		#battle_scene.next_battler = battle_scene.turn_order[1]
	#else:
		#battle_scene.next_battler = null
	#
	#
	#
	#
	##Determine if the battler is an enemy or a party member
	#match battle_scene.acting_battler.faction:
		#Battler.Faction.PARTY:
			#party_turn()
		#Battler.Faction.ENEMY:
			#enemy_turn()
		#_: #If for some reason there's something unaccounted for...
			#printerr("battle_turn_next(): " + str(battle_scene.acting_battler.actor_data.char_resource.char_name) + " has no faction set!")
			#pass
	#await battle_scene.turn_choice_finished #waits for the battler to make an action choice
	##proceed to "ACTION_EXECUTE" state/phase
	#
#
###Routine for when it is a party member's turn. 
#func party_turn()->void:
	#battle_scene.ui_state = "ACTION_SELECT"
	##Pops up commands for the acting party member's BattleStats window
	#var pmember = battle_scene.acting_battler
	#var pmbstats = pmember.ui_element as BattleStats
	#pmbstats.show_commands = true
	#pmbstats.last_button_selected.grab_button_focus()
	#
	##allow player to select their command choice
	##command choice recorded into variable
	##command choice emits turn_choice_finished signal
	##battler_turn_next() continues to process
	##
	#pass
#
#
###Routine for when it is an enemy's turn.
#func enemy_turn()->void:
	#battle_scene.ui_state = "NOTIFYING"
	##use enemy AI to determine what to do #TODO Make enemy AI somehow
	##play messages (called from battleaction)
	#pass
#
#
#
#
#func battler_turn_done()->void:
	#if battle_scene.turn_order.is_empty():
		#round_next_setup()
		#return
	#
	#battle_scene.turn_order.remove_at(0)
	#battle_scene.update_turn_order_ui() #turn_order.pop_front() already called during battler_turn_next(), but updating the UI should happen here.
	##determines if all party is dead, if so game over
	##determines if all enemies are dead, if so, victory
	#battler_turn_next()
	#pass
#
#
#
##endregion Round and Turn Loop



###Executes BattleAction's script. Needs the originator of the action, the action, and the target. Target is optional since there are actions that do not require a target (run)
#func execute_battler_action(from : Battler, action : BattleAction, to : Battler = null)->void:
##battle_state set to "ACTION_EXECUTE"
	#battle_scene.battle_state = "ACTION_EXECUTE"
##ui state set to "notifying" (player can hit buttons to advance messages)
	#battle_scene.ui_state = "NOTIFYING"
##plays out recorded action (battleaction) visually. (probably need to make individual scene that autoplay an animation at the appropriate location on screen per each battleaction. battlevfx should maybe have a function that determines what animation to play and where)
##changes values on the target the action is being enacted on (if action has a target). This needs to probably be handled by a script within the battleaction itself. each battleaction should probably have the same function name, but do different things. This shouldn't be handled by battle_scene. 
##advance battle state/phase to "TURN_END"	
	#pass
