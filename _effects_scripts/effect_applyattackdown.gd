class_name EffectAttackDown
extends Effect

@export_category("Attack Down")
## Strength of this cast.
## 1 adds 1 stack, 2 adds 2 stacks, 3 adds 3 stacks.
## If Attack Up is present, this removes that many stacks instead and stops at 0.
@export_range(1, 3, 1) var stack_levels_to_add : int = 1

## Duration in target turns. 0 means entire battle.
@export_range(0, 99, 1) var duration_turns : int = 6


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
	var strength : int = clampi(stack_levels_to_add, 1, 3)

	# Tug of war: reduce Attack Up first.
	# If this cast fully removes Attack Up and still has remaining strength,
	# apply the remainder as Attack Down (crossing 0).
	var raw_up : StatusEffect = StatusSystem.find_status(target_battler, StatusEffectAttackUp)
	var existing_up : StatusEffectAttackUp = null
	if raw_up is StatusEffectAttackUp:
		existing_up = raw_up as StatusEffectAttackUp

	if existing_up != null:
		var up_level : int = clampi(existing_up.stack_level, 1, 3)

		if strength < up_level:
			existing_up.set_stack_level(up_level - strength)
			ctx.queue_battle_message("{target}'s attack up weakens.", target_battler)
			return true

		if strength == up_level:
			status_system.remove_status(target_battler, existing_up)
			ctx.queue_battle_message("{target}'s attack returns to normal.", target_battler)
			return true

		# strength > up_level, remove up and carry remainder into Attack Down.
		status_system.remove_status(target_battler, existing_up)
		strength = strength - up_level
		# continue into Attack Down application using the remainder

	# No Attack Up (or remainder exists): add stacks to Attack Down (cap at 3).
	var raw_down : StatusEffect = StatusSystem.find_status(target_battler, StatusEffectAttackDown)
	var existing_down : StatusEffectAttackDown = null
	if raw_down is StatusEffectAttackDown:
		existing_down = raw_down as StatusEffectAttackDown

	var current_level : int = 0
	if existing_down != null:
		current_level = existing_down.stack_level

	if current_level >= 3:
		ctx.queue_battle_message("{target}'s attack cannot fall further.", target_battler)
		return false

	var desired_level : int = current_level + strength
	if desired_level > 3:
		desired_level = 3

	if existing_down != null:
		existing_down.set_stack_level(desired_level)
		existing_down.refresh_duration(duration_turns)
	else:
		var caster_battler : Battler = null
		if ctx.battle_scene != null:
			caster_battler = ctx.battle_scene.acting_battler

		var down : StatusEffectAttackDown = Registry.instantiate_status(&"statusattackdown") as StatusEffectAttackDown
		down.configure(desired_level, duration_turns)
		status_system.add_status(target_battler, down, caster_battler)

	if desired_level == 1:
		ctx.queue_battle_message("{target}'s attack falls!", target_battler)
	elif desired_level == 2:
		ctx.queue_battle_message("{target}'s attack falls further!", target_battler)
	else:
		ctx.queue_battle_message("{target}'s attack falls to its limit!", target_battler)

	return true
