class_name ActionCalculator
extends Node
##action_calculator.gd
##Used in battle. Functions called to perform the math involved.
## Pure combat math for BattleActions.
## Calculates hit or miss, crit, damage or healing amounts, and any random rolls.
## Does not change game state, does not queue UI, does not play animations, and does not inspect the scene tree.
## Returns numbers or a small result object for ActionResolver to apply.

var battle_scene : BattleScene = null



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
	print("MISS CHANCE : " + str(miss_chance))
	var miss : bool = randf_range(0.0, 100.0) < miss_chance
	print("MISS : " + str(miss))
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
	print("DODGE CHANCE : " + str(dodge_chance))
	var dodge : bool = randf_range(0.0, 100.0) < dodge_chance
	print("DODGE : " + str(dodge))
	if dodge:
		return true #attack was successfully dodged
	else:
		return false #attack was not dodged

##Returns bool for if a phsyical attack is parried in battle
func physical_will_parry(to : Battler, cannot_parry : bool)->bool:
	if cannot_parry:
		return false
	var base_parry_chance : float = 3.0
	#var base_parry_chance = 25.0 #for testing
	var str_multiplier : float = 0.25
	var agi_multiplier : float = 0.05
	var defender_str = to.actor_data.get_strength()
	var defender_agi = to.actor_data.get_agility()
	var parry_chance = base_parry_chance + (defender_str * str_multiplier) + (defender_agi * agi_multiplier)
	parry_chance = clampf(parry_chance, 0.0, 25.0)
	print("PARRY CHANCE : " + str(parry_chance))
	var parry : bool = randf_range(0.0, 100.0) < parry_chance
	print("PARRY : " + str(parry))
	if parry:
		return true
	else:
		return false

##Determines if a parry will riposte the attack
func physical_will_riposte()->bool:
	var riposte_chance : float = 50.0
	#var riposte_chance : float = 100.0 #for testing
	var riposte : bool = randf_range(0.0, 100.0) < riposte_chance
	print("RIPOSTE : " + str(riposte))
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
func physical_will_crit(from : Battler, to : Battler) -> bool:
	var attacker_lck : int = from.actor_data.get_luck()
	var attacker_luck_multiplier : float = 1.0

	var defender_lck : int = to.actor_data.get_luck()
	var defender_luck_modifier : float = 1.0

	var base_crit_rate : float = 15.0
	var crit_chance : float = base_crit_rate + (attacker_lck * attacker_luck_multiplier) - (defender_lck * defender_luck_modifier)
	crit_chance = clampf(crit_chance, 0.0, 999.0)

	var crit : bool = randf_range(0.0, 100.0) < crit_chance
	print("CRIT : " + str(crit))
	return crit

##Returns amount of critical damage when physical_will_crit is true
func get_crit_damage(from : Battler, raw_damage : int)->int:
	var crit_damage_multipier : float = 2.0
	var attacker_strength = from.actor_data.get_strength()
	var str_multiplier : float = 0.1
	var crit_damage = (raw_damage * (crit_damage_multipier + (attacker_strength * str_multiplier)))
	return crit_damage


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

## Determines whether a run attempt succeeds.
## Current behavior:
##   Party runner: compares runner agility plus a random roll against the average enemy agility plus a random roll.
##   Enemy runner: no logic is present, so the function returns false.
##
## This function returns a pure boolean and does not perform any state changes.
func run_success(runner : Battler)->bool:
	# runner is typed as Battler, so this check is redundant.
	# It is retained to avoid changing existing control flow in this pass.
	if runner is Battler:
		# Runner agility is treated as the speed stat used for run checks.
		var runnerspd : float = runner.actor_data.get_agility()

		# Enemy aggregation used to compute average opposing agility.
		var oppoidx : float = 0.0
		var oppotot : float = 0.0
		var oppoavg : float = 0.0

		# Random bonus rolls added to each side of the comparison.
		var rchance : float = randf_range(0.0, 100.0)
		var oppochance : float = randf_range(0.0, 100.0)

		if runner.faction == Battler.Faction.PARTY:
			# Compute average enemy agility for all enemy battlers currently in battle_scene.battlers.
			for enemy in battle_scene.battlers.get_children():
				if enemy is Battler:
					if enemy.faction == Battler.Faction.ENEMY:
						oppoidx += 1
						oppotot += enemy.actor_data.get_agility()

			# oppoidx is expected to be greater than 0 during a valid battle run attempt.
			oppoavg = (oppotot / oppoidx)

			# Success when runner total exceeds opposing average total.
			return (oppoavg + oppochance) < (runnerspd + rchance)

		elif runner.faction == Battler.Faction.ENEMY:
			# Placeholder branch, currently returns false.
			pass

	# Fallback for unsupported cases.
	return false
