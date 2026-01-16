class_name BattleActionRun
extends BattleAction


func _init()->void:
	category = Category.RUN
	type = ActionType.RUN
	target_shape = TargetShape.SELF
	target_side = TargetSide.SAME_FACTION
