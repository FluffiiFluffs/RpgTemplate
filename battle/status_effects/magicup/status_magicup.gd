class_name StatusEffectMagicUp
extends StatusEffect

@export_range(1, 3, 1) var stack_level : int = 1
@export_range(0.0, 1.0, 0.0001) var magic_percent_increase_total : float = 0.15

## Duration in the receiver's turns. 0 means entire battle.
@export_range(0, 99, 1) var duration_turns : int = 6
var turns_remaining : int = 6

var _stats_applied : bool = false
const _STAT_KEY : StringName = ActorData.STAT_MAGIC
const _SOURCE_KEY : StringName = &"status_magic_up"


func _init() -> void:
	kind = StatusKind.ENHANCEMENT
	scope = Scope.BATTLE_ONLY
	exclusive_group_id = &""
	exclusive_rank = 0
	remove_on_death = true
	expire_timing = ExpireTiming.NONE

	_sync_from_stack()
	turns_remaining = duration_turns


func configure(level : int, duration : int) -> void:
	stack_level = clampi(level, 1, 3)
	_sync_from_stack()

	duration_turns = max(duration, 0)
	turns_remaining = duration_turns


func refresh_duration(duration : int) -> void:
	duration_turns = max(duration, 0)
	turns_remaining = duration_turns


func set_stack_level(level : int) -> void:
	var new_level : int = clampi(level, 1, 3)
	if new_level == stack_level:
		return

	stack_level = new_level
	_sync_from_stack()

	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return
	if not _stats_applied:
		return

	_apply_magic_modifier(actor)


func _sync_from_stack() -> void:
	magic_percent_increase_total = get_percent_for_stack(stack_level)


static func get_percent_for_stack(level : int) -> float:
	if level <= 1:
		return 0.15
	if level == 2:
		return 0.20
	return 0.25


func on_apply(_status_system : StatusSystem) -> void:
	stack_level = clampi(stack_level, 1, 3)
	_sync_from_stack()

	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_apply_magic_modifier(actor)


func on_remove(_status_system : StatusSystem) -> void:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_remove_magic_modifier(actor)


func _apply_magic_modifier(actor : ActorData) -> void:
	var magnitude : float = abs(magic_percent_increase_total)
	if magnitude <= 0.0:
		return

	actor.set_stat_modifier(_STAT_KEY, _SOURCE_KEY, 0, magnitude)
	actor.clamp_vitals()
	_stats_applied = true


func _remove_magic_modifier(actor : ActorData) -> void:
	if not _stats_applied:
		return

	actor.remove_stat_modifier(_STAT_KEY, _SOURCE_KEY)
	actor.clamp_vitals()
	_stats_applied = false


func on_turn_start_tick(status_system : StatusSystem) -> bool:
	if duration_turns <= 0:
		return false

	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return false
	if actor.current_hp <= 0:
		return false

	if turns_remaining <= 0:
		if status_system != null:
			var battler : Battler = status_system.get_battler_for_actor(actor)
			if battler != null:
				status_system.remove_status(battler, self)
		return false

	turns_remaining -= 1
	return false
