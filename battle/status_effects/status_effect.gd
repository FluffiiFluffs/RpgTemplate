class_name StatusEffect
extends Resource

enum StatusKind { AILMENT, ENHANCEMENT, STANCE, LINK, SPECIAL }
@export var kind : StatusKind = StatusKind.SPECIAL

var caster_actor : ActorData = null
var receiver_actor : ActorData = null

enum ExpireTiming { NONE, TURN_START_OF_BATTLER }
var expire_timing : ExpireTiming = ExpireTiming.NONE
var expire_on_actor : ActorData = null

enum Scope {BATTLE_ONLY, FIELD_ONLY, ALL}
@export var scope : Scope = Scope.BATTLE_ONLY

@export_category("Lifecycle")
@export var remove_on_death : bool = false

## Called for statuses owned by the acting battler at the start of their turn.
## Return true when you queued notifications or changed vitals so StatusSystem can await notify_finished.
func on_turn_start_tick(_status_system : StatusSystem) -> bool:
	return false

@export_category("Exclusivity")
@export var exclusive_group_id : StringName = &""
@export var exclusive_rank : int = 0

func on_apply(_status_system : StatusSystem) -> void:
	pass

func on_remove(_status_system : StatusSystem) -> void:
	pass

func redirect_incoming_target(_attacker_actor : ActorData, _action : BattleAction, _original_target_actor : ActorData) -> ActorData:
	return null

func modify_incoming_physical_damage(_attacker_actor : ActorData, _action : BattleAction, _original_target_actor : ActorData, _final_target_actor : ActorData, damage : int) -> int:
	return damage

func forces_physical_hit(_status_system : StatusSystem, _battler : Battler) -> bool:
	return false

# -------------------------------------------------------------------
# Turn permission hooks
# -------------------------------------------------------------------
## Return true when this status prevents the battler from taking any action on their turn.
func blocks_turn(_status_system : StatusSystem, _battler : Battler) -> bool:
	return false

## Return true when this status prevents the battler from entering the command selection flow.
## This allows cases where the battler still acts, but does so via forced action logic.
func blocks_command_selection(_status_system : StatusSystem, _battler : Battler) -> bool:
	return false

## Return an ActionUse when this status forces an action selection for the battler this turn.
## Return null when no forced action applies.
func get_forced_action_use(_status_system : StatusSystem, _battler : Battler) -> ActionUse:
	return null


func bind_battle_context(_receiver_actor : ActorData, _caster_actor : ActorData) -> void:
	receiver_actor = _receiver_actor
	caster_actor = _caster_actor

## Kept for compatibility with existing cleanup calls.
func detach_battle_context() -> void:
	pass

func get_receiver_actor() -> ActorData:
	return receiver_actor

func get_caster_actor() -> ActorData:
	return caster_actor


# -------------------------------------------------------------------
# Action lifecycle hooks
# -------------------------------------------------------------------
## Return true to cancel the selected ActionUse after selection (before execution).
func on_action_selected(_status_system : StatusSystem, _battler : Battler, _use : ActionUse) -> bool:
	return false

## Called immediately before the ActionUse is executed by ActionResolver.
## Use for per action setup, validation, or side effects.
func on_action_start(_status_system : StatusSystem, _battler : Battler, _use : ActionUse) -> void:
	pass

## Called immediately after the ActionUse finishes executing in ActionResolver.
## Use for per action cleanup, counters, or side effects.
func on_action_end(_status_system : StatusSystem, _battler : Battler, _use : ActionUse) -> void:
	pass



## Return an ActionUse when this status grants a post action bonus use (example: haste rank 3).
func get_post_action_bonus_use(_status_system : StatusSystem, _original_use : ActionUse) -> ActionUse:
	return null

## Called after damage is applied to the defender.
## dmg_ctx is a dictionary with keys you control, example:
## amount, is_dot, is_poison, effect_context
func on_receive_damage(_status_system : StatusSystem, _defender : Battler, _attacker : Battler, _action_use : ActionUse, _dmg_ctx : Dictionary) -> void:
	pass
