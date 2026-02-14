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
	enemy_name = enemy_array[renemyindex].actor_data.get_display_name()

	
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

func execute_action_use(use : ActionUse) -> void:
	assert(battle_scene != null)
	assert(use != null)
	assert(use.user != null)
	assert(use.action != null)

	battle_scene.battle_state = "ACTION_EXECUTE"
	battle_scene.ui_state = "NOTIFYING"

	var user : Battler = use.user

	# Mirror the ActionUse onto BattleScene fields so downstream VFX and messaging
	# can rely on battle_scene.acting_battler and battle_scene.targeted_battler
	battle_scene.acting_battler = user
	battle_scene.targeted_battler = use.first_target()

	match use.action_type:
		BattleAction.ActionType.NORMAL_ATTACK:
			assert(use.first_target() != null)
			await _execute_normal_attack(use)
		BattleAction.ActionType.RUN:
			await _execute_run(use)
		BattleAction.ActionType.DEFEND:
			assert(use.first_target() != null)
			await _execute_defend(use)
		BattleAction.ActionType.USE_ITEM:
			assert(use.first_target() != null)
			await _execute_use_item(use)
		BattleAction.ActionType.USE_SKILL:
			assert(use.first_target() != null)
			assert(use.data.has("skill"))
			assert(use.data["skill"] is Skill)
			await _execute_use_skill(use)
		_:
			printerr("Unknown action type: " + str(use.action_type))


func _execute_normal_attack(use : ActionUse) -> void:
	var attacker : Battler = use.user
	var original_target : Battler = use.first_target()

	assert(attacker != null)
	assert(original_target != null)

	var attacker_name : String = attacker.actor_data.get_display_name()
	var original_name : String = original_target.actor_data.get_display_name()

	var final_target : Battler = original_target
	var redirected : Battler = battle_scene.status_system.resolve_incoming_target(attacker, use.action, original_target)
	if redirected != null:
		final_target = redirected

	var has_intercept : bool = final_target != original_target
	var final_name : String = final_target.actor_data.get_display_name()

	battle_scene.battle_notify_ui.queue_notification(attacker_name + " attacks " + original_name + ".")

	var force_hit : bool = battle_scene.status_system.should_force_physical_hit(final_target)

	var can_miss_check : bool = not force_hit
	var can_dodge_check : bool = not force_hit
	var can_parry_check : bool = not force_hit

	if can_miss_check:
		var miss : bool = battle_scene.action_calculator.physical_will_miss(attacker, final_target, false)
		if miss:
			if has_intercept:
				battle_scene.battle_notify_ui.queue_notification(final_name + " intercepts the attack.")
			battle_scene.battle_notify_ui.queue_notification(attacker_name + "'s attack missed!")
			await battle_scene.notify_finished
			return

	if can_dodge_check and final_target.actor_data.can_dodge:
		var dodged : bool = battle_scene.action_calculator.physical_will_dodge(final_target, false)
		if dodged:
			if has_intercept:
				battle_scene.battle_notify_ui.queue_notification(final_name + " intercepts the attack.")
			battle_scene.battle_notify_ui.queue_notification(final_name + " dodges the attack.")
			await battle_scene.notify_finished
			return

	if can_parry_check and final_target.actor_data.can_parry:
		var parried : bool = battle_scene.action_calculator.physical_will_parry(final_target, false)
		if parried:
			if has_intercept:
				battle_scene.battle_notify_ui.queue_notification(final_name + " intercepts the attack.")

			battle_scene.battle_notify_ui.queue_notification(final_name + " parries the attack.")

			var riposte : bool = battle_scene.action_calculator.physical_will_riposte()
			if riposte:
				var riposte_damage_raw = battle_scene.action_calculator.get_riposte_damage(final_target)
				var riposte_damage : int = int(round(riposte_damage_raw))
				riposte_damage = clampi(riposte_damage, 1, 9999)

				var before_hp_attacker : int = attacker.actor_data.current_hp
				attacker.actor_data.current_hp = clampi(
					attacker.actor_data.current_hp - riposte_damage,
					0,
					attacker.actor_data.get_max_hp()
				)
				var applied_riposte : int = before_hp_attacker - attacker.actor_data.current_hp

				var riposte_actions : Array[Callable] = []
				if attacker.ui_element.has_method("play_normal_hit"):
					riposte_actions.append(Callable(attacker.ui_element, "play_normal_hit"))
				if applied_riposte > 0:
					riposte_actions.append(Callable(battle_scene.battle_vfx, "pop_text").bind(attacker, applied_riposte))

				battle_scene.battle_notify_ui.queue_notification(final_name + " ripostes!", riposte_actions)

				if applied_riposte > 0:
					var riposte_ctx : Dictionary = {
						"amount": applied_riposte,
						"is_dot": false,
						"is_poison": false,
						"kind": "physical",
						"effect_context": null
					}
					battle_scene.status_system.on_receive_damage(attacker, final_target, use, riposte_ctx)

				await battle_scene.notify_finished

				if attacker.ui_element is BattleStats:
					var stats_attacker : BattleStats = attacker.ui_element as BattleStats
					await stats_attacker.hp_changed()

				await check_for_death(attacker, final_target)
				return

			await battle_scene.notify_finished
			return

	var raw_damage_val = battle_scene.action_calculator.get_raw_damage(attacker)
	var raw_damage : int = int(round(raw_damage_val))

	var variance_percent_local : int = 10
	var varied_damage : int = battle_scene.action_calculator.vary_damage(raw_damage, variance_percent_local)

	var mitigated_val = battle_scene.action_calculator.get_physical_def_mitigated_damage(varied_damage, final_target)
	var mitigated_damage : int = int(round(mitigated_val))
	mitigated_damage = clampi(mitigated_damage, 1, 9999)

	var final_damage : int = battle_scene.status_system.modify_incoming_physical_damage(
		attacker,
		use.action,
		original_target,
		final_target,
		mitigated_damage
	)

	var before_hp_target : int = final_target.actor_data.current_hp
	final_target.actor_data.current_hp = clampi(
		final_target.actor_data.current_hp - final_damage,
		0,
		final_target.actor_data.get_max_hp()
	)
	var applied_damage : int = before_hp_target - final_target.actor_data.current_hp

	var damage_actions : Array[Callable] = []
	if final_target.ui_element.has_method("play_normal_hit"):
		damage_actions.append(Callable(final_target.ui_element, "play_normal_hit"))
	if applied_damage > 0:
		damage_actions.append(Callable(battle_scene.battle_vfx, "pop_text").bind(final_target, applied_damage))

	if has_intercept:
		battle_scene.battle_notify_ui.queue_notification(final_name + " intercepts the attack.", damage_actions)
	else:
		battle_scene.battle_notify_ui.queue_on_show_actions_for_current(damage_actions)

	if applied_damage > 0:
		var dmg_ctx : Dictionary = {
			"amount": applied_damage,
			"is_dot": false,
			"is_poison": false,
			"kind": "physical",
			"effect_context": null
		}
		battle_scene.status_system.on_receive_damage(final_target, attacker, use, dmg_ctx)

	await battle_scene.notify_finished

	if final_target.ui_element is BattleStats:
		var stats_target : BattleStats = final_target.ui_element as BattleStats
		await stats_target.hp_changed()

	await check_for_death(final_target, attacker)

	
	
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
				

