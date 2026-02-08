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
	if battle_scene == null:
		return
	if battle_scene.battle_notify_ui == null:
		return
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
func execute_action_use(use: ActionUse)->void:
	battle_scene.battle_state = "ACTION_EXECUTE"
	battle_scene.ui_state = "NOTIFYING"
	if use == null:
		printerr("ActionResolver: execute_action_use() received a null ActionUse")
		return

	var user : Battler = use.user
	if battle_scene.status_system != null and user != null:
		battle_scene.status_system.on_action_start(user, use)
		await _await_notify_if_needed()

	match use.action_type:
		BattleAction.ActionType.NORMAL_ATTACK:
			await _execute_normal_attack(use)
		BattleAction.ActionType.RUN:
			await _execute_run(use)
		BattleAction.ActionType.DEFEND:
			await _execute_defend(use)
		BattleAction.ActionType.USE_ITEM:
			await _execute_use_item(use)
		BattleAction.ActionType.USE_SKILL:
			await _execute_use_skill(use)
		null:
			printerr("Null action!")
		_:
			printerr("Unknown action type")

	if battle_scene.status_system != null and user != null:
		battle_scene.status_system.on_action_end(user, use)
		await _await_notify_if_needed()

func _execute_normal_attack(use : ActionUse)->void:
	var attacker = use.user
	var original_target = use.first_target()
	if attacker == null or original_target == null:
		printerr("ActionResolver: normal attack missing attacker or target")
		return

	var attacker_name = attacker.actor_data.get_display_name()
	var original_name = original_target.actor_data.get_display_name()

	var final_target : Battler = battle_scene.status_system.resolve_incoming_target(attacker, use.action, original_target)
	var final_name = final_target.actor_data.get_display_name()

	battle_scene.battle_notify_ui.queue_notification(attacker_name + " attacks " + original_name + ".")
	if final_target != original_target:
		battle_scene.battle_notify_ui.queue_notification(final_name + " intercepts the attack.")

	var force_hit : bool = false
	if battle_scene.status_system != null:
		force_hit = battle_scene.status_system.should_force_physical_hit(final_target)


	var dmg = battle_scene.action_calculator.normal_attack(attacker, use.action, final_target, force_hit)

	if dmg == -1:
		battle_scene.battle_notify_ui.queue_notification(attacker_name + "'s attack missed!")
		await battle_scene.notify_finished
		return

	dmg = battle_scene.status_system.modify_incoming_physical_damage(attacker, use.action, original_target, final_target, dmg)

	final_target.actor_data.current_hp = clampi(final_target.actor_data.current_hp - dmg, 0, final_target.actor_data.get_max_hp())

	if final_target.ui_element != null and final_target.ui_element.has_method("play_normal_hit"):
		final_target.ui_element.play_normal_hit()


	battle_scene.battle_vfx.pop_text(final_target, dmg)
	if dmg > 0 and battle_scene.status_system != null:
		var dmg_ctx : Dictionary = {
			"amount": dmg,
			"is_dot": false,
			"is_poison": false,
			"kind": "physical",
			"effect_context": null
		}
		battle_scene.status_system.on_receive_damage(final_target, attacker, use, dmg_ctx)



	await battle_scene.notify_finished

	if final_target.ui_element is BattleStats:
		var stats = final_target.ui_element as BattleStats
		await stats.hp_changed()
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
	if defender == null or protected == null:
		printerr("ActionResolver: defend missing defender or target")
		return

	var defender_name : String = defender.actor_data.get_display_name()
	var protected_name : String = protected.actor_data.get_display_name()

	var did_link : bool = false
	if battle_scene.status_system != null:
		did_link = battle_scene.status_system.set_defend_link(defender, protected)

	if not did_link:
		printerr("ActionResolver: defend failed to set defend link")
		return



	if defender == protected:
		battle_scene.battle_notify_ui.queue_notification(defender_name + " assumes a defensive stance.")
	else:
		battle_scene.battle_notify_ui.queue_notification(defender_name + " moves to defend " + protected_name + ".")

	await battle_scene.notify_finished
