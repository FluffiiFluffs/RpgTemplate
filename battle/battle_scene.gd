class_name BattleScene
extends Node2D
@onready var button : Button = %Button
@onready var party_h_box : HBoxContainer = %PartyHBox
@onready var battle_turn_v_box : VBoxContainer = %BattleTurnVBox

var enemy_group : EnemyGroup = null
var total_actors : int = 0
var turn_order_array : Array[ActorData] = []
var round_count : int = 0
var acting_actor : ActorData = null
var next_actor : ActorData = null


const BATTLE_STATS = preload("uid://due5rm071mmh6")


signal victory_button

func _ready()->void:
	button.pressed.connect(_on_button_pressed)
	
	
func _on_button_pressed()->void:
	victory_button.emit()
	pass


func setup_all()->void:
	setup_party()
	setup_enemies()
	calc_turn_order()
	update_turn_order_ui()

func setup_party()->void:
	#instantiate BattleStats as children under party_h_box for all party members
	for child in CharDataKeeper.party_members:
		var new_battle_stats = BATTLE_STATS.instantiate() as BattleStats
		new_battle_stats.member = child #for easy reference
		party_h_box.add_child(new_battle_stats)
		new_battle_stats.set_class_color() #sets up the class colors for each party member's box
		
		
	pass
func setup_enemies()->void:
	pass
##Calculates the turn order when the amount 
func calc_turn_order()->void:
	
	
	
	
	
	##it should probably update the ui every time 	
	##determines if there needs to be an update to the UI
	#total_actors = 0
	#for child in enemy_group:
		#total_actors += 1
	#for child in CharDataKeeper.party_members:
		#total_actors += 1
	#if battle_turn_v_box.get_children().size() < total_actors:
		#update_turn_order_ui()
		
	
	
	
	pass
func update_turn_order_ui()->void:
	#clears the turn order UI box so it can be freshly updated
	for child in battle_turn_v_box.get_children():
		queue_free()
	for i in turn_order_array:
		pass
		
	pass
	
