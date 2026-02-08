class_name HPSPMod
extends Resource
##Defines HP and SP mod per each level. This is the same for all party members. The intended use is for this to be placed in an export variable within CharDataKeeper




##HP Mod per level
##Level == place in the array + 1
@export var hp_mod : Array[int] = []
##SP Mod per level
##Level == place in the array + 1
@export var sp_mod : Array[int] = []

## HP = [stamina * (hp_mod * level) / 50]
var hp_divisor : int = 50
## SP = [magic * (sp_mod * level) / 100]
var sp_divisor : int = 100
