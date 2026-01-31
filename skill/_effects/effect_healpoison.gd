class_name EffectHealPoison
extends Effect

@export_category("Poison Cure")
## Default supports “uniform cure except highest tier”
## With ranks 10, 20, 30, 40, 50 this cures through Strong Poison.
@export var max_curable_rank : int = 40

func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false
	if target.current_hp <= 0:
		return false
	if target.status_effects == null:
		return false

	for s in target.status_effects:
		if s == null:
			continue
		if s is StatusEffectPoison:
			var p : StatusEffectPoison = s as StatusEffectPoison
			if p.exclusive_rank <= max_curable_rank:
				return true

	return false


func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	var changed : bool = false

	for i in range(target.status_effects.size() - 1, -1, -1):
		var s : StatusEffect = target.status_effects[i]
		if s == null:
			target.status_effects.remove_at(i)
			continue

		if not (s is StatusEffectPoison):
			continue

		var p : StatusEffectPoison = s as StatusEffectPoison
		if p.exclusive_rank > max_curable_rank:
			continue

		if ctx != null and ctx.mode == EffectContext.Mode.BATTLE and ctx.status_system != null and ctx.current_target_battler != null:
			ctx.status_system.remove_status(ctx.current_target_battler, s)
		else:
			s.on_remove(null)
			target.status_effects.remove_at(i)

		changed = true

	return changed
