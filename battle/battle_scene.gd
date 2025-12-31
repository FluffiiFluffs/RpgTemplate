class_name BattleScene
extends Node2D
@onready var button : Button = %Button
@onready var party_h_box : HBoxContainer = %PartyHBox
@onready var battle_turn_v_box : VBoxContainer = %BattleTurnVBox
@onready var battle_camera_rig : BattleCameraRig = %BattleCameraRig
@onready var battlers : Node = %Battlers
@onready var skill_window : PanelContainer = %SkillWindow
@onready var item_window : PanelContainer = %ItemWindow

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
	make_battlers()
	setup_party()
	setup_enemies()
	calc_turn_order()
	update_turn_order_ui()
	

##Sets up party stats BattleStats windows. Data is from CharDataKeeper
##Also (should eventually) show the party member's in-battle graphics scene
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

##Sets up enemy visuals (make battlers should has already taken care of data setup)
##Scene pulled from battler.battler_scene
func setup_enemies()->void:
	pass
##Calculates the turn order when the amount 
func calc_turn_order()->void:
	pass
	
func make_battlers()->void:
	for child in battlers.get_children():
		child.queue_free()
	await get_tree().process_frame
	for child in CharDataKeeper.party_members:
		var new_battler : Battler = BATTLER.instantiate()
		new_battler.actor_data = child
		if child.battle_scene != null:
			new_battler.battler_scene = child.battle_scene
		else:
			printerr(name +": " + str(child.char_resource.char_name) + " No Battle Scene!")
		if child.battle_icon != null:
			new_battler.battler_icon = child.battle_icon
		else:
			printerr(name +": " + str(child.char_resource.char_name) + " No Battle Icon!")
		battlers.add_child(new_battler)
		new_battler.name = child.char_resource.char_name
		new_battler.faction = Battler.Faction.PARTY
	
	if enemy_group.enemies.is_empty():
		printerr(name +": " + "enemy_group is empty!!")
	else:
		for child in enemy_group.enemies:
			var new_battler : Battler = BATTLER.instantiate()
			new_battler.actor_data = child.duplicate()
			battlers.add_child(new_battler)
			if child.battle_scene != null:
				new_battler.battler_scene = child.battle_scene
			else:
				printerr(name +": " + str(child.char_resource.char_name) + " No Battle Scene!")
			if child.battle_icon != null:
				new_battler.battler_icon = child.battle_icon
			else:
				printerr(name +": " + str(child.char_resource.char_name) + " No Battle Icon!")
			new_battler.faction = Battler.Faction.ENEMY

func update_turn_order_ui()->void:
	#clears the turn order UI box so it can be freshly updated
	for child in battle_turn_v_box.get_children():
		child.queue_free()
	for i in turn_order_array:
		pass


func show_skill_window()->void:
	#propagate skills for current battler
	#show skill window
	#change battle state to skill selection
	pass
func hide_skill_window()->void:
	#hide skill window
	#change battle state should be handled by the action taken
		#if cancelled out, then go back to previous action selection state
		#if skill is used, then go into action playing state
			#consume the battler's turn
		pass

func show_item_window()->void:
	#propagate items list
	#show item window
	#change battle state to item window open
	pass

func hide_item_window()->void:
	#hide item window
	#change of battle state should be handled by action taken
		#if cancelled out, then go back to the previous action selection state
		#if item is used, then go into action playing state
			#consume the battler's turn
	pass
