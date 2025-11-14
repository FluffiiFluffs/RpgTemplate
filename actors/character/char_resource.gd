class_name CharResource
extends Resource

@export_enum("PARTY", "NPC", "ENEMY", "BOSS") var char_faction:int
@export var char_name:String=""
@export_enum("WARRIOR","THIEF","MAGE","HEALER") var char_class:int
@export var char_sprite_sheet:Texture
@export var char_level:int=1
@export var current_exp:int=0
@export var max_hp:int=100
@export var max_mp:int=50
@export var atk_value:int=10
@export var def_value:int=10
@export var strength:int=10
@export var speed:int=10
@export var stamina:int=10
@export var magic:int=10
@export var battle_actions:BattleActions
