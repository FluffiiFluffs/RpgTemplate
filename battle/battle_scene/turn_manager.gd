class_name TurnManager
extends Node
## Drives BattleScene turn flow.
## Builds and sorts turn_order, selects acting_battler, obtains ActionUse from CommandController or enemy AI,
## executes via ActionResolver, applies StatusSystem turn hooks and directives, updates turn order UI,
## and triggers victory or defeat when one side has no living battlers.
## Uses a monotonically increasing turn id to correlate asynchronous party input with the active turn.

var battle_scene : BattleScene = null
var _turn_id_counter : int = 0

#region TurnID
## Returns a unique, monotonically increasing id for the current battle instance.
## This id exists to correlate asynchronous party input with the specific turn that requested it.
## TurnManager passes this id into CommandController.begin_turn(turn_id).
## CommandController emits action_use_chosen(turn_id, use) when the player confirms an action.
func _next_turn_id()->int:
	# Increment first so the first usable id is 1, not 0.
	# This also keeps the default uninitialized value pattern elsewhere (often -1) unambiguous.
	_turn_id_counter += 1
	return _turn_id_counter


## Waits until CommandController emits an ActionUse that matches the provided turn_id.
## This is required because action selection is asynchronous and the signal payload can arrive later than expected.
## Filtering by turn_id prevents a late emit from a prior turn from being consumed by the current turn.
func _await_party_action_use(turn_id : int)->ActionUse:
	while true:
		# action_use_chosen is declared as: signal action_use_chosen(turn_id : int, use : ActionUse)
		# Awaiting it yields an Array where index 0 is the emitted turn_id and index 1 is the ActionUse.
		var result = await battle_scene.command_controller.action_use_chosen

		# Extract the emitted turn id and the selected ActionUse.
		var rid : int = result[0]
		var use : ActionUse = result[1]

		# Only accept the selection that was produced for the turn that is currently executing.
		if rid == turn_id:
			return use

		# Any other rid is treated as stale and ignored, then we continue waiting.
		# This keeps TurnManager aligned with the current turn state.
		pass

	# Present to satisfy static analysis expectations for a typed return.
	# Control flow does not reach here during normal operation.
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
## Advances the battle flow to the next battler in the current round.
## Responsibilities:
##   Select acting_battler from turn_order.
##   Run start of turn status processing, including start of turn damage and death handling.
##   Apply status directives that can force an action or suppress action execution or command selection.
##   Acquire an ActionUse from CommandController for party battlers or from AI for enemies.
##   Execute the ActionUse through ActionResolver.
##   Handle optional post action bonus actions from StatusSystem.
##   Transition to battler_turn_done() when the battler's turn completes.
func battler_turn_next() -> void:
	# Mark the system state as inside an active battler turn.
	battle_scene.battle_state = "BATTLER_TURN"

	# If the current round has no remaining battlers in the order list, rebuild and start a new round.
	if battle_scene.turn_order.is_empty():
		round_next_setup()
		return

	# The next acting battler is always the first entry in the turn order list.
	battle_scene.acting_battler = battle_scene.turn_order[0]

	# Generate a unique turn id for this turn and push it into StatusSystem.
	# This id is also used to filter party action selection signals so stale selections cannot be consumed.
	var turn_id : int = _next_turn_id()
	battle_scene.status_system.current_turn_id = turn_id

	# Start of turn status hook.
	# This may apply start of turn effects (damage over time, regen, etc.).
	# did_tick indicates that something changed that may require UI refresh or death handling.
	var did_tick : bool = await battle_scene.status_system.on_turn_start(battle_scene.acting_battler)

	if did_tick:
		# If the acting battler is represented by BattleStats, refresh the hp bar animation after the tick.
		if battle_scene.acting_battler.ui_element is BattleStats:
			var stats : BattleStats = battle_scene.acting_battler.ui_element as BattleStats
			await stats.hp_changed()

		# If start of turn effects killed the battler, resolve death before continuing the turn loop.
		if battle_scene.acting_battler.actor_data.current_hp <= 0:
			# check_for_death handles removal from turn_order and plays messaging and visuals.
			await battle_scene.action_resolver.check_for_death(battle_scene.acting_battler, battle_scene.acting_battler)
			# Wait for queued notifications and animations to finish before advancing state.
			await battle_scene.notify_finished

			# If death resolution ended the battle, stop advancing the turn loop.
			if battle_scene.battle_state == "BATTLE_END":
				return

			# Defer to avoid immediate recursion while the scene tree is mid update.
			call_deferred("battler_turn_next")
			return

	# Cache the next battler for UI preview.
	if battle_scene.turn_order.size() > 1:
		battle_scene.next_battler = battle_scene.turn_order[1]
	else:
		battle_scene.next_battler = null

	# Ask StatusSystem whether this battler has any turn directive.
	# Directives drive conditions like sleep, stun, berserk, confuse, forced actions, and command lockouts.
	var directive : Dictionary = battle_scene.status_system.get_turn_directive(battle_scene.acting_battler)

	# If a directive provides a forced action, execute it immediately with no party input.
	var forced_use : ActionUse = null
	if directive.has("forced_action_use"):
		forced_use = directive["forced_action_use"] as ActionUse

	if forced_use != null:
		# Forced actions run while UI is in notifying mode and party commands are hidden.
		battle_scene.ui_state = "NOTIFYING"
		battle_scene.hide_party_commands()

		await battle_scene.action_resolver.execute_action_use(forced_use)

		# ActionResolver can end the battle. Stop turn flow if so.
		if battle_scene.battle_state == "BATTLE_END":
			return

		# End this battler's turn after the forced action executes.
		battler_turn_done()
		return

	# Some directives allow the battler to exist in turn order but prevent action execution.
	# Example: hard stun that consumes the turn.
	var can_execute : bool = true
	if directive.has("can_execute_action"):
		can_execute = bool(directive["can_execute_action"])

	if not can_execute:
		battle_scene.ui_state = "NOTIFYING"
		battle_scene.hide_party_commands()
		battler_turn_done()
		return

	# Acquire an ActionUse for this turn.
	# Party selection is asynchronous and comes from CommandController.
	# Enemy selection is synchronous and comes from AI.
	var use : ActionUse = null

	match battle_scene.acting_battler.faction:
		Battler.Faction.PARTY:
			# Some directives allow execution but disallow player command selection.
			# Example: auto attack or command lock, where a forced action is not used.
			var can_select : bool = true
			if directive.has("can_select_commands"):
				can_select = bool(directive["can_select_commands"])

			if not can_select:
				battle_scene.ui_state = "NOTIFYING"
				battle_scene.hide_party_commands()
				battler_turn_done()
				return

			# Begin a new party input turn with this turn id.
			# begin_turn(turn_id) allows CommandController to tag its emitted ActionUse with the same id.
			battle_scene.command_controller.begin_turn(turn_id)

			# Display party command UI and establish focus state.
			party_turn()

			# Wait until CommandController emits an ActionUse matching this turn id.
			use = await _await_party_action_use(turn_id)

		Battler.Faction.ENEMY:
			# AI selects a use for enemies. enemy_turn() sets ui_state and chooses a use or falls back.
			use = enemy_turn()

		_:
			# Faction must be set for turn flow to function.
			printerr("battler_turn_next(): " + str(battle_scene.acting_battler.actor_data.get_display_name()) + " has no faction set!")
			battler_turn_done()
			return

	# If no ActionUse was produced, end the turn to avoid locking the loop.
	if use == null:
		printerr("battler_turn_next(): ActionUse is null")
		battler_turn_done()
		return

	# Give StatusSystem a chance to react to the selected action before execution.
	# This hook can cancel the action (for example, panic, confusion reroute, or enforced wait states).
	var cancel_selected : bool = battle_scene.status_system.on_action_selected(battle_scene.acting_battler, use)
	if cancel_selected:
		battle_scene.ui_state = "NOTIFYING"
		battle_scene.hide_party_commands()
		await battle_scene.notify_finished
		battler_turn_done()
		return

	# Execute the chosen action. This drives effects, messaging, animations, and death resolution.
	await battle_scene.action_resolver.execute_action_use(use)

	# Action execution can end the battle. Stop turn flow if so.
	if battle_scene.battle_state == "BATTLE_END":
		return

	# Some statuses can grant a follow up action after a completed action.
	# Example: a status that grants an extra turn or triggers an additional skill use.
	var bonus_use : ActionUse = battle_scene.status_system.get_post_action_bonus_use(use)
	if bonus_use != null:
		# Bonus uses must be fully formed, including a valid user.
		assert(bonus_use.user != null)
		assert(bonus_use.user.actor_data != null)

		# Notify the player before executing the bonus action so the extra action has clear feedback.
		var name_text : String = bonus_use.user.actor_data.get_display_name()
		battle_scene.battle_notify_ui.queue_notification(name_text + " acts again.")
		await battle_scene.notify_finished

		await battle_scene.action_resolver.execute_action_use(bonus_use)

		if battle_scene.battle_state == "BATTLE_END":
			return

	# Complete the turn and advance the loop.
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
	var normal_skill : Skill = null
	if enemy.actor_data != null:
		normal_skill = enemy.actor_data.normal_attack_skill

	if normal_skill == null:
		return null

	var use : ActionUse = ActionUse.new(enemy, battle_scene.BATTLEACTION_SKILL, [target], {})
	use.skill = normal_skill
	return use



