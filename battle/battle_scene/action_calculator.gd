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
##Should be depreciated in lieu of returning individualized bools and values from separate functions instead of this one big one. Calling the calculation functions should be called from action_resolver. 
func normal_attack(from : Battler, _attack : BattleAction, to : Battler, force_hit : bool = false) -> int:
	#record total atk from battler
	var fromatk : int = from.actor_data.get_atk_value()
	#record total defense to battler
	var todef : int = to.actor_data.get_def_value()
	#calculate raw damage (atk and defense)
	@warning_ignore("integer_division")
	var damage : int = clampi((fromatk*2) - (todef/2), 0, 9999) #simpleplaceholder formula
	#roll to determine if there is a miss (considered dodge/parry) (return -1 for this so the UI can show the difference between 0 damage and miss)
		# Sleep: attacks always land
	if force_hit:
		return damage


	
	var missvariance  = randi_range(-10,10)
	var misschance = randi_range(0,100) + (missvariance)
	var missroll = randi_range(0,100) + (from.actor_data.get_agility())
	if missroll < misschance:
		return -1	
	#roll to determine if there is a block (highly mitigated damage)...figure this out later because it will be determined by stats and possibly what armor is being used. It probably needs a shield.
	
	#return final number
	return damage
	
##Determines if a physical skill will hit or miss	
func physical_will_miss(from : Battler, to : Battler, cannot_miss : bool)->bool:
	if cannot_miss:
		return false #attack did not miss
	##Base chance the skill will miss
	var base_miss_chance : float = 3.0
	#How much additional chance to miss determined by level difference
	var miss_per_level : float = 0.7
	var level_difference : float = clampf(to.actor_data.level - from.actor_data.level, -10.0, 10.0)
	var miss_chance : float = base_miss_chance + (level_difference * miss_per_level)
	print(str(miss_chance))
	var miss : bool = randf_range(0.0, 100.0) < miss_chance
	print(str(miss))
	if miss:
		return true #attack missed
	else:
		return false #attack did not miss

##Determines if a physical attack was dodged
func physical_will_dodge(to : Battler, cannot_dodge : bool)->bool:
	if cannot_dodge:
		return false
	var base_dodge_chance : float = 1.0
	var agi_multiplier : float = 0.20
	var lck_multiplier : float = 0.07
	var defender_agi = to.actor_data.get_agility()
	var defender_lck = to.actor_data.get_luck()
	var dodge_chance : float = base_dodge_chance + (defender_agi * agi_multiplier) + (defender_lck * lck_multiplier)
	dodge_chance = clampf(dodge_chance, 0.0, 25.0)
	print(str(dodge_chance))
	var dodge : bool = randf_range(0.0, 100.0) < dodge_chance
	print(str(dodge))
	if dodge:
		return true #attack was successfully dodged
	else:
		return false #attack was not dodged

##Returns bool for if a phsyical attack is parried in battle
func physical_will_parry(to : Battler, cannot_parry : bool)->bool:
	if cannot_parry:
		return false
	#var base_parry_chance : float = 3.0
	var base_parry_chance = 25.0 #for testing
	var str_multiplier : float = 0.25
	var agi_multiplier : float = 0.05
	var defender_str = to.actor_data.get_strength()
	var defender_agi = to.actor_data.get_agility()
	var parry_chance = base_parry_chance + (defender_str * str_multiplier) + (defender_agi * agi_multiplier)
	parry_chance = clampf(parry_chance, 0.0, 25.0)
	print(parry_chance)
	var parry : bool = randf_range(0.0, 100.0) < parry_chance
	if parry:
		return true
	else:
		return false

##Determines if a parry will riposte the attack
func physical_will_riposte()->bool:
	#var riposte_chance : float = 50.0
	var riposte_chance : float = 100.0 #for testing
	var riposte : bool = randf_range(0.0, 100.0) < riposte_chance
	if riposte:
		return true
	else:
		return false

##Returns amount of damage for a riposte
func get_riposte_damage(to : Battler)->int:
	var defender_atk = to.actor_data.get_atk_value()
	var atk_multiplier : float = 1.20
	return defender_atk * atk_multiplier

