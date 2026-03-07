class_name EffectHealHP
extends Effect

@export var hp_heal_amount : int = 0


func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false

	if target.current_hp <= 0:
		return false

	if target.current_hp >= target.get_max_hp():
		return false

	return true
func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	var final_heal : int = hp_heal_amount

	if ctx != null:
		var source_skill : Skill = ctx.get_source_skill()
		if source_skill != null and ctx.user_actor != null:
			final_heal = source_skill.get_power_scaled_amount(ctx.user_actor, hp_heal_amount)

	if final_heal <= 0:
		return false

	var before_hp : int = target.current_hp

	target.current_hp = target.current_hp + final_heal
	target.clamp_vitals()

	var applied_heal : int = target.current_hp - before_hp

	if ctx.mode == EffectContext.Mode.BATTLE:
		if ctx.battle_scene != null and ctx.current_target_battler != null:
			if applied_heal > 0:
				ctx.battle_scene.battle_vfx.pop_text_healing(ctx.current_target_battler, applied_heal)

	return applied_heal != 0
	
	
	
	##
