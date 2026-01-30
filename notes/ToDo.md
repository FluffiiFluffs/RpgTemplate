Create item/skill fields that can be parsed by battle_scene's textparser so it can be converted to a string for the battle notify UI to show
Create quote bubble system for in-battle use

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
	
Refactor the game menu UI so it is not one large script
	maybe clean up the way it works a little, too

Implement skill usage outside of battle

Implement cutscenes

Implement save/load system
	Also implement persistence system between scenes for certain things like opening chests
	
Check DialogueManager code to try to figure out if some things implemented were already in place by default
	within the dialoguemanager addon (specifically the portrait thing)

Have a script go through the items folder to automatically add them to all_items instead of adding them directly, this should save a lot of time.

Implement ! and ? overhead for interactable objects and NPCs
