[Quest]: any task the player must complete. Can be explicitly given by an NPC or can be "found".


[Quest Step Types]:

	[Fetch]: Player must bring an item(s) somewhere / to someone.
		[Gather]: Player must accrue a number of a specific item.
			#example: Bring 5 apples to an NPC. Bring a specific found item to an NPC.
			[KillGather]: Kill enemies and bring back their loot.
				#example: Kill goblins and bring back 5 heads.
			[Tradeskill]: Player must craft items.
				#example: Craft 5 sharp sticks and bring them to the carpentry master.
		[Deliver]: NPC gives Player an item to give to another NPC. Type of fetch quest.

	[Kill]: Player must kill enemies.
		[Kill Boss]: Player must kill specific enemy.
			#example: Go kill the giant boar in the forest. There is only 1.
		[Kill Minor Enemies]: Player must kill a number of non-boss enemies.
			#example: Kill 10 goblins.
		[Kill All]: Player must kill a number of enemies and a boss.
			#example: Go to the dungeon and clear it out.
		[Capture]: Almost-kill, but use item/skill to incapacitate enemy.

	[Defense]: Player must defend someone / something.
		[Defend]: Player must defend a location or NPC from enemy attack.
			#example: Defend the town from bandits. Type of kill quest.
			#example: Defend the mage while they cast a spell. Type of kill quest.
		[Escort]: Player must escort an NPC to a location. Enemy attacks happen on the way. 
			#example: Little Red needs to get to Grandma's house. Help her get there.

	[Talking]: Player must seek out and speak to someone.
		#example: Go talk to the elder. He has more information.
	[Action]: Player must perform an action a number of times.
		#example: Run around the well 3 times.


[Quest Chains]: A series of quests. When one completes, another quest is started.
	#example: Main Story Quest. Epic Quests (like Everquest). Tutorial Quests.
		
