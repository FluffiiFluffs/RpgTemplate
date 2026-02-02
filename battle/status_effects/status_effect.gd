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
