class_name EffectNormalAttack
extends Effect

@export var cannot_miss : bool = false
@export var cannot_dodge : bool = false
@export var cannot_parry : bool = false
@export var cannot_riposte : bool = false

@export var variance_percent : int = 10
@export var allow_crit : bool = true


func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false

	# This effect is battle execution only.
	# current_action_use is not populated during targeting filters.
	if ctx.mode != EffectContext.Mode.BATTLE:
		return false

	return true


func _mark_effect_feedback(ctx : EffectContext) -> void:
	ctx.had_effect_feedback = true


func _queue_note(ctx : EffectContext, text : String) -> void:
	if text == "":
		return

	ctx.battle_scene.battle_notify_ui.queue_notification(text)
	_mark_effect_feedback(ctx)
	
	
	
func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	ctx.require_battle_context()

	var battle_scene : BattleScene = ctx.battle_scene
	var calc : ActionCalculator = battle_scene.action_calculator

	var use : ActionUse = ctx.current_action_use
	var attacker : Battler = ctx.current_user_battler
	var original_target : Battler = ctx.current_target_battler

	var final_target : Battler = original_target
	var redirected : Battler = ctx.status_system.resolve_incoming_target(attacker, use.action, original_target)
	if redirected != null:
		final_target = redirected

	if final_target != original_target:
		var idx : int = use.targets.find(original_target)
		if idx != -1:
			use.targets[idx] = final_target

	var has_intercept : bool = final_target != original_target
	var intercept_text : String = ""
	if has_intercept:
		intercept_text = final_target.actor_data.get_display_name() + " intercepts the attack."

	var skill : Skill = use.skill
	assert(skill != null)

	var can_miss_local : bool = skill.can_miss
	var can_dodge_local : bool = skill.can_dodge
	var can_parry_local : bool = skill.can_parry

	var final_variance_percent : int = int(round(skill.variance_percent))
	final_variance_percent = clampi(final_variance_percent, 0, 100)

	var force_hit : bool = ctx.status_system.should_force_physical_hit(final_target)

	var cannot_miss_local : bool = force_hit or not can_miss_local
	var cannot_dodge_local : bool = force_hit or not can_dodge_local
	var cannot_parry_local : bool = force_hit or not can_parry_local

	if not final_target.actor_data.can_dodge:
		cannot_dodge_local = true
	if not final_target.actor_data.can_parry:
		cannot_parry_local = true

	# Miss
	var miss : bool = calc.physical_will_miss(attacker, final_target, cannot_miss_local)
	if miss:
		if has_intercept:
			battle_scene.battle_notify_ui.queue_notification(intercept_text)

		var miss_actions : Array[Callable] = [
			Callable(battle_scene.battle_vfx, "pop_text_only").bind(final_target, "MISS!")
		]

		var attacker_name : String = attacker.actor_data.get_display_name()
		battle_scene.battle_notify_ui.queue_notification(attacker_name + "'s attack missed!", miss_actions)

		_mark_effect_feedback(ctx)
		return true


	# Crit (after miss, precludes dodge parry riposte)
	var crit : bool = false
	if allow_crit:
		crit = calc.physical_will_crit(attacker, final_target)

	if crit:
		var raw_damage_crit : int = calc.get_raw_damage(attacker)
		var varied_damage_crit : int = calc.vary_damage(raw_damage_crit, final_variance_percent)
		var crit_damage : int = int(round(calc.get_crit_damage(attacker, varied_damage_crit)))
		crit_damage = clampi(crit_damage, 1, 9999)

		# Crit ignores defense mitigation and precludes dodge, parry, and riposte.
		var final_damage_crit : int = crit_damage
		final_damage_crit = clampi(final_damage_crit, 1, 9999)

		var before_hp_target_crit : int = final_target.actor_data.current_hp
		final_target.actor_data.current_hp = final_target.actor_data.current_hp - final_damage_crit
		final_target.actor_data.clamp_vitals()

		var applied_damage_crit : int = before_hp_target_crit - final_target.actor_data.current_hp
		if applied_damage_crit > 0:
			var crit_actions : Array[Callable] = []
			if final_target.ui_element.has_method("play_normal_hit"):
				crit_actions.append(Callable(final_target.ui_element, "play_normal_hit"))
			crit_actions.append(Callable(battle_scene.battle_vfx, "pop_text_critical").bind(final_target, applied_damage_crit))

			if has_intercept:
				battle_scene.battle_notify_ui.queue_notification(intercept_text)

			var attacker_name_crit : String = attacker.actor_data.get_display_name()
			var target_name_crit : String = final_target.actor_data.get_display_name()
			battle_scene.battle_notify_ui.queue_notification(attacker_name_crit + " critically strikes " + target_name_crit + ".", crit_actions)

			var dmg_ctx_crit : Dictionary = {
				"amount": applied_damage_crit,
				"is_dot": false,
				"is_poison": false,
				"kind": "physical",
				"effect_context": ctx
			}
			ctx.status_system.on_receive_damage(final_target, attacker, use, dmg_ctx_crit)

			_mark_effect_feedback(ctx)
			return true

		_mark_effect_feedback(ctx)
		return true
	# Dodge
	var dodge : bool = calc.physical_will_dodge(final_target, cannot_dodge_local)
	if dodge:
		if has_intercept:
			battle_scene.battle_notify_ui.queue_notification(intercept_text)

		var dodge_actions : Array[Callable] = [
			Callable(battle_scene.battle_vfx, "pop_text_only").bind(final_target, "DODGE!")
		]

		var dodge_name : String = final_target.actor_data.get_display_name()
		battle_scene.battle_notify_ui.queue_notification(dodge_name + " dodges the attack.", dodge_actions)

		_mark_effect_feedback(ctx)
		return true


	# Parry and riposte
	var parry : bool = calc.physical_will_parry(final_target, cannot_parry_local)
	if parry:
		if has_intercept:
			battle_scene.battle_notify_ui.queue_notification(intercept_text)

		var parry_actions : Array[Callable] = [
			Callable(battle_scene.battle_vfx, "pop_text_only").bind(final_target, "PARRY!")
		]

		var parry_name : String = final_target.actor_data.get_display_name()
		battle_scene.battle_notify_ui.queue_notification(parry_name + " parries the attack.", parry_actions)


		var riposte : bool = calc.physical_will_riposte()
		if riposte:
			var riposte_damage : int = int(round(calc.get_riposte_damage(final_target)))
			riposte_damage = clampi(riposte_damage, 1, 9999)

			var before_hp_attacker : int = attacker.actor_data.current_hp
			attacker.actor_data.current_hp = attacker.actor_data.current_hp - riposte_damage
			attacker.actor_data.clamp_vitals()

			var applied_riposte : int = before_hp_attacker - attacker.actor_data.current_hp

			if applied_riposte > 0:
				var prev_popped : int = 0
				if use.data.has("popped_user_damage"):
					prev_popped = int(use.data["popped_user_damage"])
				use.data["popped_user_damage"] = prev_popped + applied_riposte

			var riposte_actions : Array[Callable] = []
			if final_target.ui_element.has_method("play_normal_attack"):
				riposte_actions.append(Callable(final_target.ui_element, "play_normal_attack"))
			if attacker.ui_element.has_method("play_normal_hit"):
				riposte_actions.append(Callable(attacker.ui_element, "play_normal_hit"))
			if applied_riposte > 0:
				riposte_actions.append(Callable(battle_scene.battle_vfx, "pop_text_riposte").bind(attacker, applied_riposte))

			var riposte_name : String = final_target.actor_data.get_display_name()
			battle_scene.battle_notify_ui.queue_notification(riposte_name + " ripostes!", riposte_actions)

			if applied_riposte > 0:
				var dmg_ctx_r : Dictionary = {
					"amount": applied_riposte,
					"is_dot": false,
					"is_poison": false,
					"kind": "physical",
					"effect_context": ctx
				}
				ctx.status_system.on_receive_damage(attacker, final_target, use, dmg_ctx_r)

			_mark_effect_feedback(ctx)
			return true

		_mark_effect_feedback(ctx)
		return true

	# Damage pipeline
	var raw_damage : int = calc.get_raw_damage(attacker)
	var varied_damage : int = calc.vary_damage(raw_damage, final_variance_percent)
	var mitigated_damage : int = calc.get_physical_def_mitigated_damage(varied_damage, final_target)

	var final_damage : int = mitigated_damage
	final_damage = ctx.status_system.modify_incoming_physical_damage(
		attacker,
		use.action,
		original_target,
		final_target,
		final_damage
	)

	final_damage = clampi(final_damage, 1, 9999)

	var before_hp_target : int = final_target.actor_data.current_hp
	final_target.actor_data.current_hp = final_target.actor_data.current_hp - final_damage
	final_target.actor_data.clamp_vitals()

	var applied_damage : int = before_hp_target - final_target.actor_data.current_hp
	if applied_damage > 0:
		var damage_actions : Array[Callable] = []
		if final_target.ui_element.has_method("play_normal_hit"):
			damage_actions.append(Callable(final_target.ui_element, "play_normal_hit"))
		damage_actions.append(Callable(battle_scene.battle_vfx, "pop_text").bind(final_target, applied_damage))

		if has_intercept:
			battle_scene.battle_notify_ui.queue_notification(intercept_text, damage_actions)
		else:
			battle_scene.battle_notify_ui.queue_on_show_actions_for_current(damage_actions)

		var dmg_ctx : Dictionary = {
			"amount": applied_damage,
			"is_dot": false,
			"is_poison": false,
			"kind": "physical",
			"effect_context": ctx
		}
		ctx.status_system.on_receive_damage(final_target, attacker, use, dmg_ctx)

		_mark_effect_feedback(ctx)
		return true

	return false
