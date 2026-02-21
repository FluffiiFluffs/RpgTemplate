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
@onready var notify_label : Label = %NotifyLabel
##Node for keeping scripts that calculate things in battle so this script doesn't get too big.
@onready var action_calculator : ActionCalculator = %ActionCalculator
@onready var action_resolver : ActionResolver = %ActionResolver
@onready var command_controller : CommandController = %CommandController
@onready var status_system : StatusSystem = %StatusSystem
@onready var turn_manager : TurnManager = %TurnManager
@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var vic_def_label : Label = %VicDefLabel
@onready var skill_grid_container : GridContainer = %SkillGridContainer
@onready var item_grid_container : GridContainer = %ItemGridContainer
@onready var text_parser: TextParser = %TextParser
@onready var battle_vfx: BattleVFX = %BattleVFX



@export_enum(
"SETUP", #Initial battle setup (variable setup)
"INTRO_FADE_IN", #Graphical fade in (maybe don't need this)
"INTRO_MESSAGE", #Enemy introduction messaging
"ROUND_SETUP", #When a new round is being setup
"BATTLER_TURN", #Setup phase for the next battler's turn
"ACTION_EXECUTE", #Action is being executed (enemy or party)
"TURN_END",
"ROUND_END",
"BATTLE_END"

) 
var battle_state : String = ""


@export_enum(
"ACTION_SELECT", #During Action selection
"ATTACK_TARGETING", #During attack targeting
"DEFEND_TARGETING", #During defend targeting
"SKILL_MENU_OPEN", #Skill menu is open
"SKILL_TARGETING", #During skill targeting
"ITEM_MENU_OPEN", #Item Menu is open
"ITEM_TARGETING", #During item targeting
"NOTIFYING", #When messages are playing

) 
var ui_state : String = ""

var enemy_group : EnemyGroup = null #EnemyGroup taken from the enemy touched by the player
var turn_order : Array[Battler] = [] #turn order array 
var last_battler : Battler = null #last battler that had an action
var acting_battler : Battler = null #current acting battler
var next_battler : Battler = null #next battler that will take action
var targeted_battler : Battler = null #battler being targeted by an action
var exp_earned : int = 0
var money_earned : int = 0
var loot_earned : Array[Item] = []
#var total_actors : int = 0
#var round_count : int = 0

const BATTLE_STATS = preload("uid://due5rm071mmh6")
const BATTLE_SKILL_BUTTON = preload("uid://g7x34slwkxk8")
const BATTLE_ITEM_BUTTON = preload("uid://m4s138hk416n")
const BATTLEACTION_SKILL = preload("uid://dmtmbb2d7605b")
const BATTLEACTION_ITEM = preload("uid://c6yb8mxic4rg4")


@warning_ignore("unused_signal")
signal turn_finished
signal notify_finished

func _ready()->void:
	#button.pressed.connect(_on_button_pressed) #Victory button for testing.
	clear_placeholders()
	set_references_self()
	set_initial_visibility()
	
##Sets initial visibility of UI elements (in the event they were hidden in the editor during editing)
func set_initial_visibility()->void:
	item_window.visible = false
	skill_window.visible = false
	battle_notify_ui.visible = true
	battle_turn_ui.visible = true
	$BattleUI/BattlePartyUI.visible = true
	
	
#func _on_button_pressed()->void:
	#SceneManager.main_scene.end_battle_victory_normal()

##calls queue_free() on all nodes being used as placeholders within the editor during ready.
func clear_placeholders()->void:
	#clears turn order UI
	battle_turn_ui.clear_turn_order_ui()
	
	#clears any battlers
	for child in battlers.get_children():
		if child is Battler:
			child.free()
			#child.queue_free()

	#clears the turn order array
	turn_order.clear()
	
	#clears enemies
	for child in enemy_h_box.get_children():
		if child is BattleEnemy:
			child.free()
			#child.queue_free()
			
	#clears party's battlestats
	if !party_h_box.get_children().is_empty():
		for child in party_h_box.get_children():
			child.free()
			#child.queue_free()
	
	#clears the notify label's text
	notify_label.text = ""
	
	#clears placeholders within skill window
	for child in skill_grid_container.get_children():
		child.queue_free()
	
	#clears placeholders within item window
	for child in item_grid_container.get_children():
		child.queue_free()

