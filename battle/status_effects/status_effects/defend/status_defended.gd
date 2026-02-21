class_name StatusEffectDefended
extends StatusEffect

var defender_actor : ActorData = null

func on_apply(_status_system : StatusSystem) -> void:
	if defender_actor == null:
		return
	expire_timing = ExpireTiming.TURN_START_OF_BATTLER
	expire_on_actor = defender_actor

func redirect_incoming_target(_attacker_actor : ActorData, action : BattleAction, original_target_actor : ActorData) -> ActorData:
	if action == null:
		return null
	if action.target_shape != BattleAction.TargetShape.SINGLE:
		return null

	if defender_actor == null:
		return null
	if defender_actor.current_hp <= 0:
		return null
	if defender_actor.status_effects == null:
		return null

	var found_link : bool = false
	for s in defender_actor.status_effects:
		if s is StatusEffectDefending:
			var defending : StatusEffectDefending = s as StatusEffectDefending
			if defending.protected_actor == original_target_actor:
				found_link = true
				break

	if not found_link:
		return null

	return defender_actor


func reset_runtime_state() -> void:
	super.reset_runtime_state()
	defender_actor = null
