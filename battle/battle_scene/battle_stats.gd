@tool
class_name BattleStats
extends Control
##battle_stats.gd
##Window showing hp/mp of current party member
@onready var command_container : PanelContainer= %CommandContainer
@onready var stats_panel_container : PanelContainer = %StatsPanelContainer
@onready var button : Button = %Button
@onready var command_h_box : HBoxContainer = %CommandHBox
@onready var hp_value : Label = %HPValue
@onready var hp_progress_bar : ProgressBar = %HPProgressBar
@onready var mp_value : Label = %MPValue
@onready var mp_progress_bar : ProgressBar = %MPProgressBar
@onready var command_flasher : PanelContainer = %CommandFlasher
@onready var command_container_container : PanelContainer = %CommandContainerContainer
@onready var battle_scene_container : PanelContainer = %BattleSceneContainer
@onready var attack_button : CommandButton = %AttackButton
@onready var skill_button : CommandButton = %SkillButton
@onready var defend_button : CommandButton = %DefendButton
@onready var item_button : CommandButton = %ItemButton
@onready var run_button : CommandButton = %RunButton
@onready var animation_player : AnimationPlayer = %AnimationPlayer

#toggles command container visibility
@export var show_commands : bool = false : set = set_show_commands

var battle_scene : BattleScene = null
#Party member to be represented by the window
var member : PartyMemberData = null
var battler : Battler = null
var last_command_button_selected : CommandButton
var last_enemy_selected : Battler = null
var last_skill_selected : String = ""
var last_item_selected : InventorySlot = null



var attack_action : BattleAction = null
var defend_action : BattleAction = null
var run_action : BattleAction = null


const ATTACK = preload("uid://sw7qauqi57bl") #icon
const DEFEND = preload("uid://dsddu45iui2g8") #icon
const ITEM = preload("uid://khupsuwtpksw") #icon
const RUN = preload("uid://pyut5kkgk1wd") #icon
const SKILL = preload("uid://dxepja5wakufl") #icon




func _ready() -> void:
	_apply_show_commands()

	if Engine.is_editor_hint():
		return
	show_commands = false #for runtime
	last_command_button_selected = attack_button
	_apply_show_commands()
	command_flasher.visible = true
	button.pressed.connect(button_pressed)
	button.focus_entered.connect(focused)
	button.focus_exited.connect(unfocused)
	attack_button.command_button_pressed.connect(attack_button_pressed)
	skill_button.command_button_pressed.connect(skill_button_pressed)
	defend_button.command_button_pressed.connect(defend_button_pressed)
	item_button.command_button_pressed.connect(item_button_pressed)
	run_button.command_button_pressed.connect(run_button_pressed)
	
	

#region Button Functions
func button_pressed()->void:
	battle_scene.command_controller.on_party_pressed(battler)
	pass


##Opens targeting selection for attack (anyone)
func attack_button_pressed()->void:
	battle_scene.command_controller.open_attack_targeting(battler, attack_action)
	pass

##Shows the skill window within BattleScene. Passes member as argument to fill out the skills that can be selected.
func skill_button_pressed()->void:
	battle_scene.command_controller.show_skill_window(battler)
	pass
	
#func skill_button_pressed() -> void:
	#if battler == null or battler.actor_data == null:
		#return
	#var list = battler.actor_data.skills
	#if list.is_empty():
		#GameMenu.play_error_sound()
		#return
	#battle_scene.command_controller.begin_use_skill(battler, list[0])

	
##Opens targeting selection (party only)
func defend_button_pressed()->void:
	battle_scene.command_controller.open_defend_targeting(battler, defend_action)
	pass
	
##Opens BattleScene item menu.
func item_button_pressed()->void:
	battle_scene.command_controller.show_item_window(battler)
	pass

#
###Attempts to run from battle
#func run_button_pressed()->void:
	#var runner = battle_scene.acting_battler
	#var controller = battle_scene.command_controller
	#var turn_id = controller.current_turn_id
	#var use = ActionUse.new(runner, run_action, [])
	#if runner.ui_element is BattleStats:
		#runner.ui_element.show_commands = false
	#controller.action_use_chosen.emit(turn_id, use)
	
func run_button_pressed()->void:
	if run_action == null:
		GameMenu.play_error_sound()
		return
	battle_scene.command_controller.attempt_to_run(battler, run_action)
	
func focused()->void:
	animation_player.play("flash")
	pass
	
func unfocused()->void:
	animation_player.play("RESET")
	pass

func activate_button()->void:
	button.disabled = false

func deactivate_button()->void:
	button.disabled = true


#Grabs button focus
func grab_button_focus()->void:
	button.grab_focus()

##Enables all command buttons so they can be selected by the normal UI functions
func activate_all_command_buttons()->void:
	for child in command_h_box.get_children():
		if child is CommandButton:
			child.activate_button()

##Disables all command buttons so they cannot be selected by the normal UI functions
func deactivate_all_command_buttons()->void:
	for child in command_h_box.get_children():
		if child is CommandButton:
			child.deactivate_button()


#endregion Button Function


