class_name StatusEffectSlow
extends StatusEffect

## [Slow]
## Lowers the receiver's agility via ActorData stat modifier aggregator.
## Stack levels are represented as ranks (1 to 3) via exclusive_rank.
## Rank values represent the total reduction, not an additive delta.

@export_range(1, 3, 1) var stack_level : int = 1

## Total agility reduction for the current stack level.
## This value is derived from stack_level via _sync_from_stack().
@export_range(0.0, 1.0, 0.0001) var agility_percent_decrease_total : float = 0.15

## At max stacks (3), the acting battler has this chance to lose their selected action.
## The roll is performed by TurnManager after action selection.
@export_range(0.0, 1.0, 0.0001) var action_fail_chance_at_max : float = 0.25

var _stats_applied : bool = false

const _STAT_KEY : StringName = ActorData.STAT_AGILITY
const _SOURCE_KEY : StringName = &"status_slow"

## Configure this instance for a specific stack level.
## Call this immediately after instantiation and before the status is added.
func configure(level : int) -> void:
	stack_level = clampi(level, 1, 3)
	exclusive_rank = stack_level
	_sync_from_stack()


func _sync_from_stack() -> void:
	agility_percent_decrease_total = get_percent_for_stack(stack_level)


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

	_apply_agility_decrease(actor)


func on_remove(_status_system : StatusSystem) -> void:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_remove_agility_decrease(actor)

func _apply_agility_decrease(actor : ActorData) -> void:
	if _stats_applied:
		return

	var magnitude : float = abs(agility_percent_decrease_total)
	if magnitude <= 0.0:
		return

	actor.set_stat_modifier(_STAT_KEY, _SOURCE_KEY, 0, -magnitude)
	actor.clamp_vitals()
	_stats_applied = true

func _remove_agility_decrease(actor : ActorData) -> void:
	if not _stats_applied:
		return

	actor.remove_stat_modifier(_STAT_KEY, _SOURCE_KEY)
	actor.clamp_vitals()
	_stats_applied = false


func on_action_selected(status_system : StatusSystem, battler : Battler, _use : ActionUse) -> bool:
	if not is_max_stack():
		return false

	if randf() >= action_fail_chance_at_max:
		return false

	if status_system != null and status_system.battle_scene != null and status_system.battle_scene.battle_notify_ui != null:
		var name_text : String = "Someone"
		if battler != null and battler.actor_data != null:
			name_text = battler.actor_data.get_display_name()
		status_system.battle_scene.battle_notify_ui.queue_notification(name_text + " is too slow to act.")

	return true

func reset_runtime_state() -> void:
	super.reset_runtime_state()
	_stats_applied = false
