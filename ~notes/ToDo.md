#Create item/skill fields that can be parsed by battle_scene's textparser so it can be converted to a string for the battle notify UI to show
Create quote bubble system for in-battle use

##Convert MP (Magic Points) to SP (Skill Points)
##Convert SPD (Speed) to AGI (Agility) (since SP and SPD are similar)

Implement other-party-member-leading routines for when the main character is dead
	(needs to be like earthbound / DQ)

Bug when selected skills is in targeting and cancelled out of, skill selected in menu stays highlighted

Implement skill usage outside of battle
Implement skills being rearranged / sorted just like items

Test menu memory more thoroughly and make it default ON

Implement Status Effects
Need to implement visual elements (like purple bubbles when poisoned) so it's apparent which status effect is affecting who in battle
	#Poison (in and out of battle)
		#poison heal needs a message when it successfully heals the poison
		#Same for items
		#Poison persists in and out of battle correctly. However, if a character is poisoned, enters battle, they DO correctly receive damage from the poison when it is their turn but the popup for poison doesn't work. Healing and reappling the poison makes this work correctly.
		#Need to implement out-of-battle visuals for poison that isn't too jarring, probably smaller poison bubbles. Needs to be an animation or something that persistently plays (not just when the poison tics)..but also needs to have something special happen during the poison tic.
		#Out-of-battle poison should only ever bring the party member down to 1hp. visuals/etc still play but HP should remain at 1 (like final fantasy 6). Poison in-battle should be able to kill, though.
		#Poison tics if the player moves at all and tics based upon a threshold. Very short presses in a direction still up this counter (distance threshold, too)
		#Healing Poison needs to be taken care of
		
	#Sleep
	#Stun
	#Confuse
	#Slow
	#Haste
	Attack up / down
	Defense up / down
	Magic up / down
	Berserk (do this later, not important)
	
Implement semi-unique names in battle for enemies that share the same name (A B C, 1 2 3)

Stats
	Implement luck for crits
	clean up formulas
	clean up char_resource and actor data
	Formulas for battle
	
Implement a deeper system for miss / dodge/ parry / block / riposte
	
Implement status/Elemental resists
	
Implement leveling system
	

Modify the battle_notify_ui to reveal text (very fast, it's battle)
Modify battle_notify_ui to allow 3 lines of text
Modify battle_notify_ui to scroll upwards when text reaches the 3 line limit
Determine how many characters a line can have (need to research which character takes up the most space)

Refactor the battle system to be a little more streamlined in the code so it is easier to understand what's going on
	Refactor should involve CLEARLY defining what each system does instead of having the UI decide certain
	things vs the actual systems doing that and the UI simply asking for it or something 
	(need to really think about this)

Fix Quest system UI
	(selecting completed quests does not focus the first quest in the list)

Fix bug when player has selected defend and cancels out of targeting, attack is selected (should reselect defend)


Refactor the game menu UI so it is not one large script
	maybe clean up the way it works a little, too

Implement cutscenes

Implement save/load system
	Also implement persistence system between scenes for certain things like opening chests
	
Check DialogueManager code to try to figure out if some things implemented were already in place by default
	within the dialoguemanager addon (specifically the portrait thing)

Have a script go through the items folder to automatically add them to all_items instead of adding them directly, this should save a lot of time.

Implement ! and ? overhead for interactable objects and NPCs


Implement character naming similar to mother series with "don't care" option
