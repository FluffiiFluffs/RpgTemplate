class_name EnemyAIRandomAttack
extends EnemyAI

func choose_action_use(user : Battler, battle_scene : BattleScene) -> ActionUse:
	var action : BattleAction = _find_attack_action(user)
	if action == null:
		return null

	var target : Battler = Targeting.pick_random_living_enemy(user, battle_scene)
	if target == null:
		return null

	return ActionUse.new(user, action, [target])

	
func _find_attack_action(user : Battler)-> BattleAction:
	for act in user.actor_data.battle_actions.battle_actions:
		if act is BattleActionAttack:
			return act
	return null
	
	
