class_name ActionResolver
extends Node
##action_resolver.gd
##Advances phases and determines what happens in what order.
## Executes an ActionUse through the action pipeline.
## Applies universal rules in a consistent order: permission checks, status hooks, calculator calls, and state changes.
## Coordinates battle messaging for the action and emits action lifecycle signals.
## Does not choose the acting battler, does not handle turn order, and does not drive player input.	

var battle_scene : BattleScene = null

func _await_notify_if_needed() -> void:
	var ui : BattleNotifyUI = battle_scene.battle_notify_ui
	if ui.notifying or not ui.notify_queue.is_empty():
		await battle_scene.notify_finished

#region Intro
#region Intro
## Shows the battle intro notification.
## Message variants depend on the number of enemy battlers present.
## A random enemy name is used as the referenced enemy in the message text.
##
## Assumption: at least one enemy battler exists in battle_scene.battlers.
func show_intro_message()->void:
	# Intro messaging is treated as its own battle phase.
	battle_scene.battle_state = "INTRO_MESSAGE"

	# Collect the enemy battlers that are participating in this battle.
	var enemy_array : Array[Battler] = []
	var enemy_name : String = ""
	var randmindex : int = 0
	var rmessages : Array[String] = []

	for bat in battle_scene.battlers.get_children():
		# Only enemies are used to build the intro message set.
		if bat.faction == Battler.Faction.ENEMY:
			enemy_array.append(bat)

	# Select a random enemy from the list to act as the named reference in the intro line.
	# This will error if enemy_array is empty, so the battle setup is expected to guarantee at least one enemy.
	var renemyindex : int = randi_range(0, enemy_array.size() - 1)
	enemy_name = enemy_array[renemyindex].actor_data.get_display_name()

	# Build candidate messages based on enemy count.
	# One enemy uses singular phrasing, multiple enemies use group phrasing.
	if enemy_array.size() == 1:
		rmessages = [
			enemy_name + " approaches.",
			enemy_name + " suddenly attacks.",
			enemy_name + " moves forward aggressively!",
		]
		# This roll is redundant because randmindex is rolled again after the branches.
		randmindex = randi_range(0, rmessages.size() - 1)
	elif enemy_array.size() > 1:
		rmessages = [
			enemy_name + " and its allies approach!",
			enemy_name + " and cohorts suddenly attack!",
			enemy_name + " and others moves forward aggressively!",
		]
		# This roll is redundant because randmindex is rolled again after the branches.
		randmindex = randi_range(0, rmessages.size() - 1)

	# Final selection roll from the assembled message list.
	# This overwrites the earlier randmindex assignment inside the branch.
	randmindex = randi_range(0, rmessages.size() - 1)
	var rand_message : String = rmessages[randmindex]

	# Queue and wait so the intro line fully displays before battle flow proceeds.
	battle_scene.battle_notify_ui.queue_notification(rand_message)
	await battle_scene.notify_finished
#endregion Intro

#endregion Intro

#region Action Execution

## Executes an ActionUse through the battle action pipeline.
## This is the top level dispatcher for action execution.
##
## Responsibilities
## 1. Validates required references at the subsystem boundary.
## 2. Forces BattleScene into an action execution state and locks UI into notifying mode.
## 3. Mirrors key ActionUse fields onto BattleScene so downstream messaging and VFX can reference
##    battle_scene.acting_battler and battle_scene.targeted_battler.
## 4. Dispatches to a specialized handler based on action_type.
##
## Notes on ActionUse normalization
## Some callers provide transient payload fields in use.data (for example "skill" or "item_slot").
## This function validates those payloads exist for the relevant action types before dispatching.
func execute_action_use(use : ActionUse) -> void:
	# Boundary assertions. ActionResolver expects all of these to be wired and valid.
	assert(battle_scene != null)
	assert(use != null)
	assert(use.user != null)
	assert(use.action != null)
	assert(use.action != null) # Duplicate assert retained to avoid behavior edits during a comment pass.
	assert(use.data != null)

	# State transition for the BattleScene action phase.
	battle_scene.battle_state = "ACTION_EXECUTE"

	# Action execution runs while notifications and animations play, so input should be locked.
	battle_scene.ui_state = "NOTIFYING"

	var user : Battler = use.user

	# Mirror the user onto BattleScene so all downstream systems have a consistent source of truth
	# for the current actor, even when execution originates from AI or a status forced action.
	battle_scene.acting_battler = user

	# Mirror a primary target onto BattleScene for UI highlight and VFX targeting.
	# Some action types can have no target (RUN), but this value is still set for consistency.
	battle_scene.targeted_battler = use.first_target()

	# Dispatch by action type. Each branch validates any additional fields required by that action.
	match use.action_type:
		BattleAction.ActionType.RUN:
			# Run attempts do not require a target.
			await _execute_run(use)

		BattleAction.ActionType.DEFEND:
			# Defend requires a target battler to protect, including self defend.
			assert(use.first_target() != null)
			await _execute_defend(use)

		BattleAction.ActionType.USE_ITEM:
			# Item use requires a target battler and a valid inventory slot reference.
			assert(use.first_target() != null)

			# ActionUse may carry item_slot directly, or it may be stored in use.data by the caller.
			var slot_check : InventorySlot = use.item_slot
			if slot_check == null and use.data.has("item_slot"):
				slot_check = use.data["item_slot"] as InventorySlot
			assert(slot_check != null)

			await _execute_use_item(use)

		BattleAction.ActionType.USE_SKILL:
			# Skill use requires a target battler and a valid Skill reference.
			assert(use.first_target() != null)

			# ActionUse may carry skill directly, or it may be stored in use.data by the caller.
			var skill_check : Skill = use.skill
			if skill_check == null and use.data.has("skill"):
				skill_check = use.data["skill"] as Skill
			assert(skill_check != null)

			await _execute_use_skill(use)

		_:
			# Unknown action types are logged for debugging, then execution returns with no further action.
			printerr("Unknown action type: " + str(use.action_type))





