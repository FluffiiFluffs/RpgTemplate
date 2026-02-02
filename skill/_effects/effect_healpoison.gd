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
## - Out of battle, we remove directly from the ActorData list and call on_remove(null).
## - A cure message is queued only when the cure succeeds and only while in battle mode.
func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	## Tracks whether we removed at least one curable poison status.
	var did_remove_poison : bool = false

	## Iterate backward so we can remove entries safely while iterating.
	for i in range(target.status_effects.size() - 1, -1, -1):
		var status_effect : StatusEffect = target.status_effects[i]

		## Defensive cleanup: remove null entries if they exist.
		if status_effect == null:
			target.status_effects.remove_at(i)
			continue

		## Ignore non-poison statuses.
		if not (status_effect is StatusEffectPoison):
			continue

		var poison_effect : StatusEffectPoison = status_effect as StatusEffectPoison

		## Leave stronger poison tiers intact.
		if poison_effect.exclusive_rank > max_curable_rank:
			continue

		## Battle path: remove via StatusSystem for centralized logic and proper battle signals.
		if ctx != null and ctx.mode == EffectContext.Mode.BATTLE and ctx.status_system != null and ctx.current_target_battler != null:
			ctx.status_system.remove_status(ctx.current_target_battler, status_effect)
		else:
			## Field/menu path: remove directly from ActorData.
			## on_remove(null) is used because there is no Battler context in the field.
			status_effect.on_remove(null)
			target.status_effects.remove_at(i)

		did_remove_poison = true

	## Post-removal work
	if did_remove_poison:
		## Battle feedback: queue a tokenized message that goes through TextParser in ActionResolver.
		## ctx.current_target_battler is passed so "{target}" resolves correctly even for multi-target actions.
		if ctx != null and ctx.mode == EffectContext.Mode.BATTLE:
			ctx.queue_battle_message("{target} is no longer poisoned!", ctx.current_target_battler)

		## Field poison tick system uses CharDataKeeper.poison_timer to drive visuals and periodic checks.
		## Restarting it here ensures poison visuals update correctly after a cure (and tick system remains active).
		CharDataKeeper.poison_timer.start()

	return did_remove_poison
