Leveling script probably needs to live within CharDataKeeper due it it dealing with party member stats and is an always accessable. Leveling needs to be accessable during any part of the game. Showing the messages for leveling will be handled on a case-by-case basis depending on the game's state (field, battle, minigame, etc)

Experience is dispensed (through battle, quest or event)
Check to see if the party members that received experience can level (only current party, not dead)
	Probably needs a while loop to check for multiple levels...or maybe just a second if statement that calls the function again? not sure. While loops can be risky.

if a party member has reached a threshold (total party member exp greater than or equal to next level exp) to level... then
Store current base stats of the character HP, SP, STR, STM, AGI, MAG, LCK (this is recorded to report it later in the messaging systems)
	ATK/DEF/MATK/MDEF not reported since they're derived. HP/SP are reported since players typically care about this sort of change. 
Subtract amount of experience needed to level from party member's total exp
Increment level by 1 and message: "Warrior is now level 15!"
Apply new stats from stats table, recalculate max hp (and show it if applicable) from hp_sp mod values
Check skills/level table (yet to be designed or made) to determine if a new skill is learned
Rebuild stat values on the back end at some point
Find the difference in the old stats and new stats
	These should be raw stat values and not modified values
Put these differences into a message: "Warrior gained +20 HP!", "Warrior gained +1 Strength!", "Warrior gains [new skill]"
Show the messages either in battle or on a special window designed to show if the level was gained in the field
Check to see if the next party member has leveled



Experience for party members
Should be expresed with a resource table similar to hp_sp_mod. Uses an array. 0 = level 1 to level 2. These values are predefined and all party members share this (for now, no need to get fancy with it).
Each value per level is the amount needed per level.
	Example 
		array[0], is the amount needed from level 1 to level 2. Its value is 1000 exp. This amount is reflected in the stats menu. This amount is checked against every time experience is gained.
			array[1] would be the experience value needed from level 2 to level 34. its value would need to be more than level 1's. 
	Each party member will simply keep an experience total that they accumulate during gameplay.
	"NextLvL" in menu needs to just update every time the menu is opened, probably easiest this way. This amount is subtracted from when a level up happens.
