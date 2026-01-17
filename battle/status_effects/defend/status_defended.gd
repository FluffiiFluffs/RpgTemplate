class_name StatusEffectDefended
extends StatusEffect

var defender : Battler = null

func _init() -> void:
	kind = StatusKind.LINK

func on_apply(_status_system : StatusSystem) -> void:
	if defender == null:
		return
	expire_timing = ExpireTiming.TURN_START_OF_BATTLER
	expire_on_battler = defender

func redirect_incoming_target(_attacker : Battler, action : BattleAction, original_target : Battler) -> Battler:
	if action == null:
		return null
	if action.target_shape != BattleAction.TargetShape.SINGLE:
		return null

	if defender == null:
		return null

	# Relationship validation so stale links do nothing.
	var defending : StatusEffectDefending = StatusSystem.find_status(defender, StatusEffectDefending)
	if defending == null:
		return null
	if defending.protected != original_target:
		return null

	# Dead battlers still exist, so guard against redirecting to a dead defender.
	if defender.actor_data.current_hp <= 0:
		return null

	return defender
	
	