##Plays notification the battler is dead. Removes battler from turn_order[]. Deactivates selection button (though this should be enabled/disabled as needed).
func check_for_death(to : Battler, _from :  Battler)->void:
	#checks to see if the battler died after being hit by an attack
	if to.actor_data.current_hp <= 0:
		battle_scene.status_system.on_death(to)
		battle_scene.battle_notify_ui.queue_notification(to.actor_data.get_display_name() + " falls to the ground!")
		to.ui_element.deactivate_button()

		await battle_scene.notify_finished
		await get_tree().create_timer(1.0).timeout

		#If the killed battler was an enemy, then distribute exp/money/loot(items)
		if to.faction == Battler.Faction.ENEMY:
			var enemy = to.actor_data
			if enemy is EnemyData:
				to.ui_element.visible = false
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
	var runner_name = runner.actor_data.get_display_name()
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
				
## Executes a DEFEND ActionUse.
## This establishes a "defend link" in StatusSystem so incoming attacks can be redirected or mitigated
## according to your defend rules.
##
## Expected inputs
##   use.user is the defending battler
##   use.first_target() is the protected battler (can be the same as the defender for self defend)
##
## Output
##   Queues a single notification describing the defend action, then waits for notify completion.
func _execute_defend(use : ActionUse) -> void:
	# ActionUse normalization for defend.
	# user is the defender, first_target is the protected battler.
	var defender : Battler = use.user
	var protected : Battler = use.first_target()

	# Boundary assertions for required references.
	assert(defender != null)
	assert(protected != null)

	# Names are used for the battle notification text.
	var defender_name : String = defender.actor_data.get_display_name()
	var protected_name : String = protected.actor_data.get_display_name()

	# StatusSystem owns the actual defend relationship data.
	# If the link cannot be created, do not proceed with messaging.
	var did_link : bool = battle_scene.status_system.set_defend_link(defender, protected)
	if not did_link:
		printerr("ActionResolver: defend failed to set defend link")
		return

	# Message differs depending on whether this is self defend or defending another battler.
	if defender == protected:
		battle_scene.battle_notify_ui.queue_notification(defender_name + " assumes a defensive stance.")
	else:
		battle_scene.battle_notify_ui.queue_notification(defender_name + " moves to defend " + protected_name + ".")

	# Wait so the turn pipeline does not advance while the notification is still active.
	await battle_scene.notify_finished

