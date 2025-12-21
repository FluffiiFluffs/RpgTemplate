class_name BattleManager
extends Node2D
#battle_manager.gd
#attached to BattleRoot in main.tscn




var enemy_group : EnemyGroup = null
var round_count : int = 0
var acting_actor : Actor = null
var next_actor : Actor = null
var round_order : Array[Actor] = []



func start_battle(egroup : EnemyGroup)->void:
	#play transition
	#disable camera
	
	enemy_group = egroup #record the enemy group
	#stop processing on main.field_root
	#instantiate battle scene
	#place enemies
	#place party
	#determine turn order
	#fill UI
	
	#change game state
	pass
