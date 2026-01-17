class_name StatusEffect
extends Resource

enum StatusKind { AILMENT, ENHANCEMENT, STANCE, LINK, SPECIAL }
@export var kind : StatusKind = StatusKind.SPECIAL

var caster : Battler = null
var receiver : Battler = null

enum ExpireTiming { NONE, TURN_START_OF_BATTLER }
var expire_timing : ExpireTiming = ExpireTiming.NONE
var expire_on_battler : Battler = null

enum Scope {BATTLE_ONLY, FIELD_ONLY, ALL}
@export var scope : Scope = Scope.BATTLE_ONLY

func on_apply(_status_system : StatusSystem) -> void:
	pass

func on_remove(_status_system : StatusSystem) -> void:
	pass

func redirect_incoming_target(_attacker : Battler, _action : BattleAction, _original_target : Battler) -> Battler:
	return null

func modify_incoming_physical_damage(_attacker : Battler, _action : BattleAction, _original_target : Battler, _final_target : Battler, damage : int) -> int:
	return damage