func party_turn() -> void:
	battle_scene.ui_state = "ACTION_SELECT"

	var pmember : Battler = battle_scene.acting_battler
	var pmbstats : BattleStats = pmember.ui_element as BattleStats
	pmbstats.show_commands = true
	pmbstats.last_command_button_selected.grab_button_focus()

#endregion Turn Progression

#region TURN END
## Completes the current acting battler turn and advances the battle loop.
## Responsibilities:
##   Run end of turn status processing for the acting battler.
##   Remove the acting battler from turn_order if it is still queued at index 0.
##   Refresh the turn order UI after any list mutation.
##   Evaluate victory or defeat and transition to end of battle sequence if required.
##   If the round is exhausted, start round setup. Otherwise, start the next battler turn.
func battler_turn_done()->void:
	# Debug trace for turn flow verification.
	# This is safe to remove once turn flow is stable and verified.
	print(battle_scene.acting_battler.name + " TURN DONE")

	# End of turn status hook.
	# StatusSystem can expire statuses, tick end of turn effects, and enqueue messages.
	battle_scene.status_system.on_turn_end(battle_scene.acting_battler)

	# Remove the acting battler only if it is still at index 0.
	# Death resolution during the action can remove the battler earlier, so this guard prevents index drift.
	if not battle_scene.turn_order.is_empty():
		if battle_scene.turn_order[0] == battle_scene.acting_battler:
			battle_scene.turn_order.remove_at(0)

	# Update the UI after potential removals so the preview matches the current order.
	battle_scene.update_turn_order_ui()

	# Evaluate victory or defeat before starting a new round or turn.
	# check_for_end_battle returns:
	#   0 = battle continues
	#   1 = party defeated
	#   2 = enemies defeated
	var endbattle : int = check_for_end_battle()
	if endbattle == 1:
		battle_scene.end_of_battle_normal_defeat()
		return
	if endbattle == 2:
		battle_scene.end_of_battle_normal_victory()
		return

	# Continue turn flow.
	# If the list is empty, the round is finished and a new round must be built.
	if battle_scene.turn_order.is_empty():
		round_next_setup()
		return

	# Otherwise advance to the next battler in the existing round order.
	battler_turn_next()


