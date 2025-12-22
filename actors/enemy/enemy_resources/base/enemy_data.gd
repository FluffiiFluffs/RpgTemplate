class_name EnemyData
extends ActorData

@export_category("Battle Options")
@export var loot_table : Array[LootDrop]
@export var steal_table : Array[LootDrop]
@export var money : int = 0
@export var experience : int = 0
@export var difficulty : float = 1.0
