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

	var before_hp : int = target.current_hp

	target.current_hp = target.current_hp + hp_heal_amount
	target.clamp_vitals()

	var applied_heal : int = target.current_hp - before_hp

	if ctx.mode == EffectContext.Mode.BATTLE:
		if ctx.battle_scene != null and ctx.current_target_battler != null:
			if applied_heal > 0:
				ctx.battle_scene.battle_vfx.pop_text_healing(ctx.current_target_battler, applied_heal)

	return applied_heal != 0
	
	
	
	##