## Executes a USE_SKILL ActionUse.
## Responsibilities:
## Normalizes the Skill reference onto use.skill, pays cost unless flagged free_cost,
## queues the skill message, applies the skill effects to all targets, emits any queued
## effect messages from the EffectContext, plays damage popups caused to the user,
## updates BattleStats UI for user and targets, and resolves deaths caused by the action.
func _execute_use_skill(use : ActionUse) -> void:
	# The battler performing the skill.
	var user : Battler = use.user

	# Normalize the Skill reference.
	# Some callers populate use.skill directly, others place it in use.data["skill"].
	var skill : Skill = use.skill
	if skill == null and use.data.has("skill"):
		skill = use.data["skill"] as Skill
	assert(skill != null)

	# Store the normalized skill on the ActionUse and remove the transient payload entry.
	use.skill = skill
	use.data.erase("skill")

	var user_name : String = user.actor_data.get_display_name()

	# free_cost is used for forced actions or special cases where SP or HP costs should not be paid.
	var is_free_cost : bool = false
	if use.data.has("free_cost"):
		is_free_cost = bool(use.data["free_cost"])

	# Cost gate. If the user cannot pay the cost, the action is canceled with a notification.
	if not is_free_cost:
		if not skill.can_pay_cost(user.actor_data):
			battle_scene.battle_notify_ui.queue_notification(user_name + " cannot use " + skill.name + ".")
			await battle_scene.notify_finished
			return

	# Cache user resources so UI deltas can be refreshed after the action resolves.
	var before_user_hp : int = user.actor_data.current_hp
	var before_user_mp : int = user.actor_data.current_sp

	# Pay the skill cost before effect execution so downstream effects see the post cost state.
	# Some skills may spend SP, HP, or other resources depending on the Skill implementation.
	if not is_free_cost:
		skill.pay_cost(user.actor_data)

	# after_cost_user_hp is used as the baseline to detect additional self damage caused during effect application.
	var after_cost_user_hp : int = user.actor_data.current_hp

	# Create a battle execution context. This provides access to battle systems and message queues.
	var ctx : EffectContext = EffectContext.make_battle_execution(use, battle_scene)

	# Build and queue the skill message using the TextParser.
	var message : String = skill.message_template
	message = battle_scene.text_parser.parse_skill_message(use, skill)
	battle_scene.battle_notify_ui.queue_notification(message)

	# Fetch all effects for this context and apply them across all targets.
	var effects : Array[Effect] = skill.get_effects_for_context(ctx)
	var any_effect_applied : bool = false

	for target in use.targets:
		for effect in effects:
			if effect == null:
				continue
			if effect.apply_to_battler(ctx, target):
				any_effect_applied = true

	# Compute damage taken by the user after paying cost.
	# This captures self damage that occurs during effect execution (recoil, backlash, counters that target user, etc).
	var user_damage_taken : int = after_cost_user_hp - user.actor_data.current_hp

	# Some effects may have already produced a user damage popup (for example via a custom effect path).
	# popped_user_damage is used to prevent double popups for the same damage instance.
	var already_popped_user_damage : int = 0
	if use.data.has("popped_user_damage"):
		already_popped_user_damage = int(use.data["popped_user_damage"])

	var popup_user_damage : int = user_damage_taken - already_popped_user_damage
	if popup_user_damage < 0:
		popup_user_damage = 0

	# Show damage popup on the user if additional damage occurred during execution.
	if popup_user_damage > 0:
		battle_scene.battle_vfx.pop_text(user, popup_user_damage)

	# Determine whether any feedback was produced by effects.
	# ctx.had_effect_feedback is set by effects that intentionally display something even when no effect applies.
	var had_effect_feedback : bool = ctx.had_effect_feedback

	# Flush any queued battle messages produced by effects.
	# queued_battle_message_targets allows a message to target a specific battler for parsing.
	if ctx.queued_battle_messages.size() > 0:
		had_effect_feedback = true

		for i in range(ctx.queued_battle_messages.size()):
			var template : String = ctx.queued_battle_messages[i]
			var parsed : String = template

			var parse_targets : Array[Battler] = use.targets
			if i < ctx.queued_battle_message_targets.size():
				var override_target : Battler = ctx.queued_battle_message_targets[i]
				if override_target != null:
					parse_targets = [override_target]

			parsed = battle_scene.text_parser.parse_custom_message(template, use.user, parse_targets, skill, null)
			battle_scene.battle_notify_ui.queue_notification(parsed)

	# If the skill had effects but none applied and no feedback was generated, show a generic message.
	if effects.size() > 0 and not any_effect_applied and not had_effect_feedback:
		battle_scene.battle_notify_ui.queue_notification("It has no effect.")

	# Wait for all queued notifications to complete before UI updates and death checks.
	await battle_scene.notify_finished

	# Refresh user UI only when values changed to avoid unnecessary animation calls.
	if user.ui_element is BattleStats:
		var stats_user : BattleStats = user.ui_element as BattleStats
		if user.actor_data.current_hp != before_user_hp:
			await stats_user.hp_changed()
		if user.actor_data.current_sp != before_user_mp:
			await stats_user.mp_changed()

	# Refresh target UI after effects resolve.
	for target in use.targets:
		if target.ui_element is BattleStats:
			var stats_target : BattleStats = target.ui_element as BattleStats
			await stats_target.hp_changed()
			await stats_target.mp_changed()

		# Resolve target deaths caused by this action.
		if target.actor_data.current_hp <= 0:
			await check_for_death(target, user)

	# Resolve user death if the user died during execution and the user was not already handled as a target.
	# from_battler is used as the source parameter for death handling; targeted_battler is preferred when available.
	if user.actor_data.current_hp <= 0 and not use.targets.has(user):
		var from_battler : Battler = battle_scene.targeted_battler
		if from_battler == null:
			from_battler = user
		await check_for_death(user, from_battler)