#region Initial Battle Setup
func setup_all()->void:

	battle_state = "SETUP" #sets battle state
	new_randomize_seed() #New global randomize seed
	battlers.make_battlers() #Instantiates battlers from data
	check_tie_rolls() #Ensures no battlers have the same tie_roll value
	setup_party() #Instantiates party's battle stats and graphics
	setup_enemies() #Instantiates enemy's graphics
	hide_party_commands()
	await get_tree().process_frame #Waits a frame for safety
	#show_intro_message() #done from main due to the await for transition to end
	#round_next_setup() #done from main due to the await for transition to end

##Sets up party stats BattleStats windows. Data is from CharDataKeeper
##Also (should eventually) show the party member's in-battle graphics scene
func setup_party()->void:

	#instantiate BattleStats as children under party_h_box for all party members
	for child in CharDataKeeper.party_members:
		var new_battle_stats = BATTLE_STATS.instantiate() as BattleStats
		new_battle_stats.member = child #for easy reference
		party_h_box.add_child(new_battle_stats)
		new_battle_stats.set_class_color() #sets up the class colors for each party member's box
		new_battle_stats.setup_hpmp()
		new_battle_stats.update_battle_scene() #Updates the graphics for the party member
		new_battle_stats.name = str(new_battle_stats.member.get_display_name()) + "StatsBox" #Naming like this should be okay since party members will be unique
		new_battle_stats.setup_command_container_focus_neighbors()
	for bat in battlers.get_children():
		if bat is Battler:
			var batdata = bat.actor_data
			for child in party_h_box.get_children():
				if child is BattleStats:
					if child.member == batdata:
						bat.ui_element = child
						bat.ui_element.battler = bat
						bat.ui_element.battle_scene = self
						bat.ui_element.deactivate_button()
						child.set_defend_action()
						child.set_run_action()

##Sets up enemy visuals (make battlers should has already taken care of data setup)
##Scene pulled from battler.battler_scene
func setup_enemies()->void:
	for child in battlers.get_children():
		if child is Battler:
			if child.faction == Battler.Faction.ENEMY:
				var new_enemy_scene = child.battler_scene.instantiate()
				enemy_h_box.add_child(new_enemy_scene)
				child.ui_element = new_enemy_scene #ALERT this doesn't seem right, the UI element for the party is BattleStats but the UI element for the enemy is BattleEnemy. Both contain the graphical representation of their battler...
				new_enemy_scene.battler = child
				new_enemy_scene.battle_scene = self
				new_enemy_scene.deactivate_button()
				
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

#
##Shows the intro message for the battle. Intro message changes for how many enemies are in the enemy_group. Picks a random enemy's name as the "leader".
func show_intro_message()->void:
	await action_resolver.show_intro_message()
	
##Hides all top level commands for the party members.
func hide_party_commands()->void:
	for child in party_h_box.get_children():
		if child is BattleStats:
			child.show_commands = false



##Fills out references to the battle scene in its child nodes' scripts so they can function correctly.
func set_references_self()->void:
	action_calculator.battle_scene = self
	action_resolver.battle_scene = self
	command_controller.battle_scene = self
	status_system.battle_scene = self
	battle_vfx.battle_scene = self
	text_parser.battle_scene = self
	turn_manager.battle_scene = self
	battle_turn_ui.battle_scene = self
	battle_notify_ui.battle_scene = self

	pass

##Creates new global randomize seed so random calls are not exactly the same each battle (for safety)
func new_randomize_seed()->void:
	randomize()

#endregion Initial Battle Setup


#region Turn Order
##Updates the turn order UI (calls function of same name from battle_turn_ui node's script)[br]
##clears turn order UI box[br]
##Instantiates new turn_order_box (in order) from battle_scene.turn_order[]
func update_turn_order_ui()->void:
	battle_turn_ui.update_turn_order_ui()
#endregion Turn Order


#region End Of Battle
##Plays end of battle victory sequence for normal battles
func end_of_battle_normal_victory()->void:
	battle_state = "BATTLE_END"
	ui_state = "NOTIFYING"
	battle_notify_ui.queue_notification("VICTORY!")
	play_victory_swipe()
	give_money()
	give_xp()
	give_items()
	await notify_finished
	#CharDataKeeper.check_for_level_ups()
	#CharDataKeeper.get_level_up_differences()
	
	
	
	SceneManager.main_scene.end_battle_victory_normal()
	pass

func end_of_battle_special()->void:
	pass

##Plays end of battle defeat sequence for normal battles
func end_of_battle_normal_defeat()->void:
	pass
	
