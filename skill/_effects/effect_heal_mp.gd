class_name EffectHealMP
extends Effect

@export var mp_heal_amount : int = 0


func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false

	## Dead check should be HP based.
	if target.current_hp <= 0:
		return false

	if target.current_mp >= target.get_max_mp():
		return false

	return true


func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	var before_mp = target.current_mp
	target.current_mp = target.current_mp + mp_heal_amount
	target.clamp_vitals()
	return target.current_mp != before_mp
