class_name CommandController
extends Node
##command_controller.gd
##Figures out valid targets for an action and returns a chosen target list.
## Handles the player decision flow during a party member's turn.
## Shows or hides command UI, opens skill or item menus, runs targeting selection, and supports back or cancel.
## Produces a single ActionUse when the player's choice is confirmed and emits it for TurnManager to consume.
## Does not apply action effects and does not advance the battle loop.


var battle_scene : BattleScene = null
var pending_user : Battler = null
var pending_action : BattleAction = null
var current_turn_id : int = -1

signal action_use_chosen(turn_id : int, use : ActionUse)

#region TurnID
func begin_turn(turn_id : int)->void:
	current_turn_id = turn_id
#endregion TurnID

#region Command Button Functions
func open_attack_targeting(attacker : Battler, action : BattleAction)->void:
	pending_user = attacker
	pending_action = action
	
	battle_scene.ui_state = "ACTION_TARGETING"
	
	#Enables targeting (can target anyone, even self)
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.actor_data.current_hp > 0:
				bat.ui_element.activate_button()

	#If menu memory is on, targets last enemy selected. If it can't happen, then the first enemy is focused.
	if Options.battle_menu_memory:
		if pending_user.battler_scene.last_enemy_selected != null:
			if pending_user.ui_element.last_enemy_selected.actor_data.current_hp > 0:
				pending_user.ui_element.last_enemy_selected.grab_button_focus()
			else:
				target_first_enemy()
		else:
			target_first_enemy()
	else:
		target_first_enemy()

##Opens targeting, passes who is defending, and the defense action
func open_defend_targeting(defender : Battler, action : BattleAction)->void:
	pending_user = defender
	pending_action = action
	battle_scene.ui_state = "ACTION_TARGETING"
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			if bat.faction == Battler.Faction.PARTY:
				if bat.actor_data.current_hp > 0:
					bat.ui_element.activate_button()
				elif bat.actor_data.current_hp <= 0:
					bat.ui_element.deactivate_button()
				pass
			if bat.faction == Battler.Faction.ENEMY:
				bat.ui_element.deactivate_button()
				pass
	defender.ui_element.grab_button_focus() #focus the defender by default


##Button pressed function for when an enemy's button (selected) in battle.
##TODO This needs to be changed to support skills and items as well!
func on_enemy_pressed(target : Battler)->void:
	_confirm_action_attack([target])

	
func _confirm_action_attack(targets : Array[Battler])->void:
	var use = ActionUse.new(pending_user, pending_action, targets)
	for tar in targets:
		tar.ui_element.animation_player.play("RESET") #all battler ui elements should have this
	for bat in battle_scene.battlers.get_children():
		if bat is Battler:
			bat.ui_element.deactivate_button()
		if battle_scene.acting_battler.ui_element is BattleStats:
			battle_scene.acting_battler.ui_element.show_commands = false
	_end_targeting()
	if current_turn_id < 0:
		printerr("CommandController: current_turn_id not set for this turn")
		return
	action_use_chosen.emit(current_turn_id, use)


func _confirm_action_other()->void:
	for bat in  battle_scene.battlers.get_children():
		if bat is Battler:
			bat.ui_element.deactivate_button()
		if battle_scene.acting_battler.ui_element is BattleStats:
			battle_scene.acting_battler.ui_element.show_commands = false

##Sets pending_user and pending_action to null
func _end_targeting()->void:
	pending_user = null
	pending_action = null
	pass

##Shows skill window based upon the skills available to the party member
func show_skill_window(battler: Battler)->void:
	battle_scene.ui_state = "SKILL_MENU_OPEN"
	#propagate skills for current party member
	#show skill window
	#change battle state to skill selection
	pass
	
	
func hide_skill_window()->void:
	
	#hide skill window
	#change battle state should be handled depending on the UI action taken
		#if cancelled out, then go back to previous action selection state
		#if skill is used, then go into action playing state
			#consume the battler's turn
		pass



##Shows item list. Only shows battle-usable items.
func show_item_window()->void:
	battle_scene.ui_state = "ITEM_WINDOW_OPEN"
	#propagate items list
	#show item window
	#change battle state to item window open
	pass

func hide_item_window()->void:
	#hide item window
	#change of battle state should be handled depending on the UI action taken
		#if cancelled out, then go back to the previous action selection state
		#if item is used, then go into action playing state
			#consume the battler's turn
	pass

##Attempts to run from battle immediately. Uses PartyMember's stats to attempt this
func attempt_to_run(runner : Battler)->void:
	var run_action : BattleAction = battle_scene.BATTLEACTION_RUN
	if runner.ui_element is BattleStats:
		runner.ui_element.show_commands = false
	_end_targeting()
	if current_turn_id < 0:
		printerr("CommandController: current_turn_id not set for this turn")
		return
	action_use_chosen.emit(current_turn_id, ActionUse.new(runner, run_action, []))
	
	pass
#endregion Command Button Functions



#region Targeting


func setup_enemy_targeting(_hbox : HBoxContainer) -> void:
	var ilist := battle_scene.enemy_h_box.get_children()
	var count := ilist.size()
	var first_pmember : BattleStats = null
	for child in battle_scene.party_h_box.get_children():
		if child is BattleStats:
			first_pmember = child
			break
	

		# Two or more entries, use wraparound for top and bottom
	for i in range(count):
		
		var child = ilist[i]
		var btn = child.button

		var left_index := (i - 1 + count) % count
		var right_index := (i + 1) % count
		var left_btn = ilist[left_index].button
		var right_btn = ilist[right_index].button

		var self_path = btn.get_path()
		btn.focus_neighbor_top = self_path
		btn.focus_neighbor_bottom = first_pmember.selection_button.get_path()
		btn.focus_neighbor_left = left_btn.get_path()
		btn.focus_neighbor_right = right_btn.get_path()
		btn.focus_previous = left_btn.get_path()
		btn.focus_next = right_btn.get_path()
		
func setup_party_targeting()->void:
	var ilist := battle_scene.party_h_box.get_children()
	var count := ilist.size()
	var first_enemy : BattleEnemy = null
	for child in battle_scene.enemy_h_box.get_children():
		if child is BattleEnemy:
			first_enemy = child
			break
	

		# Two or more entries, use wraparound for top and bottom
	for i in range(count):
		
		var child = ilist[i] as BattleStats
		var btn = child.selection_button

		var left_index := (i - 1 + count) % count
		var right_index := (i + 1) % count
		var left_btn = ilist[left_index].selection_button
		var right_btn = ilist[right_index].selection_button

		var self_path = btn.get_path()
		btn.focus_neighbor_top = first_enemy.button.get_path()
		btn.focus_neighbor_bottom = self_path
		btn.focus_neighbor_left = left_btn.get_path()
		btn.focus_neighbor_right = right_btn.get_path()
		btn.focus_previous = left_btn.get_path()
		btn.focus_next = right_btn.get_path()
		
		
func target_first_enemy()->void:
	for child in battle_scene.enemy_h_box.get_children():
		if child is BattleEnemy:
			child.grab_button_focus()
			break
			

#endregion Targeting
