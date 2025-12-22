class_name BattleScene
extends Node2D
@onready var button : Button = %Button
@onready var party_h_box : HBoxContainer = %PartyHBox
@onready var battle_turn_v_box : VBoxContainer = %BattleTurnVBox
@onready var battle_camera_rig : BattleCameraRig = %BattleCameraRig
@onready var battlers : Node = %Battlers

var enemy_group : EnemyGroup = null
var total_actors : int = 0
var turn_order_array : Array[Battler] = []
var round_count : int = 0
var acting_battler : Battler = null
var next_battler : Battler = null

const BATTLE_STATS = preload("uid://due5rm071mmh6")

const BATTLER = preload("uid://cjqlo5m6a50x2")

func _ready()->void:
	button.pressed.connect(_on_button_pressed)
	
	
func _on_button_pressed()->void:
	SceneManager.main_scene.end_battle_victory_normal()

func setup_all()->void:
	setup_party()
	setup_enemies()
	calc_turn_order()
	update_turn_order_ui()

func setup_party()->void:
	if !party_h_box.get_children().is_empty():
		for child in party_h_box.get_children():
			child.queue_free()
	#instantiate BattleStats as children under party_h_box for all party members
	for child in CharDataKeeper.party_members:
		var new_battle_stats = BATTLE_STATS.instantiate() as BattleStats
		new_battle_stats.member = child #for easy reference
		party_h_box.add_child(new_battle_stats)
		new_battle_stats.set_class_color() #sets up the class colors for each party member's box
		new_battle_stats.setup_hpmp()

func setup_enemies()->void:
	pass
##Calculates the turn order when the amount 
func calc_turn_order()->void:
	pass
	
func make_battlers()->void:
	for child in battlers.get_children():
		child.queue_free()
	for child in CharDataKeeper.party_members:
		var new_battler : Battler = BATTLER.instantiate()
		new_battler.actor_data = child
		if child.battle_scene != null:
			new_battler.actor_battle_scene = child.battle_scene
		else:
			printerr(name +": " + str(child.char_resource.name) + "No Battle Scene!")
		if child.battle_icon != null:
			new_battler.actor_battle_icon = child.battle_icon
		else:
			printerr(name +": " + str(child.char_resource.name) + "No Battle Icon!")
		battlers.add_child(new_battler)
	if enemy_group.enemies.is_empty():
		printerr(name +": " + "enemy_group is empty!!")
	else:
		for child in enemy_group.enemies:
			var new_battler : Battler = BATTLER.instantiate()
			new_battler.actor_data = child
			if child.battle_scene != null:
				new_battler.actor_battle_scene = child.battle_scene
			else:
				printerr(name +": " + str(child.char_resource.name) + "No Battle Scene!")
			if child.battle_icon != null:
				new_battler.actor_battle_icon = child.battle_icon
			else:
				printerr(name +": " + str(child.char_resource.name) + "No Battle Icon!")	
			battlers.add_child(new_battler)

func update_turn_order_ui()->void:
	#clears the turn order UI box so it can be freshly updated
	for child in battle_turn_v_box.get_children():
		child.queue_free()
	for i in turn_order_array:
		pass
