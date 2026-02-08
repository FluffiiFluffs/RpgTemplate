class_name EffectApplyVeryWeakPoison
extends Effect

func _init() -> void:
	scope = Scope.BATTLE_ONLY


func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false
	if target.current_hp <= 0:
		return false
	if ctx.mode != EffectContext.Mode.BATTLE:
		return false
	if ctx.status_system == null:
		return false
	if ctx.current_target_battler == null:
		return false
	return true


func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	var new_poison : StatusVeryWeakPoison = StatusVeryWeakPoison.new()

	var caster_battler : Battler = null
	if ctx.battle_scene != null:
		caster_battler = ctx.battle_scene.acting_battler

	var result : Dictionary = ctx.status_system.try_add_status(ctx.current_target_battler, new_poison, caster_battler)

	if result.has("outcome"):
		if result["outcome"] == StatusSystem.AddStatusOutcome.BLOCKED:
			var target_name : String = "Target"
			if target != null:
				target_name = target.get_display_name()
				if target_name == "":
					target_name = "Target"


			var msg : String = target_name + " already has a stronger poison."

			if result.has("blocked_by") and result["blocked_by"] != null:
				if result["blocked_by"] is StatusEffectPoison:
					var existing : StatusEffectPoison = result["blocked_by"] as StatusEffectPoison
					msg = target_name + " already has " + existing.tier_name + "."

			ctx.queue_battle_message(msg)
			return false

		if result["outcome"] == StatusSystem.AddStatusOutcome.REPLACED:
			var target_name2 : String = "Target"
			if target != null:
				target_name2 = target.get_display_name()
				if target_name2 == "":
					target_name2 = "Target"

			ctx.queue_battle_message(target_name2 + "'s poison intensifies.")
			return true

	return true
