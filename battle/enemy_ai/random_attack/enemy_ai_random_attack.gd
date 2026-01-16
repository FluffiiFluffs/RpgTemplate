class_name EnemyAIRandomAttack
extends EnemyAI

func choose_action_use(user : Battler, battle_scene : BattleScene)-> ActionUse:
	var action := _find_attack_action(user)
	var target := _pick_random_living_party_member(battle_scene)
	return ActionUse.new(user, action,[target])
	
	
func _find_attack_action(user : Battler)-> BattleAction:
	for act in user.actor_data.battle_actions.battle_actions:
		if act is BattleActionAttack:
			return act
	return null
	
	
func _pick_random_living_party_member(battle_scene : BattleScene)->Battler:
	var alive : Array[Battler] = []
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.faction == Battler.Faction.PARTY and bat.actor_data.current_hp > 0:
				alive.append(bat)
	return alive[randi_range(0, alive.size()-1)]
