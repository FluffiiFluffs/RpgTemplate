Each derived stat has a float value (or values if more than one) that allows it to be tuned more precisely. This is a multiplier.

Stats grow on level up
Gear only modifies derived stats (HP/MP/ATK/DEF/MATK/MDEF)



Level (LV)
	Contributing factor to: 
		hit rate (like WoW)
		crit rate (like Wow)
		All derived stats (HP/SP/ATK/DEF/MATK/MDEF)

Hit Points (HP)
	Total health points (0 = dead)
	Is one of the deciding factors for order in battle if other stats are equal
	Is a combination of base + level bonus + stamina + gear
	base + (level * level_hp_scaler) + (stamina * stamina_hp_scaler) + gear_hp

Skill Points (SP) 
	Total skill points (must have enough to use the skill)
	Is a combination of base + (level * level_sp_scaler) + (magic * mag_sp_scaler) + gear_sp
	
ATTACK (ATK)
	Calculated into physical attack damage
	Is a combination of base + (strength * strength_atk_scaler) + gear_atk

DEFENSE (DEF)
	Used to calculate the amount of phsyical damage mitigated by a physical attack
	Does not work for magic
	Is a combination of base + (stamina * stamina_def_scaler) + gear_def
	
MAGIC ATTACK (MATK)
	Calculated into magical attack damage
	Is a combination of base + (magic * magic_atk_scaler) + gear_m_atk
	
	
MAGIC DEFENSE (MDEF)
	Used to calculate the amount of magical damage mitigated by a magical attack
	Does not work for physical attacks
	Is a combination of base + (magic * magic_def_scaler) + gear_m_def
	
Strength (STR)
	Part of the calculation for attack (ATK), therefore physical damage
	Some skills will use this in their damage calculations
	Is a combination of base + level bonuses

Stamina (STM)
	Part of the calculation for HP
	Part of the calculation for Defense
	Part of the calculation to resist sleep, stun
	Helps determine turn order
	Is a combination of base + level bonuses


Agility (AGI)
	Part of the calculation for evasion%
	Part of the calculation for hit%
	Part of the calculation to resist slow
	Is the foremost factor in turn order in battle
	Is a combination of base + level bonuses

MAGIC (MAG)
	The defining factor to determine how strong magical skills are (all types)
	Part of the calculation for resistance to magical damage
	Part of the calculation to resist all negative status effects
	Part of the calculation on max SP
	is a combination of base + level bonuses

LUCK (LCK)
	Helps determine chance of criticals
	Part of the calculation on evasion%
	Part of the calculation for hit%
	Part of the calculation on fully resisting magical damage
	Part of the calculation for resisting any negative status effect
	is a combination of base + level bonuses


[Battle Formulas]
Physical attack
Dodge and Parry have boolean switches on actor_data to determine if the actor can do either one in battle. Enemies usually dodge at best.
Enemies have a boolean for attacks_always_hit
Calculations should happen in this order.
Miss. If miss is true, then no more calculations are made
Dodge. If dodge is true, then no more calculations are made
Parry. If parry is true, hit is avoided
Riposte. If parry was true, then roll to see if riposte activates
Dispense riposte damage to attacker (and no damage to defender) if riposte is true

Raw Damage Calculated if miss/dodge/parry were false
Damage dispensed to defender and calculate in def value if 



	Hit/Miss
		attacker level vs defender level with baseline miss chance
		needs room for skills that cannot miss
		base miss chance = 3.0
		miss_per_level = 0.75
		level_difference = defender_level - attacker_level
		level_difference = clampi(level_difference, -10, 10)
			+/- 10 levels from the target gives +/- miss_per_level to miss
				Capped at 10 levels difference
				obviously, miss chance = 0 is the lowest it can go (attack always hits)
		miss_chance = base_miss_chance + (level_difference * miss_per_level)
		miss = randf_range(0.0, 100.0) < miss_chance


	Dodge (if miss check is failed and attacker's attack CAN miss)
		Uses Defender agi, defender luck
		base_dodge_chance = 1.0 (some lower percentage)
		agi_multiplier = 0.20
		luck_multiplier = 0.07
		dodge_chance = base_dodge_chance + (defender_agi * agi_multiplier) + (defender_luck * luck_multiplier)
		dodge = randf_range(0.0, 100.0) < dodge_chance


	Parry 
		defender str, defender agi
		base_parry_chance = 3.0 (some lower percentage)
		str_multiplier = 0.25 (under 0.5)
		agi_multiplier = 0.05 (under 0.5)
		parry_chance = base_parry_chance + (defender_str * str_multiplier) + (defender_agi * agi_multiplier)
		parry = randf_range(0.0,100.0) < parry_chance
		
	Riposte
		Chance to counter-attack
		50% chance if parry is true  (cannot happen if parry does not happen)
		Always hits, no miss/dodge/parry checks
			(Prevents a loop-ish situation)
		riposte_damage = defender_atk * riposte_atk_multiplier
		Is not lowered by a defense stat, a riposte is considered to be a surprise
		Riposte does not crit due to it bypassing defense
		riposte = randf_range(0.0, 100.0) < 50.0


	Damage calculation
		Attacker atk vs defender def
		Minimum damage is 1 damage
		Damage = ((attacker atk * atk_multiplier) - (defender def * def_multiplier)) * randf_range(-10.0, 10.0)
		has a variance of +/- 10% so damage isn't always the same
		atk_multiplier should be positive
		def_multiplier should be positive
		atk = (strength * multiplier) + weapon atk
		Currently the only damage mitigation that exists for a physical hit
			(other forms may exist later)

	Critical hit calculation
		crit_chance = flat_crit_rate + ((attacker_luck * attacker_luck_multiplier) - (defender_luck * defender_luck_multiplier)) 
		crit_chance should never be lower than flat_crit_rate (should start at 3.0)
		attacker/defender luck modifier is to help with tuning
			Will start at 1.0
		attacker/defender luck is their base luck + gear
		crit = randf_range(0.0, 100.0) < crit_chance
		crit_damage = raw_damage * crit_damage_multiplier
		Possibly, crit_damage_multiplier starts at 2.0 times raw damage and is raised 0.01 for every point of strength ((50 str * 0.01) + 2.0 = 2.5x damage)
		crit damage is not capped, higher strength means harder crits (always)










[Resist System]
Elemental resists range from -4 to +4 (-4, -3, -2, -1, 0, +1, +2, +3, +4)
-4 = 100% more damage from the element
-3 = 75% more damage from the element
-2 = 50% more damage from the element
-1 = 25% more damage from the element
0 = no more or less damage from the element
+1 = 25% less damage from the element
+2 = 50% less damage from the element
+3 = 75% less damage from the element
+4 = 100% less damage from the element

Status resists are individual and range from -4 to +4 (-4, -3, -2, -1, 0, +1, +2, +3, +4)
	(some math needs to be done to figure this out)
-4 = 100% higher chance status lands
-3 = 75% higher chance status lands
-2 = 50% higher chance status lands
-1 = 25% higher chance status lands
0 = no more or less damage from the element
+1 = 25% lower chance status lands
+2 = 50% lower chance status lands
+3 = 75% lower chance status lands
+4 = 100% lower chance status lands
