class_name BattleActionDefend
extends BattleAction
##battleaction_defend


func _init()->void:
	category = Category.DEFEND
	type = ActionType.DEFEND
	target_shape = TargetShape.SINGLE
	target_side = TargetSide.SAME_FACTION
	
