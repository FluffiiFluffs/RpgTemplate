class_name EnemyData
extends ActorData

@export_category("Battle Options")
##Array of loot able to be had after battle
@export var loot_table : Array[LootDrop]
##Array of loot able to be stolen during battle
@export var steal_table : Array[LootDrop]
##Money given when enemy is killed (in battle)
@export var money : int = 0
##Experience given when enemy is killed (in battle)
@export var experience : int = 0
##Multiplies the stats of the enemy in battle
@export var difficulty : float = 1.0
##AI routine for the enemy in battle
@export var ai : EnemyAI