func _execute_use_skill(use : ActionUse) -> void:
	var user = use.user
	if user == null:
		return

	if not use.data.has("skill"):
		printerr("ActionResolver: USE_SKILL missing skill in use.data")
		return

	var skill = use.data["skill"] as Skill
	if skill == null:
		printerr("ActionResolver: USE_SKILL skill is null")
		return

	var user_name = user.actor_data.get_display_name()

	var is_free_cost : bool = false
	if use.data != null and use.data.has("free_cost"):
		is_free_cost = bool(use.data["free_cost"])

	if not is_free_cost:
		if not skill.can_pay_cost(user.actor_data):
			battle_scene.battle_notify_ui.queue_notification(user_name + " cannot use " + skill.name + ".")
			await battle_scene.notify_finished
			return

	var before_user_hp : int = user.actor_data.current_hp
	var before_user_mp : int = user.actor_data.current_sp

	if not is_free_cost:
		# Pay cost up front
		skill.pay_cost(user.actor_data)


	var ctx = EffectContext.new()
	ctx.mode = EffectContext.Mode.BATTLE
	ctx.user_actor = user.actor_data
	ctx.battle_scene = battle_scene
	ctx.status_system = battle_scene.status_system
	ctx.current_user_battler = user
	ctx.current_action_use = use


	var message : String = skill.message_template
	if battle_scene.text_parser != null:
		message = battle_scene.text_parser.parse_skill_message(use, skill)
	else:
		message = message.replace("{user}", user_name)
		message = message.replace("{skill}", skill.name)
	battle_scene.battle_notify_ui.queue_notification(message)

	var effects = skill.get_effects_for_context(ctx)
	var any_effect_applied = false

	for target in use.targets:
		if target == null:
			continue
		for effect in effects:
			if effect == null:
				continue
			if effect.apply_to_battler(ctx, target):
				any_effect_applied = true

	var had_effect_feedback : bool = false
	if ctx.queued_battle_messages != null and ctx.queued_battle_messages.size() > 0:
		had_effect_feedback = true

		for i in range(ctx.queued_battle_messages.size()):
			var template : String = ctx.queued_battle_messages[i]
			var parsed : String = template

			if battle_scene.text_parser != null:
				var parse_targets : Array[Battler] = use.targets

				if ctx.queued_battle_message_targets != null and i < ctx.queued_battle_message_targets.size():
					var override_target : Battler = ctx.queued_battle_message_targets[i]
					if override_target != null:
						parse_targets = [override_target]

				parsed = battle_scene.text_parser.parse_custom_message(template, use.user, parse_targets, skill, null)

			battle_scene.battle_notify_ui.queue_notification(parsed)

	if effects.size() > 0 and not any_effect_applied and not had_effect_feedback:
		battle_scene.battle_notify_ui.queue_notification("It has no effect.")

	await battle_scene.notify_finished

	# Update user UI if cost changed
	if user.ui_element is BattleStats:
		var stats_user = user.ui_element as BattleStats
		if user.actor_data.current_hp != before_user_hp:
			await stats_user.hp_changed()
		if user.actor_data.current_sp != before_user_mp:
			await stats_user.mp_changed()

	# Update target UIs and check deaths
	for target in use.targets:
		if target == null:
			continue
		if target.ui_element is BattleStats:
			var stats_target = target.ui_element as BattleStats
			await stats_target.hp_changed()
			await stats_target.mp_changed()

		if target.actor_data.current_hp <= 0:
			await check_for_death(target, user)



func _execute_use_item(use : ActionUse) -> void:
	var user = use.user
	if user == null:
		return

	if not use.data.has("item_slot"):
		printerr("ActionResolver: USE_ITEM missing item_slot in use.data")
		return

	var slot = use.data["item_slot"] as InventorySlot
	if slot == null or slot.item == null:
		printerr("ActionResolver: USE_ITEM slot or item is null")
		return

	var item = slot.item
	var user_name = user.actor_data.get_display_name()

	var ctx = EffectContext.new()
	ctx.mode = EffectContext.Mode.BATTLE
	ctx.user_actor = user.actor_data
	ctx.battle_scene = battle_scene
	ctx.status_system = battle_scene.status_system
	ctx.source_item = item
	ctx.current_user_battler = user
	ctx.current_action_use = use


	var message : String = item.message_template
	if battle_scene.text_parser != null:
		message = battle_scene.text_parser.parse_item_message(use, item)
	else:
		message = message.replace("{user}", user_name)
		message = message.replace("{item}", item.name)
	battle_scene.battle_notify_ui.queue_notification(message)

	var effects : Array[Effect] = item.get_effects_for_context(ctx)

	var any_effect_applied = false
	for target in use.targets:
		if target == null:
			continue
		for effect in effects:
			if effect == null:
				continue
			if effect.apply_to_battler(ctx, target):
				any_effect_applied = true

	var had_effect_feedback : bool = false
	if ctx.queued_battle_messages != null and ctx.queued_battle_messages.size() > 0:
		had_effect_feedback = true

		for i in range(ctx.queued_battle_messages.size()):
			var template : String = ctx.queued_battle_messages[i]
			var parsed : String = template

			if battle_scene.text_parser != null:
				var parse_targets : Array[Battler] = use.targets

				if ctx.queued_battle_message_targets != null and i < ctx.queued_battle_message_targets.size():
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

	# Consume item only when something applied
	if item.consume_on_use:
		slot.quantity -= 1
		if slot.quantity <= 0:
			Inventory.current_inventory.erase(slot)

	await battle_scene.notify_finished

	# Update target UIs and check deaths
	for target in use.targets:
		if target == null:
			continue

		if target.ui_element is BattleStats:
			var stats_target = target.ui_element as BattleStats
			await stats_target.hp_changed()
			await stats_target.mp_changed()

		if target.actor_data.current_hp <= 0:
			await check_for_death(target, user)






#endregion Action Execution