##Returns the raw amount of damage to be dealt. Does not factor in defender's defense value.
func get_raw_damage(from : Battler)->int:
	var attacker_atk = from.actor_data.get_atk_value()
	var atk_multiplier = 1.5 #for tuning
	var raw_damage = attacker_atk * atk_multiplier
	return raw_damage
	
##Varies damage within a certain range.
##Should be used before armor reduction calculation
##Variance should be input as 10 meaning 10%
func vary_damage(raw_damage : int, variance_percent : int) -> int:
	var variance_amount : int = int(round(raw_damage * (float(variance_percent) / 100.0)))
	return raw_damage + randi_range(-variance_amount, variance_amount)

	
##Returns damage amount when the defender's defense is used
##Damage value used should be the one from vary_damage
func get_physical_def_mitigated_damage(damage : int, to : Battler)->int:
	var defender_def = to.actor_data.get_def_value()
	var def_multiplier : float = 0.5
	var final_damage = damage - (defender_def * def_multiplier)
	return clampi(final_damage, 1, 9999) ##Final damage cannot be less than 1 or more than 9999
	

##Returns bool for if an attack that has landed is critical damage
func physical_will_crit( from : Battler, to : Battler)->bool:
	var defender_lck = to.actor_data.get_luck()
	var defender_luck_multiplier : float = 1.0
	var attacker_luck = from.actor_data.get_luck()
	var attacker_luck_modifier : float = 1.0
	var base_crit_rate = 3.0
	return randf_range(0.0, 100.0) < clampf(base_crit_rate + (defender_lck * defender_luck_multiplier) - (attacker_luck * attacker_luck_modifier), 0.0, 999.0) #Should never be below 0, but base crit rate should be able to be negated via defender's luck

##Returns amount of critical damage when physical_will_crit is true
func get_crit_damage(from : Battler, raw_damage : int)->int:
	var crit_damage_multipier : float = 2.0
	var attacker_strength = from.actor_data.get_strength()
	var str_multiplier : float = 0.1
	return (raw_damage * (crit_damage_multipier + (attacker_strength * str_multiplier)))


##Returns amount of damage from an attack when a battler is defending.
func defend_amount(_from : Battler, _to : Battler, _damage : int)->int:
	pass
	return 0

	
##Calculates the amount of healing a spell will do
func heal_spell(_from : Battler, _spell : BattleAction, _to : Battler)->int:
	#record healer's magic stat
	#use healer's magic stat and spell's power value to determine a raw amount to heal
	#vary that raw number by a certain amount (maybe 10%?)
	#return final number
	pass
	return 0

##Calculates the amount of spell damage a spell will do (may need to split up into types later).
##Will eventually factor in resists, but no system for this has been implemented yet (2026-08-01)
##TODO Implement resists
func spell_attack(_from : Battler, _spell : BattleAction, _to : Battler)->int:
	pass
	return 0

##Determines if the run chance was successful. Returns true if successful, false if not.
##Rolls a random number (1-100) for the runner and the threshold (1-100) they must meet in order to run. 
##If the runner is a party member, the entire party runs away. If the runner is an enemy, only the single enemy gets away.
func run_success(runner : Battler)->bool:
	if runner is Battler:
		var runnerspd : float = runner.actor_data.get_agility()
		var oppoidx : float = 0.0
		var oppotot : float = 0.0
		var oppoavg : float = 0.0
		var rchance : float = randf_range(0.0,100.0)
		var oppochance : float = randf_range(0.0,100.0)

		if runner.faction == Battler.Faction.PARTY:
			pass
			for enemy in battle_scene.battlers.get_children():
				if enemy is Battler:
					if enemy.faction == Battler.Faction.ENEMY:
						oppoidx += 1
						oppotot += enemy.actor_data.get_agility()
			oppoavg = (oppotot / oppoidx)
			print("oppototal: " + str(oppoavg + oppochance) + "  runnertotal: " + str(runnerspd + rchance))
			return (oppoavg + oppochance) < (runnerspd + rchance)
					

		elif runner.faction == Battler.Faction.ENEMY:
			pass
	pass
	return false
