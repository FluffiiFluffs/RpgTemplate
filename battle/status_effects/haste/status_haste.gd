class_name StatusEffectHaste
extends StatusEffect

## [Haste]
## Raises the receiver's agility via ActorData.buff_agility_percent.
## Stack levels are represented as ranks (1 to 3) via exclusive_rank.
## Rank values represent the total increase, not an additive delta.

@export_range(1, 3, 1) var stack_level : int = 1

## Total agility increase for the current stack level.
## This value is derived from stack_level via _sync_from_stack().
@export_range(0.0, 1.0, 0.0001) var agility_percent_increase_total : float = 0.15

var _stats_applied : bool = false


func _init() -> void:
	kind = StatusKind.ENHANCEMENT
	scope = Scope.BATTLE_ONLY

	exclusive_group_id = &"haste"
	exclusive_rank = 1

	remove_on_death = true
	expire_timing = ExpireTiming.NONE

	_sync_from_stack()


## Configure this instance for a specific stack level.
## Call this immediately after StatusEffectHaste.new() and before the status is added.
func configure(level : int) -> void:
	stack_level = clampi(level, 1, 3)
	exclusive_rank = stack_level
	_sync_from_stack()


func _sync_from_stack() -> void:
	agility_percent_increase_total = get_percent_for_stack(stack_level)


static func get_percent_for_stack(level : int) -> float:
	if level <= 1:
		return 0.15
	if level == 2:
		return 0.20
	return 0.25


func is_max_stack() -> bool:
	return stack_level >= 3


func on_apply(_status_system : StatusSystem) -> void:
	# Keep rank and tuning synced in case this Resource was edited in the inspector
	stack_level = clampi(stack_level, 1, 3)
	exclusive_rank = stack_level
	_sync_from_stack()

	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_apply_agility_increase(actor)


func on_remove(_status_system : StatusSystem) -> void:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_remove_agility_increase(actor)


func _apply_agility_increase(actor : ActorData) -> void:
	if _stats_applied:
		return

	var magnitude : float = abs(agility_percent_increase_total)
	if magnitude <= 0.0:
		return

	actor.buff_agility_percent += magnitude
	actor.clamp_vitals()
	_stats_applied = true


func _remove_agility_increase(actor : ActorData) -> void:
	if not _stats_applied:
		return

	var magnitude : float = abs(agility_percent_increase_total)
	if magnitude <= 0.0:
		return

	actor.buff_agility_percent += -magnitude
	actor.clamp_vitals()
	_stats_applied = false