func _execute_defend(use : ActionUse) -> void:
	var defender : Battler = use.user
	var protected : Battler = use.first_target()

	assert(defender != null)
	assert(protected != null)

	var defender_name : String = defender.actor_data.get_display_name()
	var protected_name : String = protected.actor_data.get_display_name()

	var did_link : bool = battle_scene.status_system.set_defend_link(defender, protected)
	if not did_link:
		printerr("ActionResolver: defend failed to set defend link")
		return

	if defender == protected:
		battle_scene.battle_notify_ui.queue_notification(defender_name + " assumes a defensive stance.")
	else:
		battle_scene.battle_notify_ui.queue_notification(defender_name + " moves to defend " + protected_name + ".")

	await battle_scene.notify_finished


	
func _execute_use_skill(use : ActionUse) -> void:
	var user : Battler = use.user

	battle_scene.acting_battler = user
	battle_scene.targeted_battler = use.first_target()

	var skill : Skill = use.data["skill"] as Skill
	var user_name : String = user.actor_data.get_display_name()

	var is_free_cost : bool = false
	if use.data.has("free_cost"):
		is_free_cost = bool(use.data["free_cost"])

	if not is_free_cost:
		if not skill.can_pay_cost(user.actor_data):
			battle_scene.battle_notify_ui.queue_notification(user_name + " cannot use " + skill.name + ".")
			await battle_scene.notify_finished
			return

	var before_user_hp : int = user.actor_data.current_hp
	var before_user_mp : int = user.actor_data.current_sp

	if not is_free_cost:
		skill.pay_cost(user.actor_data)

	var after_cost_user_hp : int = user.actor_data.current_hp

	var ctx := EffectContext.new()
	ctx.mode = EffectContext.Mode.BATTLE
	ctx.user_actor = user.actor_data
	ctx.battle_scene = battle_scene
	ctx.status_system = battle_scene.status_system
	ctx.current_user_battler = user
	ctx.current_action_use = use

	var message : String = skill.message_template
	message = battle_scene.text_parser.parse_skill_message(use, skill)
	battle_scene.battle_notify_ui.queue_notification(message)

	var effects : Array[Effect] = skill.get_effects_for_context(ctx)
	var any_effect_applied : bool = false

	for target in use.targets:
		for effect in effects:
			if effect == null:
				continue
			if effect.apply_to_battler(ctx, target):
				any_effect_applied = true

	var user_damage_taken : int = after_cost_user_hp - user.actor_data.current_hp

	var already_popped_user_damage : int = 0
	if use.data.has("popped_user_damage"):
		already_popped_user_damage = int(use.data["popped_user_damage"])

	var popup_user_damage : int = user_damage_taken - already_popped_user_damage
	if popup_user_damage < 0:
		popup_user_damage = 0

	if popup_user_damage > 0:
		battle_scene.battle_vfx.pop_text(user, popup_user_damage)

	var had_effect_feedback : bool = false
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

	if not had_effect_feedback:
		if use.data.has("had_effect_feedback"):
			if bool(use.data["had_effect_feedback"]):
				had_effect_feedback = true

	if effects.size() > 0 and not any_effect_applied and not had_effect_feedback:
		battle_scene.battle_notify_ui.queue_notification("It has no effect.")

	await battle_scene.notify_finished

	if user.ui_element is BattleStats:
		var stats_user : BattleStats = user.ui_element as BattleStats
		if user.actor_data.current_hp != before_user_hp:
			await stats_user.hp_changed()
		if user.actor_data.current_sp != before_user_mp:
			await stats_user.mp_changed()

	for target in use.targets:
		if target.ui_element is BattleStats:
			var stats_target : BattleStats = target.ui_element as BattleStats
			await stats_target.hp_changed()
			await stats_target.mp_changed()

		if target.actor_data.current_hp <= 0:
			await check_for_death(target, user)

	if user.actor_data.current_hp <= 0 and not use.targets.has(user):
		var from_battler : Battler = battle_scene.targeted_battler
		if from_battler == null:
			from_battler = user
		await check_for_death(user, from_battler)


