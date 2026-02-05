class_name EffectApplyHaste
extends Effect

@export_category("Haste")
## When 0, this effect increments the current Haste stack by 1.
## When 1 to 3, this effect sets Haste directly to that stack level.
## This supports a skill that applies 3 stack Haste immediately.
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

	# Haste overwrites Slow (Slow removes Haste when Slow is applied, and Haste removes Slow here).
	var existing_slow : StatusEffect = StatusSystem.find_status(target_battler, StatusEffectSlow)
	if existing_slow != null:
		status_system.remove_status(target_battler, existing_slow)

	var existing_haste : StatusEffectHaste = null
	var existing_raw : StatusEffect = StatusSystem.find_status(target_battler, StatusEffectHaste)
	if existing_raw is StatusEffectHaste:
		existing_haste = existing_raw as StatusEffectHaste

	var current_level : int = 0
	if existing_haste != null:
		current_level = existing_haste.stack_level

	var desired_level : int = 0
	if set_to_stack_level > 0:
		desired_level = clampi(set_to_stack_level, 1, 3)
	else:
		desired_level = current_level + 1

	if desired_level > 3:
		ctx.queue_battle_message("{target} are as fast as they can get!", target_battler)
		return false

	if desired_level <= current_level:
		if current_level >= 3:
			ctx.queue_battle_message("{target} are as fast as they can get!", target_battler)
		return false

	var caster_battler : Battler = null
	if ctx.battle_scene != null:
		caster_battler = ctx.battle_scene.acting_battler

	var new_haste : StatusEffectHaste = StatusEffectHaste.new()
	new_haste.configure(desired_level)

	var result : Dictionary = status_system.try_add_status(target_battler, new_haste, caster_battler)
	if result.has("outcome"):
		if result["outcome"] == StatusSystem.AddStatusOutcome.BLOCKED:
			ctx.queue_battle_message("{target} cannot be hasted.", target_battler)
			return false

	if desired_level == 1:
		ctx.queue_battle_message("{target} is hasted!", target_battler)
	elif desired_level == 2:
		ctx.queue_battle_message("{target} is hasted further!", target_battler)
	else:
		ctx.queue_battle_message("{target} is hasted to the limit!", target_battler)

	return true
