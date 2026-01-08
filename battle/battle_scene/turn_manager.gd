class_name TurnManager
extends Node
## Owns the battle turn loop.
## Builds and sorts turn order at the start of each round, selects the next acting battler, and advances turns.
## Requests an ActionUse from CommandController for party turns or from enemy logic for enemy turns.
## Calls ActionResolver to execute the ActionUse, then checks victory or defeat and proceeds to the next turn.
## Does not do combat math and does not directly apply action effects.

var battle_scene : BattleScene = null


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

##Advances to the next battler's turn or sets up the next round.
##If turn_order is empty, then the next round is setup.
func battler_turn_next()->void:
	battle_scene.battle_state = "BATTLER_TURN"
	if battle_scene.turn_order.is_empty(): #If the turn order array is empty
		round_next_setup() #Setup the next round
		return
	battle_scene.acting_battler = battle_scene.turn_order[0]
	if battle_scene.turn_order.size() > 1:
		battle_scene.next_battler = battle_scene.turn_order[1]
	else:
		battle_scene.next_battler = null
	
	#Determine if the battler is an enemy or a party member
	match battle_scene.acting_battler.faction:
		Battler.Faction.PARTY:
			party_turn()
		Battler.Faction.ENEMY:
			enemy_turn()
		_: #If for some reason there's something unaccounted for...
			printerr("battle_turn_next(): " + str(battle_scene.acting_battler.actor_data.char_resource.char_name) + " has no faction set!")
			pass
	await battle_scene.turn_choice_finished #waits for the battler to make an action choice
	#proceed to "ACTION_EXECUTE" state/phase
	var use = battle_scene.pending_action_use
	await battle_scene.action_resolver.execute_action_use(use) 
	battler_turn_done()


##Routine for when it is an enemy's turn.
func enemy_turn()->void:
	battle_scene.ui_state = "NOTIFYING"
	#use enemy AI to determine what to do #TODO Make enemy AI somehow
	#play messages (called from battleaction)
	
	call_deferred("_enemy_choose_and_emit")
	pass
	
func _enemy_choose_and_emit()->void:
	var enemy := battle_scene.acting_battler
	var use : ActionUse = null

	if enemy != null and enemy.actor_data is EnemyData:
		var ed := enemy.actor_data as EnemyData
		if ed.ai != null:
			use = ed.ai.choose_action_use(enemy, battle_scene)

	if use == null:
		# hard fallback so the battle never stalls
		use = _fallback_enemy_attack(enemy)

	battle_scene.pending_action_use = use
	battle_scene.turn_choice_finished.emit()


func _fallback_enemy_attack(enemy : Battler) -> ActionUse:
	var action := BattleActionAttack.new() # only if you want, otherwise find an existing attack action
	# Better: reuse the same logic you already used to find BattleActionAttack on the actor_data

	return null

##Routine for when it is a party member's turn. 
func party_turn()->void:
	battle_scene.ui_state = "ACTION_SELECT"
	#Pops up commands for the acting party member's BattleStats window
	var pmember = battle_scene.acting_battler
	var pmbstats = pmember.ui_element as BattleStats
	pmbstats.show_commands = true
	pmbstats.last_button_selected.grab_button_focus()
	
	pass
	
	#allow player to select their command choice
	#command choice recorded into variable
	#command choice emits turn_choice_finished signal
	#battler_turn_next() continues to process
	#
	pass

func battler_turn_done()->void:
	if battle_scene.turn_order.is_empty():
		round_next_setup()
		return
	
	battle_scene.turn_order.remove_at(0)
	battle_scene.update_turn_order_ui() #turn_order.pop_front() already called during battler_turn_next(), but updating the UI should happen here.
	#determines if all party is dead, if so game over
	#determines if all enemies are dead, if so, victory
	battler_turn_next()
	pass

#endregion Turn Progression

#region TURN END
#check to see if all enemies or party is dead
	#if so start end of battle sequence
	#if not go to next turn (next turn handles if there is no more battlers in the turn_order array)

#endregion TURN END



#region Turn Order Building and Sorting
##Clears turn_order[] of all entries
func clear_turn_order()->void:
	battle_scene.turn_order.clear()

##Sorts turn order array based on speed, stamina, current hp, and then tie_roll
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
##Speed > Stamina > HP > tie_roll
##Tie roll is guaranteed to be unique via check_tie_rolls()
func compare_battlers_for_turn_order(first : Battler, second : Battler)->bool:
	#print("SORTING")`
	var first_speed = first.actor_data.get_speed()
	var second_speed = second.actor_data.get_speed()
	if first_speed != second_speed:
		return first_speed > second_speed
	
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