#region Setup
##Uses member.class color to set border colors
func set_class_color()->void:
	if member != null:
		stats_panel_container.self_modulate = member.class_color
		command_container.self_modulate = member.class_color

func setup_hpmp()->void:
	hp_value.text = str(member.current_hp)
	mp_value.text = str(member.current_mp)
	hp_progress_bar.max_value = member.get_max_hp()
	mp_progress_bar.max_value = member.get_max_mp()
	hp_progress_bar.value = member.current_hp
	mp_progress_bar.value = member.current_mp
	if_hp_mp_full_or_empty()
	
func set_attack_action()->void:
	for bact in battler.actor_data.battle_actions.battle_actions:
		if bact is BattleActionAttack:
			attack_action = bact
			break
func set_defend_action()->void:
	for bact in battler.actor_data.battle_actions.battle_actions:
		if bact is BattleActionDefend:
			defend_action = bact
			break

func set_run_action()->void:
	run_action = null
	for bact in battler.actor_data.battle_actions.battle_actions:
		if bact is BattleActionRun:
			run_action = bact
			break

#endregion Setup

#region Update Stats
##Makes HP/MP value a different color if they are full
func if_hp_mp_full_or_empty()->void:
	if member.current_hp == member.get_max_hp():
		hp_value.self_modulate = GameMenu.ENABLED_COLOR
	else:
		hp_value.self_modulate = GameMenu.WHITE_COLOR
	if member.current_mp == member.get_max_mp():
		mp_value.self_modulate = GameMenu.ENABLED_COLOR
	else:
		mp_value.self_modulate = GameMenu.WHITE_COLOR
	if member.current_hp == 0:
		hp_value.self_modulate = GameMenu.MINUS_COLOR
	if member.current_mp == 0:
		mp_value.self_modulate = GameMenu.MINUS_COLOR

##Updates label to new HP value and animates the bar to show it. Does not touch the actual HP value, only animates the UI
func hp_changed()->void:
	var new_hp := member.current_hp
	hp_value.text = str(new_hp)
	var tween := create_tween()
	tween.tween_property(hp_progress_bar, "value", new_hp, 0.3)
	await tween.finished
	if_hp_mp_full_or_empty()
	
##Updates label to new MP value and animates the bar to show it. Does not touch the actual MP value, only animates the UI
func mp_changed()->void:
	var new_mp := member.current_mp
	mp_value.text = str(new_mp)
	var tween := create_tween()
	tween.tween_property(mp_progress_bar, "value", new_mp, 0.3)
	await tween.finished
	if_hp_mp_full_or_empty()
	


#endregion Update Stats

#region Graphical Scene

#Instantiates battle scene
func update_battle_scene()->void:
	if member.battle_scene != null and member != null:
		for child in battle_scene_container.get_children():
			child.queue_free()
		await get_tree().process_frame
		var new_battle_scene = member.battle_scene.instantiate()
		battle_scene_container.add_child(new_battle_scene)
	else:
		if member == null:
			printerr("NO PARTY MEMBER DATA!!")
		else:
			if member.battle_scene == null:
				printerr(str(member.char_resource.char_name) + " HAS NO BATTLE SCENE SET!")

#region Selection

#endregion Selection


#region Command Container
## for us in editor
func set_show_commands(value: bool) -> void:
	show_commands = value
	_apply_show_commands()
## for use in editor
func _apply_show_commands() -> void:
	var container := _get_command_container()
	if container == null:
		return
	container.visible = show_commands

##For editor use
func _get_command_container() -> PanelContainer:
	# Setter can run before @onready has executed (especially in the editor).
	# Prefer the cached reference if it exists, otherwise resolve it on demand.
	if command_container_container != null:
		return command_container_container

	if not is_inside_tree():
		return null

	var n := get_node_or_null(^"%CommandContainerContainer")
	if n == null:
		return null

	command_container_container = n as PanelContainer
	return command_container_container

##Shows command container (runtime)
func show_command_container_container()->void:
	command_container_container.visible = true

##Hides command container (runtime)
func hide_command_container_container()->void:
	command_container_container.visible = false

##Sets up focus neighbors for command container
func setup_command_container_focus_neighbors()->void:
	var ilist := command_h_box.get_children()
	var count := ilist.size()
	for i in range(count):
		var child := ilist[i]
		var btn : Button = child.button
		var left_index := (i - 1 + count) % count
		var right_index := (i + 1) %count
		var left_btn : Button = ilist[left_index].button
		var right_btn : Button = ilist[right_index].button
		var self_path = btn.get_path()
		btn.focus_neighbor_top = self_path
		btn.focus_neighbor_bottom = self_path
		btn.focus_neighbor_left = left_btn.get_path()
		btn.focus_neighbor_right = right_btn.get_path()
		btn.focus_previous = left_btn.get_path()
		btn.focus_next = right_btn.get_path()
	
##Selects the last command button pressed. By default, is attack button.
##last_command_button_selected is set by the command button itself when pressed
func select_last_button()->void:
	last_command_button_selected.grab_focus()
	
func setup_commands()->void:
	pass

#endregion Command Container
