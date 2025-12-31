class_name CharResource
extends Resource

##What faction the actor is.[br]PARTY: Player's party (includes player)[br]NPC: Non-Aggressive NPC[br]ENEMY: Aggressive NPC
@export_enum("PARTY", "NPC", "ENEMY", "BOSS") var char_faction:int
##Name of the Actor
@export var char_name:String=""
##Class of the Actor
@export_enum("WARRIOR","THIEF","MAGE","HEALER") var char_class:int
##Default walk speed of the Actor
#@export var move_speed : float = 115.0 #ALERT To be transferred to scene!
##Sprite sheet of the Actor
#@export var char_sprite_sheet:Texture #ALERT To be transferred to scene!
##Sprite sheet used for battle
#@export var battle_sprite_sheet:Texture #ALERT To be transferred to scene!
###Sprite Used for stats page portrait
#@export var stats_sprite : Texture #ALERT Moved to party_member_data
##Default level of the actor
@export var char_level:int=1
##Default max_hp of the Actor. Modified by Stamina.
@export var max_hp:int=100
##Default max_mp of the Actor. Modified by Magic.
@export var max_mp:int=50
##Default atk_value of the Actor. Used to determine how much damage is done by a physical attack. Modified by Strength.
@export var atk_value:int=10
##Default def_value of the Actor. Used to determine how much a physical attack's damage is mitigated. Modified by Stamina.
@export var def_value:int=10
##Default strength of the Actor. Calculated into atk_value for physical attacks.
@export var strength:int=10
##Default speed of the Actor. Determines turn order in battle.
@export var speed:int=10
##Default Stamina of the Actor 
@export var stamina:int=10
##Default Magic of the Actor. Determines effectiveness of magic. 
@export var magic:int=10

#TODO Transfer to PartyMemberResource! Enemies should have their own array held in scene export!
##Array of default actions that can be taken in battle by the actor.
@export var battle_actions:BattleActions

#ALERT NO LONGER USED, held within enemy scene!
#@export_category("Enemy Specific")
###How an enemy will react to the player's presence.[br]Scared: Enemy will run when in alert range[br]Cautious: Enemy will chase when in alert range[br]Aggressive: Enemy will chase when in caution range
#@export_enum("SCARED", "CAUTIOUS", "AGGRESSIVE") var alert_type : int = 1
###Radius of see_range
#@export var see_range : float = 300.0
###Radius of caution range
#@export var caution_range : float = 250.0
###Radius of alert range.
#@export var alert_range : float = 100.0
###How fast the enemy will move in alert mode
#@export var alert_move_speed : float = 125.0


func _class_name()->String:
	match char_class:
		0:
			return "WARRIOR"
		1:
			return "THIEF"
		2:
			return "MAGE"
		3:
			return "HEALER"
		_:
			return ""
