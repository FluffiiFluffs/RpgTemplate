#All commented out lines are completed

[Big Changes]
	#Implement cutscenes
		**Cutscenes have been mostly implemented, but the system could use some refinement**

	#Implement save/load system
		#Also implement persistence system between scenes for certain things like opening chests

	STATS
		#Implement luck 
		#crit
		#evasion/hit
		full resist magic damage
		resist negative status effects + break out
			
		#clean up formulas
		#clean up actor data
		#Formulas for battle
		
	# Implement a deeper system for miss / dodge/ parry / block / riposte
	
	Implement status/Elemental resists
	
	#Implement leveling system
		#Leveling System is implemented...in battle
		Out of battle messaging and level ups needed

	Refactor the battle system to be a little more streamlined in the code so it is easier to understand what's going on
		Refactor should involve CLEARLY defining what each system does instead of having the UI decide certain things vs the actual systems doing that and the UI simply asking for it or something 
			(need to really think about this)


	[NEXT]
	#Implement character naming similar to mother series with "don't care" option
	This is mostly implemented, however the title scene needs to be updated
		#Options menu needs to be updated to be more in line with what's in game_menu
		New Game needs to trigger naming
			cutscene actions need to be added to:
				await
				call function from a script (somehow)
			The way this should work is:
				new game button is pressed, confirm pops up, yes is pressed, cutscene starts, first cutscene action calls scenemanager instantiation of the naming scene for warrior, second cutscene action is await until it hears a signal that naming is done, third cutscene action is to load a field scene that is the intro the the game.
	[NEXT]
	
	
	
	#Check DialogueManager code to try to figure out if some things implemented were already in place by default
	#	within the dialoguemanager addon (specifically the portrait thing)
	#** Dialogue Manager handling has been reworked so that dm_helper handles almost everything. SpeakerResource reworked. Easier authoring within dialogue scripts. Also added the ability to use PLAYER: to use the speaker resource attached to the currently controlled party member's SpeakerResource.
		
	#Implement title screen / intro sequence
		**a baseline version of this has been implemented, complete with a menu for options**
		loading menu needs to be implemented
		
	Implement shop system

[BATTLE] 
	party defeat needs to be handled, currently unimplemented
		probably needs to happen after the save-load system is implemented so a restart position / scene can be set.
	
	Implement semi-unique names in battle for enemies that share the same name (A B C, 1 2 3)

	Implement other-party-member-leading routines for when the main character is dead (or later the player will be able to change the party order)
		(needs to be like earthbound / DQ)
	

#	Implement power value for skills that heal or do damage
#		Power value should be used for scaling
#		Need to implement an enum for which stat to scale from

	
	## maybe not 
		Create quote bubble system for in-battle use
	
	Modify the battle_notify_ui to reveal text (very fast, it's battle)
	Modify battle_notify_ui to allow 3 lines of text
	Modify battle_notify_ui to scroll upwards when text reaches the 3 line limit
	
	Determine how many characters a line can have (need to research which character takes up the most space)
	
	Need to implement visual elements (like purple bubbles when poisoned) so it's apparent which status effect is affecting who in battle


[INVENTORY]
	#Have a script go through the items folder to automatically add them to all_items instead of adding them directly, this should save a lot of time. ** Implemented during registry refactor

[QUESTS]
	FIX Quests do not seem to work properly when the game is loaded, needs more testing



[UI]
	#Update UI for luck
		#stats page
		#equip page
		#inventory description panel
	
	#Implement skill usage outside of battle*
		#Implement skills being rearranged / sorted just like items

	Test menu memory more thoroughly and make it default ON

	Fix Quest system UI
		(selecting completed quests does not focus the first quest in the list)
		Focus still works a little weird

	Fix bug when player has selected defend and cancels out of targeting, attack is selected (should reselect defend)

	#Fix in-battle item/skill menu scroll container bug. This happens when there are enough buttons in the gridcontainer to allow scrolling. The initial position of the scroll container's vertical scroll position is set to a value other than 0 when opening the container the first time in battle. Further testing needed after attempting to fix...

	FIX when selected skills is in targeting and cancelled out of, skill selected in menu stays highlighted

	#Refactor the game menu UI so it is not one large script
		#maybe clean up the way it works a little, too

	#Implement ! and ? overhead for interactable objects and NPCs
	#	Check implementation in other project
	#	Disables during cutscenes, but pops up again afterwards

	#FIX cutscene actors pushing each other around when moving
	#	fixed, but may need later tweaking

	
#Create item/skill fields that can be parsed by battle_scene's textparser so it can be converted to a string for the battle notify UI to show

##Convert MP (Magic Points) to SP (Skill Points)
##Convert SPD (Speed) to AGI (Agility) (since SP and SPD are similar)

[Status Effects]
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
	#Attack up / down
	#Defense up / down
	#Magic up / down
	Berserk (do this later, not important)
