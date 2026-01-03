class_name BattleScene
extends Node2D
@onready var button : Button = %Button
@onready var party_h_box : HBoxContainer = %PartyHBox
@onready var battle_turn_ui : BattleTurnUI = %BattleTurnUI
@onready var battle_camera_rig : BattleCameraRig = %BattleCameraRig
@onready var battlers : Battlers = %Battlers
@onready var skill_window : PanelContainer = %SkillWindow
@onready var item_window : PanelContainer = %ItemWindow
@onready var enemy_h_box : HBoxContainer = %EnemyHBox
@onready var battle_notify_ui : BattleNotifyUI = %BattleNotifyUI

@export_enum(
"SETUP", #Initial battle setup (variable setup)
"INTRO_FADE_IN", #Graphical fade in (maybe don't need this)
"INTRO_MESSAGE", #Enemy introduction messaging
"ROUND_SETUP", #When a new round is being setup
"TURN_SETUP", #Setup phase for the next battler's turn
"ACTION_EXECUTE", #Action is being executed (enemy or party)
"TURN_END",
"ROUND_END",

) 
var battle_state : String = ""


@export_enum(
"ACTION_SELECT", #During action selection for battler
"ACTION_TARGETING", #During targeting state (for actions, skills, items)
"SKILL_MENU_OPEN", #Skill menu is open
"ITEM_MENU_OPEN", #Item Menu is open
"NOTIFYING",
) 
var ui_state : String = ""

var enemy_group : EnemyGroup = null
var total_actors : int = 0
var turn_order : Array[Battler] = []
var round_count : int = 0
var last_battler : Battler = null
var acting_battler : Battler = null
var next_battler : Battler = null

const BATTLE_STATS = preload("uid://due5rm071mmh6")


func _ready()->void:
	button.pressed.connect(_on_button_pressed)
	
func _on_button_pressed()->void:
	SceneManager.main_scene.end_battle_victory_normal()


#region Initial Battle Setup
func setup_all()->void:
	battle_state = "SETUP"
	new_randomize_seed()
	battlers.make_battlers()
	check_tie_rolls()
	setup_party()
	setup_enemies()
	await get_tree().process_frame
	sort_turn_order()
	update_turn_order_ui()
	show_intro_message()

##Sets up party stats BattleStats windows. Data is from CharDataKeeper
##Also (should eventually) show the party member's in-battle graphics scene
func setup_party()->void:
	##Gets rid of preexisting editor entries
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
		new_battle_stats.update_battle_scene() #Updates the graphics for the party member
		new_battle_stats.name = str(new_battle_stats.member.char_resource.char_name) + "StatsBox" #Naming like this should be okay since party members will be unique

##Sets up enemy visuals (make battlers should has already taken care of data setup)
##Scene pulled from battler.battler_scene
func setup_enemies()->void:
	for child in enemy_h_box.get_children():
		child.queue_free()
	await get_tree().process_frame
	for child in battlers.get_children():
		if child is Battler:
			if child.faction == Battler.Faction.ENEMY:
				var new_enemy_scene = child.battler_scene.instantiate()
				enemy_h_box.add_child(new_enemy_scene)
				
				pass
	pass

##Ensures that all battler's tie_rolls are unique
##If found to be the same, the while function rolls a new random integer until it is different
##The while portion of this function is very unlikely to be needed, but exists for safety
func check_tie_rolls()->void:
	var used_rolls : Dictionary = {}
	for battler in turn_order:
		var roll : int = battler.tie_roll
		while used_rolls.has(roll):
			print("BATTLERS HAVE THE SAME TIE_ROLL! ROLLING NEW VALUE!")
			roll = randi()
		used_rolls[roll] = true
		battler.tie_roll = roll
		
