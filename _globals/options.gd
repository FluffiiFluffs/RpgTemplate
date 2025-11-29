##options.gd
##Global Script Options
extends Node2D


#region In-Game Options (for player)
@export_category("In-Game Options")
#volume
	#music
	#sfx
	#voices
#menu memory
	#menu
	#battle
#menu colors/style
#inventory sort order?
#controls
#current-game-stats (like how many enemies killed)
#walk_speed (always run?)
#message speed (need to make this a thing in dialogue manager)
	#should show example of how fast
#battle message speed

#load game
#exit game



@export_category("DIALOGUE")
## 0 : FULL = Speaking characters play their voice sound rapidly.[br]
## 1 : START = Speaking characters only play their voices at the beginning of text.[br]
## 2 : OFF = Speaking characters do not make sound.
@export_enum("FULL", "START", "OFF") var voices_type : int = 0
## 0 : TALKING = Speaking character portraits fully animate.[br]
## 1 : STILL = Speaking character portraits do not animate (but will show expression).
@export_enum("TALKING", "STILL") var portrait_type : int = 1
#endregion



#region Dev Options


#region Inventory Options
@export_category("INVENTORY")

##If true, another stack of the item will be made when it fills up
@export var multi_stacks : bool = true

#endregion

#endregion
