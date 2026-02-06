class_name EffectHealPoison
extends Effect

@export_category("Poison Cure")
## Max poison "exclusive_rank" this effect is allowed to cure.
## Example tiering: 10, 20, 30, 40, 50
## If max_curable_rank = 40, this cures poison tiers up through rank 40 and leaves rank 50 intact.
@export var max_curable_rank : int = 40


## Returns true when:
## 1) The base Effect rules allow application, and
## 2) The target is alive, and
## 3) The target has at least one curable poison StatusEffect (exclusive_rank <= max_curable_rank).
func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false

	## Do not attempt to cure statuses on dead targets.
	## This keeps behavior consistent with other effects and avoids edge cases around KO state handling.
	if target.current_hp <= 0:
		return false

	## Defensive: status_effects should exist for party/enemy ActorData, but we treat null as no statuses.
	if target.status_effects == null:
		return false

	## Scan status list for any poison effect that is within the curable rank threshold.
	for status_effect in target.status_effects:
		if status_effect == null:
			continue

		if status_effect is StatusEffectPoison:
			var poison_effect : StatusEffectPoison = status_effect as StatusEffectPoison
			if poison_effect.exclusive_rank <= max_curable_rank:
				return true

	## No curable poison present.
	return false


## Removes poison StatusEffects from target that satisfy exclusive_rank <= max_curable_rank.
##
## Behavior notes:
## - In battle, removal is routed through StatusSystem.remove_status(...) so battle side-effects and signals fire.
## - A cure message is queued only when the cure succeeds and only while in battle mode.
func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	var did_remove_poison : bool = false

	var ss : StatusSystem = null
	var target_battler : Battler = null

	if ctx != null and ctx.mode == EffectContext.Mode.BATTLE:
		if ctx.status_system == null:
			return false
		if ctx.current_target_battler == null:
			return false
		ss = ctx.status_system
		target_battler = ctx.current_target_battler
	else:
		ss = CharDataKeeper.field_status_system
		if ss == null:
			return false
		target_battler = Battler.new()
		target_battler.actor_data = target

	for i in range(target.status_effects.size() - 1, -1, -1):
		var status_effect : StatusEffect = target.status_effects[i]
		if status_effect == null:
			continue
		if not (status_effect is StatusEffectPoison):
			continue

		var poison_effect : StatusEffectPoison = status_effect as StatusEffectPoison
		if poison_effect.exclusive_rank > max_curable_rank:
			continue

		ss.remove_status(target_battler, status_effect)
		did_remove_poison = true

	if did_remove_poison:
		if ctx != null and ctx.mode == EffectContext.Mode.BATTLE:
			ctx.queue_battle_message("{target} is no longer poisoned!", ctx.current_target_battler)
		CharDataKeeper.poison_timer.start()

	return did_remove_poison
