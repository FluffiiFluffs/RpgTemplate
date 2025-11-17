##Global Script for keeping track of each playable character's stats, equipment etc
##charadata_keeper.gd
##As with normal RPG convention, Slot00 is the currently controlled character, set by player_character.gd on load
extends Node2D

const PLAYER_CHARACTER = preload("uid://bita6dnrj87wq")
const NPC = preload("uid://56kk082o8ck1")
const ENEMY = preload("uid://dt3hw6ocf2cl7")



@export var controlled_character_data:CharResource
@export var controlled_character:PlayerCharacter
@export_range(1, 4, 1) var party_size:int=4
@export var party_member_02 : NPC = null
@export var party_member_03 : NPC = null
@export var party_member_04 : NPC = null



@export var slot00 : CharResource = null #set in inspector
var slot00_in_party:bool=true
var slot00_faction:int=0
var slot00_name:String=""
var slot00_class:int=0
var slot00_level:int=1
var slot00_current_exp:int=0
var slot00_next_level_exp:int=100
var slot00_total_exp:int=0
var slot00_max_hp:int=100
var slot00_max_mp:int=50
var slot00_current_hp:int=100
var slot00_current_mp:int=50
var slot00_atk_value:int=10
var slot00_def_value:int=10
var slot00_strength:int=10
var slot00_speed:int=10
var slot00_stamina:int=10
var slot00_magic:int=10
var slot00_battle_actions:BattleActions
var slot00_headslot
var slot00_chestslot
var slot00_armslot
var slot00_legslot
var slot00_accy01
var slot00_accy02
var slot00_mainhand
var slot00_offhand
var slot00_2handing:bool=false


@export var slot01 : CharResource = null #set in inspector
var slot01_in_party:bool=false
var slot01_faction:int=0
var slot01_name:String=""
var slot01_class:int=0
var slot01_level:int=1
var slot01_current_exp:int=0
var slot01_next_level_exp:int=100
var slot01_total_exp:int=0
var slot01_max_hp:int=100
var slot01_max_mp:int=50
var slot01_current_hp:int=100
var slot01_current_mp:int=50
var slot01_atk_value:int=10
var slot01_def_value:int=10
var slot01_strength:int=10
var slot01_speed:int=10
var slot01_stamina:int=10
var slot01_magic:int=10
var slot01_battle_actions:BattleActions
var slot01_headslot
var slot01_chestslot
var slot01_armslot
var slot01_legslot
var slot01_accy01
var slot01_accy02
var slot01_mainhand
var slot01_offhand
var slot01_2handing:bool=false

@export var slot02 : CharResource = null #set in inspector
var slot02_in_party:bool=false
var slot02_faction:int=0
var slot02_name:String=""
var slot02_class:int=0
var slot02_level:int=1
var slot02_current_exp:int=0
var slot02_next_level_exp:int=100
var slot02_total_exp:int=0
var slot02_max_hp:int=100
var slot02_max_mp:int=50
var slot02_current_hp:int=100
var slot02_current_mp:int=50
var slot02_atk_value:int=10
var slot02_def_value:int=10
var slot02_strength:int=10
var slot02_speed:int=10
var slot02_stamina:int=10
var slot02_magic:int=10
var slot02_battle_actions:BattleActions
var slot02_headslot
var slot02_chestslot
var slot02_armslot
var slot02_legslot
var slot02_accy01
var slot02_accy02
var slot02_mainhand
var slot02_offhand
var slot02_2handing:bool=false

@export var slot03 : CharResource = null #set in inspector
var slot03_in_party:bool=false
var slot03_faction:int=0
var slot03_name:String=""
var slot03_class:int=0
var slot03_level:int=1
var slot03_current_exp:int=0
var slot03_next_level_exp:int=100
var slot03_total_exp:int=0
var slot03_atk_value:int=10
var slot03_def_value:int=10
var slot03_max_hp:int=100
var slot03_max_mp:int=50
var slot03_current_hp:int=100
var slot03_current_mp:int=50
var slot03_strength:int=10
var slot03_speed:int=10
var slot03_stamina:int=10
var slot03_magic:int=10
var slot03_battle_actions:BattleActions
var slot03_headslot
var slot03_chestslot
var slot03_armslot
var slot03_legslot
var slot03_accy01
var slot03_accy02
var slot03_mainhand
var slot03_offhand
var slot03_2handing:bool=false




func set_modified_data()->void:
	#when game is loaded from save, loads:
	#in_party flag
	#current_exp, next_level_exp, total_exp, level
	#max_hp, max_mp, current_hp, current_hp
	#Gear: headslot, chestslot, armslot, legslot, accy01, accy02, mainhand, offhand, sets 2 handing flag
	pass

##Adds stats from gear to base stats
func update_stats_from_gear()->void:
	pass


func _ready()->void:
	set_base_data()
	set_modified_data()
	update_stats_from_gear()
	#update_who_is_in_party()
	pass
	
func set_base_data()->void:
	slot00_faction = slot00.char_faction
	slot00_name = slot00.char_name
	slot00_class = slot00.char_class
	slot00_level = slot00.char_level
	slot00_max_hp = slot00.max_hp
	slot00_max_mp = slot00.max_mp
	slot00_atk_value = slot00.atk_value
	slot00_def_value = slot00.def_value
	slot00_strength = slot00.strength
	slot00_speed = slot00.speed
	slot00_stamina = slot00.stamina
	slot00_magic = slot00.magic
	slot00_battle_actions = slot00.battle_actions
	
	slot01_faction = slot01.char_faction
	slot01_name = slot01.char_name
	slot01_class = slot01.char_class
	slot01_level = slot01.char_level
	slot01_max_hp = slot01.max_hp
	slot01_max_mp = slot01.max_mp
	slot01_atk_value = slot01.atk_value
	slot01_def_value = slot01.def_value
	slot01_strength = slot01.strength
	slot01_speed = slot01.speed
	slot01_stamina = slot01.stamina
	slot01_magic = slot01.magic
	slot01_battle_actions = slot01.battle_actions
	
	
	slot02_faction = slot02.char_faction
	slot02_name = slot02.char_name
	slot02_class = slot02.char_class
	slot02_level = slot02.char_level
	slot02_max_hp = slot02.max_hp
	slot02_max_mp = slot02.max_mp
	slot02_atk_value = slot02.atk_value
	slot02_def_value = slot02.def_value
	slot02_strength = slot02.strength
	slot02_speed = slot02.speed
	slot02_stamina = slot02.stamina
	slot02_magic = slot02.magic
	slot02_battle_actions = slot02.battle_actions

	slot03_faction = slot03.char_faction
	slot03_name = slot03.char_name
	slot03_class = slot03.char_class
	slot03_level = slot03.char_level
	slot03_max_hp = slot03.max_hp
	slot03_max_mp = slot03.max_mp
	slot03_atk_value = slot03.atk_value
	slot03_def_value = slot03.def_value
	slot03_strength = slot03.strength
	slot03_speed = slot03.speed
	slot03_stamina = slot03.stamina
	slot03_magic = slot03.magic
	slot03_battle_actions = slot03.battle_actions
	
	