func end_of_battle_special_defeat()->void:
	pass

##Gives experience to the party per each enemy killed
func give_xp()->void:
	if exp_earned == 0:
		return

	for bat in battlers.get_children():
		if bat is Battler:
			if bat.faction == Battler.Faction.PARTY:
				if bat.actor_data.current_hp > 0:
					bat.actor_data.current_exp = bat.actor_data.current_exp + exp_earned
					bat.actor_data.total_exp = bat.actor_data.total_exp + exp_earned

	battle_notify_ui.queue_notification("Gained " + str(exp_earned) + " experience.")

	if CharDataKeeper != null:
		## This refreshes next_level_exp and applies level ups, queuing notifications via main.current_battle_scene
		CharDataKeeper.process_party_level_ups(true)



	pass
	
##Moves money accumulated during battle to the player[br]
##Needs to have the word for money changed to whatever it is called in the world (zenny, gil, gold, etc)
func give_money()->void:
	if money_earned != 0:
		SaveManager.money += money_earned
		battle_notify_ui.queue_notification("Found " + str(money_earned) + " money.")
	pass

##Gives items that were gained in battle
##TODO This script currently assumes a quantity of 1 per each item, but should probably be changed later (likely will need dictionary support from the loot_earned variable instead of it being an array)
func give_items()->void:
	if !loot_earned.is_empty():
		for it in loot_earned:
			Inventory.add_item(it.item_id, 1)
			battle_notify_ui.queue_notification(it.name + " was found.")
			
			
func play_victory_swipe()->void:
	vic_def_label.text = "VICTORY!"
	animation_player.play("vicdef_show")
	await animation_player.animation_finished
	pass
	
func play_defeat_swipe()->void:
	vic_def_label.text = "DEFEAT!"
	animation_player.play("vicdef_show")
	pass
#endregion End of Battle


#region Input
##Detected inputs during battle should ONLY be handled here (in battle_scene). Children nodes/scripts should be called from this point!
func _unhandled_input(_event):
	if Input.is_action_just_pressed("cancel_input"):
		match ui_state:
			"ACTION_SELECT":
				#do nothing, it's the top level
				ui_state = "ACTION_SELECT"
				pass
			"ATTACK_TARGETING":
				disable_all_ui_element_buttons()
				#go back to action select (focus current battler's last command selected)
				go_back_to_action_select()
				pass
			"DEFEND_TARGETING":
				#disable all ui_element.buttons
				disable_all_ui_element_buttons()
				go_back_to_action_select()
				pass
			"SKILL_MENU_OPEN":
				#Close the skill menu
				skill_window.visible = false
				go_back_to_action_select()
				pass
			"SKILL_TARGETING":
				disable_all_ui_element_buttons()

				if skill_window.visible:
					go_back_to_skill_select()
				else:
					go_back_to_action_select()
				pass
			"ITEM_MENU_OPEN":
				#hide the item menu
				item_window.visible = false
				go_back_to_action_select()
				pass
			"ITEM_TARGETING":
				#disable all ui_element.buttons
				disable_all_ui_element_buttons()
				#reopen item menu
				go_back_to_item_select()
				pass
			"NOTIFYING":
				#allow user to skip the notify message to the next
				battle_notify_ui.skip_notify()
				#allow other parts of the system to change the state, only skip the message shown
				pass

#region cancel_input Behaviors
##Sets all ui_element.button.disabled to true so they cannot be accidentally selected
func disable_all_ui_element_buttons()->void:
	for child in battlers.get_children():
		if child is Battler:
			child.ui_element.button.disabled = true
	get_viewport().gui_release_focus()
	
##Returns user to action selection
func go_back_to_action_select()->void:
	(acting_battler.ui_element as BattleStats).focus_last_command_button()
	ui_state = "ACTION_SELECT"

##Returns user to skill selection
func go_back_to_skill_select()->void:
	(acting_battler.ui_element as BattleStats).focus_last_skill_button()
	clear_all_is_active(skill_grid_container)
	ui_state = "SKILL_MENU_OPEN"

##Returns user to item selection
func go_back_to_item_select()->void:
	(acting_battler.ui_element as BattleStats).focus_last_item_button()
	clear_all_is_active(item_grid_container)
	ui_state = "ITEM_MENU_OPEN"
	
func clear_all_is_active(gcontainer : GridContainer)->void:
	for child in gcontainer.get_children():
		child.is_active = false
#endregion cancel_input Behaviors
