class_name EffectDamageHP
extends Effect

@export var hp_damage_amount : int = 0

func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false

	if hp_damage_amount <= 0:
		return false

	if target.current_hp <= 0:
		return false

	return true

func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	var before_hp : int = target.current_hp

	target.current_hp = target.current_hp - hp_damage_amount
	target.clamp_vitals()

	var applied_dmg : int = before_hp - target.current_hp

	if ctx.mode == EffectContext.Mode.BATTLE:
		if ctx.battle_scene != null and ctx.current_target_battler != null:
			if applied_dmg > 0:
				ctx.battle_scene.battle_vfx.pop_text(ctx.current_target_battler, applied_dmg)

	if ctx.mode == EffectContext.Mode.BATTLE:
		if applied_dmg > 0 and ctx.status_system != null and ctx.current_target_battler != null:
			var attacker_battler : Battler = null
			var action_use : ActionUse = null

			if ctx.current_user_battler != null:
				attacker_battler = ctx.current_user_battler
			if ctx.current_action_use != null:
				action_use = ctx.current_action_use

			var dmg_ctx : Dictionary = {
				"amount": applied_dmg,
				"is_dot": false,
				"is_poison": false,
				"kind": "hp_damage",
				"effect_context": ctx
			}

			ctx.status_system.on_receive_damage(ctx.current_target_battler, attacker_battler, action_use, dmg_ctx)

	return applied_dmg != 0
