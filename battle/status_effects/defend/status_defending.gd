class_name StatusEffectDefending
extends StatusEffect

@export var physical_damage_multiplier : float = 0.5
var protected_actor : ActorData = null

func _init() -> void:
	kind = StatusKind.LINK

func modify_incoming_physical_damage(_attacker_actor : ActorData, _action : BattleAction, original_target_actor : ActorData, final_target_actor : ActorData, damage : int) -> int:
	if protected_actor == null:
		return damage
	if original_target_actor != protected_actor:
		return damage
	if final_target_actor != receiver_actor:
		return damage

	var scaled : float = float(damage) * physical_damage_multiplier
	return int(round(scaled))

func on_apply(_status_system : StatusSystem) -> void:
	if receiver_actor == null:
		return
	expire_timing = ExpireTiming.TURN_START_OF_BATTLER
	expire_on_actor = receiver_actor

func on_remove(status_system : StatusSystem) -> void:
	if protected_actor == null:
		return
	if protected_actor.status_effects == null:
		return

	for i in range(protected_actor.status_effects.size() - 1, -1, -1):
		var s : StatusEffect = protected_actor.status_effects[i]
		if s is StatusEffectDefended:
			var d : StatusEffectDefended = s as StatusEffectDefended
			if d.defender_actor == receiver_actor:
				if status_system != null:
					var protected_battler : Battler = status_system.get_battler_for_actor(protected_actor)
					if protected_battler != null:
						status_system.remove_status(protected_battler, d)
						break

				d.on_remove(null)
				protected_actor.status_effects.remove_at(i)
				break
