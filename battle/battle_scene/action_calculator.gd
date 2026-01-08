class_name ActionCalculator
extends Node
##action_calculator.gd
##Used in battle. Functions called to perform the math involved.
## Pure combat math for BattleActions.
## Calculates hit or miss, crit, damage or healing amounts, and any random rolls.
## Does not change game state, does not queue UI, does not play animations, and does not inspect the scene tree.
## Returns numbers or a small result object for ActionResolver to apply.

var battle_scene : BattleScene = null


##Calculates the damage from a normal attack (physical)
func normal_attack(from : Battler, attack : BattleAction, to : Battler)->int:
	#record total atk from battler
	var fromatk : int = from.actor_data.get_atk_value()
	#record total defense to battler
	var todef : int = to.actor_data.get_def_value()
	#calculate raw damage (atk and defense)
	var damage : int = clampi(fromatk - todef/2, 0, 9999) #simpleplaceholder formula
	#roll to determine if there is a miss (considered dodge/parry) (return -1 for this so the UI can show the difference between 0 damage and miss)
	var missvariance  = randi_range(-10,10)
	var misschance = randi_range(0,100) + (missvariance)
	var missroll = randi_range(0,100) + (from.actor_data.get_speed() / 2 )
	if missroll < misschance:
		return -1	
	#roll to determine if there is a block (highly mitigated damage)...figure this out later because it will be determined by stats and possibly what armor is being used. It probably needs a shield.
	
	#return final number
	return damage
	

##Returns amount of damage from an attack when a battler is defending.
func defend_amount(from : Battler, to : Battler, damage : int)->int:
	pass
	return 0

##Returns amount of damage from an attack when a battler successfully blocks.
##Block amount should be determined by the stats of the "to battler" 
func block_amount(from : Battler, to : Battler, damage : int)->int:
	return 0
	
##Calculates the amount of healing a spell will do
func heal_spell(from : Battler, spell : BattleAction, to : Battler)->int:
	#record healer's magic stat
	#use healer's magic stat and spell's power value to determine a raw amount to heal
	#vary that raw number by a certain amount (maybe 10%?)
	#return final number
	pass
	return 0

##Calculates the amount of spell damage a spell will do (may need to split up into types later).
##Will eventually factor in resists, but no system for this has been implemented yet (2026-08-01)
##TODO Implement resists
func spell_attack(from : Battler, spell : BattleAction, to : Battler)->int:
	pass
	return 0

##Determines if the run chance was successful. Returns true if successful, false if not.
##Rolls a random number (1-100) for the runner and the threshold (1-100) they must meet in order to run. 
##The runner's agility is added to their amount, the of the opposing side's agility is added to the threshold. 
##If the runner's random number + agility is over the threshold random + opposing average agility, then run is successful.[br]
##If the runner is a party member, the entire party runs away. If the runner is an enemy, only the single enemy gets away.
func run_success(runner : Battler)->bool:
	pass
	return false
