class_name EffectHealSP
extends Effect

@export var sp_heal_amount : int = 0


func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false

	## Dead check should be HP based.
	if target.current_hp <= 0:
		return false

	if target.current_sp >= target.get_max_sp():
		return false

	return true


func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	var before_sp = target.current_sp
	target.current_mp = target.current_sp + sp_heal_amount
	target.clamp_vitals()
	return target.current_sp != before_sp
