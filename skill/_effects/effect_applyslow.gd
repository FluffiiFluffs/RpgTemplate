class_name EffectApplySlow
extends Effect

@export_category("Slow")
## When 0, this effect increments the current Slow stack by 1.
## When 1 to 3, this effect sets Slow directly to that stack level.
## This supports a skill that applies 3 stack Slow immediately.
@export_range(0, 3, 1) var set_to_stack_level : int = 0


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

	var target_battler : Battler = ctx.current_target_battler
	var status_system : StatusSystem = ctx.status_system

	# Slow overwrites Haste.
	var existing_haste : StatusEffect = StatusSystem.find_status(target_battler, StatusEffectHaste)
	if existing_haste != null:
		status_system.remove_status(target_battler, existing_haste)


	var existing_slow : StatusEffectSlow = null
	var existing_raw : StatusEffect = StatusSystem.find_status(target_battler, StatusEffectSlow)
	if existing_raw is StatusEffectSlow:
		existing_slow = existing_raw as StatusEffectSlow

	var current_level : int = 0
	if existing_slow != null:
		current_level = existing_slow.stack_level

	var desired_level : int = 0
	if set_to_stack_level > 0:
		desired_level = clampi(set_to_stack_level, 1, 3)
	else:
		desired_level = current_level + 1

	if desired_level > 3:
		ctx.queue_battle_message("{target} is as slow as they can get!", target_battler)
		return false

	if desired_level <= current_level:
		if current_level >= 3:
			ctx.queue_battle_message("{target} is as slow as they can get!", target_battler)
		return false

	var caster_battler : Battler = null
	if ctx.battle_scene != null:
		caster_battler = ctx.battle_scene.acting_battler

	var new_slow : StatusEffectSlow = StatusEffectSlow.new()
	new_slow.configure(desired_level)

	var result : Dictionary = status_system.try_add_status(target_battler, new_slow, caster_battler)
	if result.has("outcome"):
		if result["outcome"] == StatusSystem.AddStatusOutcome.BLOCKED:
			ctx.queue_battle_message("{target} cannot be slowed.", target_battler)
			return false

	if desired_level == 1:
		ctx.queue_battle_message("{target} is slowed!", target_battler)
	elif desired_level == 2:
		ctx.queue_battle_message("{target} is slowed further!", target_battler)
	else:
		ctx.queue_battle_message("{target} is slowed to a crawl!", target_battler)

	return true


func _has_status_in_group(receiver : Battler, group_id : StringName) -> bool:
	if receiver == null:
		return false
	if receiver.actor_data == null:
		return false
	if receiver.actor_data.status_effects == null:
		return false

	for s in receiver.actor_data.status_effects:
		if s == null:
			continue
		if s.exclusive_group_id == group_id:
			return true

	return false
