class_name BuffDefend
extends Buff
##Buff given when a battler is being defended (be either themselves or another)
##Base defend with nothing special
##Should cut physical damage by half
##If a battler is self-defending, there should probably be a higher chance for attacks (of all types) missing, too. 


@export var defend_percent : int = 50

func defended_damage(rdamage : int)->int:
	@warning_ignore("integer_division")
	return rdamage / defend_percent
	
