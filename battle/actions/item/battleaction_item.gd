class_name BattleActionItem
extends BattleAction

func _init() -> void:
	category = Category.ITEM
	type = ActionType.USE_ITEM
	target_shape = TargetShape.SINGLE
	target_side = TargetSide.ANY_FACTION
