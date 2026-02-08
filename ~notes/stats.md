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
	Raw damage calculation first (so block can work)
		Attacker atk vs defender def
		attacker atk - defender def
			if >= 0, 0 damage



	Critical hit calculation
		

	Hit/Miss
		attacker agi, attacker level vs defender agi, defender level
		needs room for skills that cannot miss

	Dodge (if miss check is failed and attacker's attack CAN miss)
		attacker agi, attacker level, vs defender agi, defender level

	Parry 
		attacker agi, attacker level, vs defender agi, defender level

	Block
		attacker agi, attacker level vs defender agi, defender level
		if blocked, utilizes attacker atk vs defender def to determine










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