func _execute_use_item(use : ActionUse) -> void:
	var user : Battler = use.user
	assert(user != null)

	if not use.data.has("item_slot"):
		printerr("ActionResolver: USE_ITEM missing item_slot in use.data")
		return

	var slot : InventorySlot = use.data["item_slot"] as InventorySlot
	if slot == null or slot.item == null:
		printerr("ActionResolver: USE_ITEM slot or item is null")
		return

	var item : Item = slot.item
	var user_name : String = user.actor_data.get_display_name()

	var ctx := EffectContext.new()
	ctx.mode = EffectContext.Mode.BATTLE
	ctx.user_actor = user.actor_data
	ctx.battle_scene = battle_scene
	ctx.status_system = battle_scene.status_system
	ctx.source_item = item
	ctx.current_user_battler = user
	ctx.current_action_use = use

	var message : String = item.message_template
	message = battle_scene.text_parser.parse_item_message(use, item)
	battle_scene.battle_notify_ui.queue_notification(message)

	var effects : Array[Effect] = item.get_effects_for_context(ctx)

	var any_effect_applied : bool = false
	for target in use.targets:
		for effect in effects:
			if effect == null:
				continue
			if effect.apply_to_battler(ctx, target):
				any_effect_applied = true

	var had_effect_feedback : bool = false
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

			parsed = battle_scene.text_parser.parse_custom_message(template, use.user, parse_targets, null, item)
			battle_scene.battle_notify_ui.queue_notification(parsed)

	if effects.size() > 0 and not any_effect_applied:
		if not had_effect_feedback:
			battle_scene.battle_notify_ui.queue_notification("It has no effect.")
		await battle_scene.notify_finished
		return

	if item.consume_on_use:
		slot.quantity -= 1
		if slot.quantity <= 0:
			Inventory.current_inventory.erase(slot)

	await battle_scene.notify_finished

	for target in use.targets:
		if target.ui_element is BattleStats:
			var stats_target : BattleStats = target.ui_element as BattleStats
			await stats_target.hp_changed()
			await stats_target.mp_changed()

		if target.actor_data.current_hp <= 0:
			await check_for_death(target, user)



#endregion Action Execution
