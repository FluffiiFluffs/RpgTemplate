Rule: Any time a status effect is applied to a character, and the status effect has a counter, the only time the counter will count down is when the target would have taken a turn.

[Poison]
	Target has a DOT applied to them
	Very Weak, Weak, Normal, Strong and Very Strong poisons exist
	Poison damage based on % of MAX_HP of the target, not a fixed value.
	Poison also lowers all stats by a certain %
	Damage does not break it
	Persists after battle
	Does not persist after death
	Is not overwritten by other status effects, but is overwritten by stronger poisons
		A weaker poison applied when a more powerful poison is in effect does nothing (message needed)
	Does not have stacks.
	Lasts until cured (indefinite duration)
	Persists out of battle (should have many ways to cure it though). The cure is uniform except for the highest level.
	Moving out of battle causes damage, but much lesser (player should be able to walk around but panic because they're poisoned)
		Graphical indication of poison ticking in the field needs to be done (probably a shader)
	(tuning needed for percentages in the future)
	Very Weak Poison - 0.3% of max HP per turn, 0.15% max hp in field. 5% stat decrease
	Weak Poison - 0.5% of max hp per turn, 0.25% max hp in field. 10% stat decrease
	Normal Poison - 1.0% of max hp per turn. 0.5% max hp in field. 15% stat decrease
	Strong Poison - 3.0% of max hp per turn. 1.0% max hp in field. 20% stat decrease
	Very Strong Poison - 5.0 of max HP per turn. 1.5% max hp in field. 30% stat decrease

[Sleep]
	Target unable to act during their turn if sleep is active
	Target is kept in turn queue
	Target unable to select commands
	During target's turn, there is a 1/4 chance they will wake up (random roll)
		If wake up roll is successful, commands are able to selected (meaning, this calculation needs to happen before anything else as with other status effects)
		Target also regenerates 5% of their health per turn if they fail the wakeup roll
	Being confused overwrites this effect
	Damage to the target has 1/2 a chance to wake them
	All attacks against the target always land
	Can be healed with items/skills that "heal all"
		so an effect_healsleep needs to be made eventually
	Is not broken by poison (user still takes damage during sleep)
		So sleep+poison is a great combo
	Does not persist after battle
	Does not persist after death

[Confuse]
	Target randomly selects an action they have available
		Includes normal attack, all skills, defend
		DISCLUDES run/items (problematic!)
	Target randomly selects a target (all allies/enemies that are alive)
	User cannot select anything
	Lasts 3 turns
	Damage has 1/2 chance to break the effect
	Is not broken by DOTs (and user takes the DOT damage, obviously)
	Does not persist through death
	Does not persist after battle
	Being stunned / sleeped overwrites this status effect
	
[Stun]
	Target is unable to act during their next turn
	Lasts only 1 turn
		ex: target is stunned, it is their turn, they are unable to act. status effect is taken off after this.
	Being hit with a stun before stun wears off does NOT extend the duration
	Is a separate component from damage (so there can be JUST stun or a skill that has the stun effect + damage effect...may require some rewiring)
	Does not persist through death
	Does not persist after battle
	Is not overwritten by any other skill (immutable)
	Poison tics persist during the skipped turn
	Cannot be cured
	
[Slow]
	Target's agility stat is lowered
		Lower agility = lower evasion %, more likely to act later in the round, lower hit %
		Does not reorder turn order array during current round, but still changes stat
	Stacks up to 3 times, (15, 20, 25%) less agility total
		These percentages are TOTAL, not additive. Rank 3 is 25% more agility.
		trying to stack a 3rd time will result in a "failure"
			{target} is as slow as they can get!
	3 stacks on a single target allows for a 1/4 chance for the selected action to fail (determined after action selection)
	Room for a skill that applies 3-stack slow immediately (no need to work up the levels) should be made
	Duration is for the entire battle
	Does not persist through death
	Does not persist after battle
	Is not broken by damage
	Overwritten by haste 
		Haste removes slow and starts at stack 1, or at stack 3 if the 3-stack skill is used

[Haste]
	Target's agility stat is raised
		higher agility = higher evasion %, more likely to act sooner in the round, higher hit %
		Does not reorder turn order array during current round, but still changes stat
	Stacks up to 3 times (15, 20, 25)% more agility total
		These percentages are TOTAL, not additive. Rank 3 is 25% more agility.
			trying to stack a 3rd time will result in a "failure"
			{target} are as fast as they can get!
	Duration is for the entire battle
	3 stacks allows a second attack or (free) spell or ability to be cast against the same enemy target.
		If the target dies during the first action, then another target is selected so this is not wasted. This goes for enemies AND the party.
	Room for a skill that applies 3-stack haste immediately (no need to work up the levels) should be made
	Lasts the entire battle
	Does not persist through death
	Does not persist after battle
	Is not broken by damage
	Overwritten by slow
		Slow removes haste and starts at stack 1, or at stack 3 if the 3-stack skill is used


[Attack / Defense Down (Weaken / Soften)]
	Target's Attack / Defense lowered by a certain % (needs tuning)
	Lasts 6 turns (needs a variable so this can be tuned later)
	Reapplication increases the % (not double, needs tuning) / Adds a stack
	Max 4 stacks
	Only affects physical attacks, not magic
	Does not persist after battle
	Does not persist after death
	Is not broken by damage
	1 application of Strengthen / Harden takes 1 stack away. If no stacks exist, then Strengthen / Harden is applied
		This allows a more linear experience

[Magic Down (Mind Fog)]
	Target's magic stat is reduced by certain %
		Lower magic stat = less magic damage, less magic defense
	Target's evasion reduced by a certain % (maybe just speed, but less than a slow)
	Lasts 4 turns
	Reapplication increases the % (needs tuning) / Adds a stack
	Max 4 stacks
	Does not persist after battle
	Does not persist after death
	Is not broken by damage
	1 application of Clarity takes 1 stack away. If no stacks exist, then Clarity is applied
		Same rules as Weaken/Soften, Strengthen/Harden
	
	
