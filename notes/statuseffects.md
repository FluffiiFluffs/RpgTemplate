Rule: Any time a status effect is applied to a character, and the status effect has a counter, the only time the counter will count down is when the target would have taken a turn.

Poison
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

Sleep
	Target unable to act
	Lasts 1-3 turns (random roll to determine the duration upon application)
	Being stunned or confused overwrites this effect
	Is not broken by poison (user still takes damage during sleep)
	Reapplication extends duration
	Does not persist after battle
	Does not persist after death

Confuse
	Target randomly selects actions and targets
	Lasts 2 turns
	Most damage breaks the effect
	Is not broken by DOTs (and user takes the DOT damage, obviously)
	Does not persist through death
	Does not persist after battle
	Being stunned / sleeped overwrites this status effect
	
Stun
	Target is unable to act during their next turn
	Lasts only 1 turn
	Being hit with a stun before stun wears off extends the duration by 1 turn
	Does not persist through death
	Does not persist after battle
	Is not overwritten by anything
	Poison tics persist during the skipped turn
	Cannot be cured
	
Slow
	Target's speed stat is lowered
		Lower speed = lower evasion %, more likely to act later in the round, lower hit %
		Percentages need to be tuned
	Lasts 2-5 turns
	Does not persist through death
	Does not persist after battle
	Is not broken by damage
	Overwritten by haste 
		Haste does not "restore" speed. Remove slow status and applies haste status
		
Attack / Defense Down (Weaken / Soften)
	Target's Attack / Defense lowered by a certain % (needs tuning)
	Lasts 4 turns (may need tuning)
	Reapplication increases the % (not double, needs tuning) / Adds a stack
	Max 4 stacks
	Only affects physical attacks, not magic
	Does not persist after battle
	Does not persist after death
	Is not broken by damage
	1 application of Strengthen / Harden takes 1 stack away. If no stacks exist, then Strengthen / Harden is applied
		This allows a more linear experience

Magic Down (Mind Fog)
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
	
	