## Evaluates whether the battle has reached a terminal state.
## This counts living battlers currently present under battle_scene.battlers.
##
## Return codes:
##   0: battle continues
##   1: party defeat (no living party battlers)
##   2: party victory (no living enemy battlers)
func check_for_end_battle()->int:
	# Count living battlers by faction.
	# Battler nodes remain in the scene tree while death resolution and visuals complete,
	# so current_hp is used as the authoritative alive check.
	var party_count : int = 0
	var enemy_count : int = 0

	for bat in battle_scene.battlers.get_children():
		# battle_scene.battlers may contain non Battler nodes (helpers, VFX, etc).
		if bat is Battler:
			# Only count battlers with positive HP as living participants.
			if bat.actor_data.current_hp > 0:
				if bat.faction == Battler.Faction.PARTY:
					party_count += 1
				if bat.faction == Battler.Faction.ENEMY:
					enemy_count += 1

	# Terminal state resolution is evaluated from the living counts.
	# party_count == 0 means the party has no remaining living battlers.
	if party_count == 0:
		return 1

	# If the party still has living battlers, enemy_count == 0 means victory.
	elif party_count != 0:
		if enemy_count == 0:
			return 2

	# Default case: at least one living party battler and at least one living enemy battler remain.
	return 0

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
	
	
	
## Prunes invalid or dead battlers from battle_scene.turn_order.
## This is used to keep the queued round order consistent after HP ticks, death resolution, or removals.
##
## Removal rules:
##   1) Null entries are removed (defensive cleanup if something removed a battler without updating turn_order).
##   2) Battlers with current_hp <= 0 are removed (dead battlers should not receive turns).
##
## Status effects do not remove a battler from turn_order here.
## Status driven turn behavior is handled via StatusSystem turn directives (sleep, stun, etc).
func remove_dead_from_turn_order()->void:
	# Iterate in reverse so remove_at(i) does not shift indices that still need to be visited.
	for i in range(battle_scene.turn_order.size() - 1, -1, -1):
		var bat = battle_scene.turn_order[i]

		# Defensive cleanup: if an entry became invalid, remove it from the queue.
		if bat == null:
			battle_scene.turn_order.remove_at(i)
			continue

		# Remove battlers that are dead so they cannot be selected as acting_battler.
		if bat.actor_data.current_hp <= 0:
			battle_scene.turn_order.remove_at(i)

		# Status conditions should keep the actor in the turn_order array, so do not remove for status here.



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

#endregion Turn Order Building and Sorting
