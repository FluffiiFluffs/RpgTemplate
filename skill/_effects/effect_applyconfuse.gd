class_name EffectApplyConfuse
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

	var caster_battler : Battler = null
	if ctx.battle_scene != null:
		caster_battler = ctx.battle_scene.acting_battler

	var new_confuse : StatusEffectConfuse = StatusEffectConfuse.new()
	var result : Dictionary = ctx.status_system.try_add_status(ctx.current_target_battler, new_confuse, caster_battler)

	if result.has("outcome"):
		if result["outcome"] == StatusSystem.AddStatusOutcome.BLOCKED:
			if result.has("blocked_by") and result["blocked_by"] is StatusEffectConfuse:
				ctx.queue_battle_message("{target} is already confused.", ctx.current_target_battler)
			else:
				ctx.queue_battle_message("{target} cannot be confused.", ctx.current_target_battler)
			return false

	ctx.queue_battle_message("{target} becomes confused!", ctx.current_target_battler)
	return true
