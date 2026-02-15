class_name EnemyAIRandomAttack
extends EnemyAI

func choose_action_use(user : Battler, battle_scene : BattleScene) -> ActionUse:


	var target : Battler = Targeting.pick_random_living_enemy(user, battle_scene)
	
	var normal_skill : Skill = user.actor_data.normal_attack_skill
	
	if normal_skill != null:
		var use : ActionUse = ActionUse.new(user, battle_scene.BATTLEACTION_SKILL, [target], {})
		use.skill = normal_skill
		return use

	return null
