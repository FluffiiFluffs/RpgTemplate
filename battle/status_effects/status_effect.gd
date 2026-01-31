class_name StatusEffect
extends Resource

enum StatusKind { AILMENT, ENHANCEMENT, STANCE, LINK, SPECIAL }
@export var kind : StatusKind = StatusKind.SPECIAL

var caster : Battler = null
var receiver : Battler = null
var caster_actor : ActorData = null
var receiver_actor : ActorData = null

enum ExpireTiming { NONE, TURN_START_OF_BATTLER }
var expire_timing : ExpireTiming = ExpireTiming.NONE
var expire_on_battler : Battler = null

enum Scope {BATTLE_ONLY, FIELD_ONLY, ALL}
@export var scope : Scope = Scope.BATTLE_ONLY


@export_category("Lifecycle")
@export var remove_on_death : bool = false


## Called for statuses owned by the acting battler at the start of their turn.
## Return true when you queued notifications or changed vitals so StatusSystem can await notify_finished.
func on_turn_start_tick(_status_system : StatusSystem) -> bool:
	return false


@export_category("Exclusivity")
## If set, only one status in this group should exist on a battler at a time.
## Example for poison: &"poison"
@export var exclusive_group_id : StringName = &""

## Higher rank overrides lower rank within the same exclusive group.
## Example mapping: very weak 10, weak 20, normal 30, strong 40, very strong 50
@export var exclusive_rank : int = 0




func on_apply(_status_system : StatusSystem) -> void:
	pass

func on_remove(_status_system : StatusSystem) -> void:
	pass

func redirect_incoming_target(_attacker : Battler, _action : BattleAction, _original_target : Battler) -> Battler:
	return null

func modify_incoming_physical_damage(_attacker : Battler, _action : BattleAction, _original_target : Battler, _final_target : Battler, damage : int) -> int:
	return damage



func bind_battle_context(_receiver : Battler, _caster : Battler) -> void:
	receiver = _receiver
	caster = _caster

	receiver_actor = null
	caster_actor = null

	if receiver != null:
		receiver_actor = receiver.actor_data
	if caster != null:
		caster_actor = caster.actor_data


func detach_battle_context() -> void:
	# ActorData references remain valid for field persistence
	receiver = null
	caster = null

	# Expiry that targets a Battler becomes invalid once battle nodes are freed
	expire_on_battler = null


func get_receiver_actor() -> ActorData:
	if receiver_actor != null:
		return receiver_actor
	if receiver != null:
		return receiver.actor_data
	return null


func get_caster_actor() -> ActorData:
	if caster_actor != null:
		return caster_actor
	if caster != null:
		return caster.actor_data
	return null
