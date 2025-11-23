##quest_step_resource.gd
class_name QuestStep
extends Resource

##Name of the step
@export var step_name : String = ""
##Type of step
@export_enum("KILL", "GATHER", "DELIVER", "TALK", "ACTION", "ESCORT") var step_type : int = 1
##Tier level of monster to be killled
@export_enum("NONE", "MINION", "BOSS") var kill_tier : int = 0
##Specific race of enemy to be killed
@export_enum("NONE", "goblin", "wolf", "slime") var kill_race : int = 0 #needs to be a list of all races in the game...
##Type of item to be gathered
@export var item_name : String = ""
##name of NPC possibly used for who to talk or deliver to
@export var npc_name1 : String = "" 
##If second NPC is to be interacted during this step
@export var npc_name2 : String = "" 

##Description of the quest step
@export_multiline var description : String = ""
##How many actions are needed to complete the quest step.
@export var actions_needed : int = 1 #How many items, how many kills, how many actions
##How many times action_needed has been performed
@export var actions_taken : int = 0
##If the quest step is completed
@export var is_completed : bool = false
##Experience rewarded on step completion
@export var reward_exp : int = 0
##Money rewarded on step completion
@export var reward_money : int = 0
##Items rewarded on step completion
@export var reward_items : Array = []

#region my original code
#func _reset()->void:
	#is_completed = false
	#actions_taken = 0
#endregion