## Executes a USE_ITEM ActionUse.
## Responsibilities:
##   Normalizes the InventorySlot reference onto use.item_slot.
##   Builds an EffectContext with source_item set.
##   Queues the item message, applies item effects to all targets, and flushes any queued effect messages.
##   Handles the "It has no effect." fallback and returns early in that case.
##   Consumes the item from inventory when consume_on_use is enabled.
##   Updates BattleStats UI for targets and resolves deaths caused by the item.
func _execute_use_item(use : ActionUse) -> void:
	# The battler using the item.
	var user : Battler = use.user
	assert(user != null)

	# Item usage requires an inventory slot payload.
	# Caller may set use.item_slot directly, or provide it in use.data["item_slot"].
	if not use.data.has("item_slot"):
		printerr("ActionResolver: USE_ITEM missing item_slot in use.data")
		return

	# Normalize the InventorySlot reference.
	var slot : InventorySlot = use.item_slot
	if slot == null and use.data.has("item_slot"):
		slot = use.data["item_slot"] as InventorySlot
	assert(slot != null)
	assert(slot.item != null)

	# Store the normalized slot on the ActionUse and remove the transient payload entry.
	use.item_slot = slot
	use.data.erase("item_slot")

	# Redundant safety guard retained to avoid behavior edits during a comment pass.
	if slot == null or slot.item == null:
		printerr("ActionResolver: USE_ITEM slot or item is null")
		return

	# Resolve the Item from the inventory slot.
	var item : Item = slot.item
	var user_name : String = user.actor_data.get_display_name()

	# Build a battle execution context and attach the item as the source for effects and parsing.
	var ctx : EffectContext = EffectContext.make_battle_execution(use, battle_scene)
	ctx.source_item = item

	# Queue the item use message (template parsing includes user and targets).
	var message : String = item.message_template
	message = battle_scene.text_parser.parse_item_message(use, item)
	battle_scene.battle_notify_ui.queue_notification(message)

	# Apply item effects to all targets.
	var effects : Array[Effect] = item.get_effects_for_context(ctx)

	var any_effect_applied : bool = false
	for target in use.targets:
		for effect in effects:
			if effect == null:
				continue
			if effect.apply_to_battler(ctx, target):
				any_effect_applied = true

	# Effects can intentionally generate feedback without applying a state change.
	# queued_battle_messages is also treated as feedback.
	var had_effect_feedback : bool = ctx.had_effect_feedback
	if ctx.queued_battle_messages.size() > 0:
		had_effect_feedback = true

		# Flush any queued messages produced by effects.
		# queued_battle_message_targets can override parsing targets per message.
		for i in range(ctx.queued_battle_messages.size()):
			var template : String = ctx.queued_battle_messages[i]
			var parsed : String = template

			var parse_targets : Array[Battler] = use.targets
			if i < ctx.queued_battle_message_targets.size():
				var override_target : Battler = ctx.queued_battle_message_targets[i]
				if override_target != null:
					parse_targets = [override_target]

			parsed = battle_scene.text_parser.parse_custom_message(template, use.user, parse_targets, null, item)
			battle_scene.battle_notify_ui.queue_notification(parsed)

	# If the item has effects but none applied and no feedback was generated, show a generic message.
	# Current behavior returns immediately after displaying the message and does not consume the item.
	if effects.size() > 0 and not any_effect_applied and not had_effect_feedback:
		battle_scene.battle_notify_ui.queue_notification("It has no effect.")
		await battle_scene.notify_finished
		return

	# Consume item from inventory if the item is configured to be consumed on use.
	if item.consume_on_use:
		slot.quantity -= 1
		if slot.quantity <= 0:
			Inventory.current_inventory.erase(slot)

	# Wait for all notifications to complete before UI updates and death checks.
	await battle_scene.notify_finished

	# Refresh target UI and resolve deaths caused by the item.
	for target in use.targets:
		if target.ui_element is BattleStats:
			var stats_target : BattleStats = target.ui_element as BattleStats
			await stats_target.hp_changed()
			await stats_target.mp_changed()

		if target.actor_data.current_hp <= 0:
			await check_for_death(target, user)

#endregion Action Execution
