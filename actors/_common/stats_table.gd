class_name StatsTable
extends Resource

##Resource for defining the stats of a party member at a given level
##Does not define HP, MP, ATK, DEF, MATK, MDEF. These are derived stats.


@export var strength : Array[int] = []
@export var stamina : Array[int] = []
@export var agility : Array[int] = []
@export var magic : Array[int] = []
@export var luck : Array[int] = []