func show_intro_message()->void:
	var enemy_array : Array[Battler] = []
	var enemy_name : String = ""
	var randmindex : int = 0
	var rmessages : Array[String] = []
	for bat in battlers.get_children():
		if bat.faction == Battler.Faction.ENEMY:
			enemy_array.append(bat)
			
	var renemyindex : int = randi_range(0, enemy_array.size() - 1)
	enemy_name = enemy_array[renemyindex].actor_data.char_resource.char_name
	randmindex = randi_range(0, rmessages.size() - 1)
	
	if enemy_array.size() == 1: #if there's only one enemy
		rmessages = [
		enemy_name + " approaches.",
		enemy_name + " suddenly attacks.",
		enemy_name + " moves forward aggressively!",
		]
		randmindex = randi_range(0, rmessages.size() - 1)
	elif enemy_array.size() > 1: #if there's more than one enemy

		rmessages = [
		enemy_name + " and its allies approach!",
		enemy_name + " and cohorts suddenly attack!",
		enemy_name + " and others moves forward aggressively!",
		]
		randmindex = randi_range(0, rmessages.size() - 1)
	
	var rand_message : String = rmessages[randmindex]
	
	battle_notify_ui.queue_notification(rand_message)
	await battle_notify_ui.notify_final_end
	
	##Trigger first turn
	print("starting first turn")
	pass



#endregion Initial Battle Setup

		
#region Turn Order
##Clears turn_order[] of all entries
func clear_turn_order()->void:
	turn_order.clear()

##Sorts turn order array based on speed, stamina, current hp, and then tie_roll
##calls compare_battlers_for_turn_order within sort_custom()
func sort_turn_order()->void:
	clear_turn_order()
	battlers.add_battlers_to_turn_order()

	remove_dead_from_turn_order()
	turn_order.sort_custom(self.compare_battlers_for_turn_order)
	
##Removes dead battlers from turn_order array
func remove_dead_from_turn_order()->void:
	for i in range(turn_order.size() -1, -1, -1):
		var bat = turn_order[i]
		if bat == null:
			turn_order.remove_at(i)
			continue
		
		if bat.actor_data.current_hp <= 0:
			turn_order.remove_at(i)
		#status conditions should keep the actor in the turn_order array, so don't do that here


	
##Returns true if first battler should be placed before second battler in turn_order[]
##Speed > Stamina > HP > tie_roll
##Tie roll is guaranteed to be unique via check_tie_rolls()
func compare_battlers_for_turn_order(first : Battler, second : Battler)->bool:
	#print("SORTING")`
	var first_speed = first.actor_data.get_speed()
	var second_speed = second.actor_data.get_speed()
	if first_speed != second_speed:
		return first_speed > second_speed
	
	var first_stamina = first.actor_data.get_stamina()
	var second_stamina = second.actor_data.get_stamina()
	if first_stamina != second_stamina:
		return first_stamina > second_stamina
	
	var first_hp = first.actor_data.current_hp
	var second_hp = second.actor_data.current_hp
	if first_hp != second_hp:
		return first_hp > second_hp
	
	
	return first.tie_roll > second.tie_roll

##Updates the turn order UI (calls function of same name from battle_turn_ui node's script)[br]
##clears turn order UI box[br]
##Instantiates new turn_order_box (in order) from battle_scene.turn_order[]
func update_turn_order_ui()->void:
	battle_turn_ui.update_turn_order_ui()


##Creates new global randomize seed so random calls are not exactly the same each battle (for safety)
func new_randomize_seed()->void:
	randomize()

##for debugging
#func print_turn_order()->void:
	#return
	#print(str(turn_order))
	#for bat in turn_order:
		#print(str(bat.tie_roll) + " " +str(bat.name))

#endregion Turn Order


func battler_turn_next()->void:
	if turn_order.size() != 0: #if there's still battler's in turn_order[]
		acting_battler = turn_order[0]
		next_battler = turn_order[1]
		pass
	else: #if there's no more battlers in turn_order[]
		#setup next round	
		pass


func battler_turn_done()->void:
	turn_order.pop_front() #get rid of the current battler turn_order[]
	update_turn_order_ui()
	#determines if all party is dead, if so game over
	#determines if all enemies are dead, if so, victory
	#calls battler_turn_next()
	pass

func round_next_setup()->void:
	battle_state = "ROUND_SETUP"
	sort_turn_order() #clears turn_order[], adds battlers to turn_order[]
	update_turn_order_ui() #updates the UI to show the 
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
