class_name LootDrop
extends Resource

@export var loot : Item = null
@export var chance : int = 100

func roll()->bool:
	var _rollval : float = randf_range(0,100)
	if _rollval <= chance:
		return true
	return false
