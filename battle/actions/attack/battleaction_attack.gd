class_name BattleActionAttack
extends BattleAction
## battleaction_attack.gd
## Standard basic melee Attack command.
## Uses ActionType.NORMAL_ATTACK and relies entirely on battler stats in ActionCalculator.

func _init()->void:
	category = Category.ATTACK
	expanded_shape = TargetShape.SINGLE
