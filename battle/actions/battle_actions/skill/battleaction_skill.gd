class_name BattleActionSkill
extends BattleAction

func _init() -> void:
	category = Category.SKILL
	type = ActionType.USE_SKILL
	target_shape = TargetShape.SINGLE
	target_side = TargetSide.ANY_FACTION
