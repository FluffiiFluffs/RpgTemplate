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

	var before_hp = target.current_hp
	target.current_hp = target.current_hp - hp_damage_amount
	target.clamp_vitals()
	return target.current_hp != before_hp
