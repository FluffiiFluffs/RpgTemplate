class_name StatusEffectDefending
extends StatusEffect

@export var physical_damage_multiplier : float = 0.5
var protected : Battler = null

func _init() -> void:
	kind = StatusKind.LINK

func modify_incoming_physical_damage(_attacker : Battler, action : BattleAction, original_target : Battler, final_target : Battler, damage : int) -> int:
	if protected == null:
		return damage
	if original_target != protected:
		return damage
	if final_target != receiver:
		return damage

	var scaled : float = float(damage) * physical_damage_multiplier
	return int(round(scaled))

func on_apply(_status_system : StatusSystem) -> void:
	if receiver == null:
		return
	expire_timing = ExpireTiming.TURN_START_OF_BATTLER
	expire_on_battler = receiver



func on_remove(status_system : StatusSystem) -> void:
	if protected == null:
		return
	if protected.actor_data == null:
		return
	if protected.actor_data.status_effects == null:
		return

	for i in range(protected.actor_data.status_effects.size() - 1, -1, -1):
		var s = protected.actor_data.status_effects[i]
		if s is StatusEffectDefended:
			var d = s as StatusEffectDefended
			if d.defender == receiver:
				status_system.remove_status(protected, d)
