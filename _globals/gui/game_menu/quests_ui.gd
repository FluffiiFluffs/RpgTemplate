class_name QuestsUI extends Control


#region quest menu variables
@onready var quests_list_v_box : VBoxContainer = %QuestsListVBox
@onready var quest_title : Label = %QuestTitle
@onready var quest_desc : Label = %QuestDesc
@onready var quest_step_desc : Label = %QuestStepDesc
@onready var quests_current_button : QuestTypeButton = %QuestsCurrentButton
@onready var quests_completed_button : QuestTypeButton = %QuestsCompletedButton
@onready var quest_desc_h_sep_1 : HSeparator = %QuestDescHSep1
@onready var quest_desc_h_sep_2 : HSeparator = %QuestDescHSep2
@onready var quests_type_h_box : HBoxContainer = %QuestsTypeHBox

@onready var quests_left_panel: PanelContainer = %QuestsLeftPanel
@onready var description_panel: PanelContainer = %DescriptionPanel
#endregion quest menu variables

func _ready()->void:
	#region initialize position and visibility
	visible = true
	quests_left_panel.visible = false
	description_panel.visible = false
	quests_left_panel.position = Vector2(-200, 0)
	description_panel.position = Vector2(200, 0)
	
	#endregion initialize position and visibility



#region quest menu
func open_quests_menu()->void:
	#plays menu open animation
	#animation_player.play("quests_menu_show")
	quests_menu_show()
	#sets menu state to last_quests_menu_state ("QUESTS_CURRENT_QUESTS" by default, then changed later if user selects differently)
	GameMenu.menu_state = GameMenu.last_quests_menu_state
	GameMenu.last_top_button_focused = GameMenu.top_level.quests_button
	GameMenu.top_level.quests_button.is_active = true
	match GameMenu.last_quests_menu_state:
		"QUESTS_CURRENT_QUESTS":
			quests_current_button.is_active = true
			quests_current_button.self_modulate = GameMenu.ENABLED_COLOR
		"QUESTS_COMPLETED_QUESTS":
			quests_completed_button.is_active = true
			quests_completed_button.self_modulate = GameMenu.ENABLED_COLOR
	update_quests_list(GameMenu.last_quests_menu_state)
	select_first_quest_in_list()
	pass

func close_quests_menu()->void:
	#plays menu close animation
	#animation_player.play("quests_menu_hide")
	await quests_menu_hide()
	clear_quests_list()
	quests_completed_button.is_active = false
	quests_current_button.is_active = false
	quests_current_button.self_modulate = GameMenu.TRANS_COLOR
	quests_completed_button.self_modulate = GameMenu.TRANS_COLOR
	pass

func quests_menu_show()->void:
	GameMenu.menu_is_animating = true
	await GameMenu.top_level.top_menu_hide()
	quests_left_panel.visible = true
	description_panel.visible = true
	quests_left_panel.position = Vector2(-200, 0)
	description_panel.position = Vector2(200, 0)
	var tween := create_tween().set_parallel()
	tween.tween_property(quests_left_panel, "position", Vector2(0, 0), 0.15)
	tween.tween_property(description_panel, "position", Vector2(0,0), 0.15)
	await tween.finished
	GameMenu.menu_is_animating = false

func quests_menu_hide()->void:
	GameMenu.menu_is_animating = true
	quests_left_panel.position = Vector2(0, 0)
	description_panel.position = Vector2(0, 0)

	var tween := create_tween().set_parallel()
	tween.tween_property(quests_left_panel, "position", Vector2(-200, 0), 0.15)
	tween.tween_property(description_panel, "position", Vector2(200,0), 0.15)
	await tween.finished
	quests_left_panel.visible = false
	description_panel.visible = false
	await GameMenu.top_level.top_menu_show()
	GameMenu.menu_is_animating = false


func open_current_quests()->void:
	clear_quests_list()
	#iterate through QuestManager.completed_quests and instantiate buttons in list
	for quest in QuestManager.current_quests:
		if quest != null:
			var new_button = GameMenu.QUEST_BUTTON.instantiate()
			quests_list_v_box.add_child(new_button)
			new_button.label.text = quest.quest_name
			new_button.quest = quest
	select_first_quest_in_list()
	pass

func open_completed_quests()->void:
	clear_quests_list()
	#iterate through QuestManager.completed_quests and instantiate buttons in list
	for quest in QuestManager.completed_quests:
		if quest != null:
			var new_button = GameMenu.QUEST_BUTTON.instantiate()
			quests_list_v_box.add_child(new_button)
			new_button.label.text = quest.quest_name
			new_button.quest = quest
	select_first_quest_in_list()
	pass


func select_first_quest_in_list()->void:
	if GameMenu.menu_state == "QUESTS_CURRENT_QUESTS":
		if QuestManager.current_quests.is_empty():
			quests_current_button.is_active = false
			quests_current_button.grab_button_focus()
			quest_desc_h_sep_1.visible = false
			quest_desc_h_sep_2.visible = false
			return
	elif GameMenu.menu_state == "QUESTS_COMPLETED_QUESTS":
		if QuestManager.completed_quests.is_empty():
			quests_completed_button.is_active = false
			quests_completed_button.grab_button_focus()
			quest_desc_h_sep_1.visible = false
			quest_desc_h_sep_2.visible = false
			return
	#find the first quest_button and focus it
	for child in quests_list_v_box.get_children():
		if child is QuestButton:
			child.grab_button_focus()
			break
		pass
	#setting focus should trigger focus_entered on the button to update the description
	pass

func cancel_to_quest_type_selection()->void:
	#unfocus current quest in list and focus either Current Quests or Complete Quests type selection button
	quests_completed_button.is_active = false
	quests_current_button.is_active = false
	quests_current_button.self_modulate = GameMenu.TRANS_COLOR
	quests_completed_button.self_modulate = GameMenu.TRANS_COLOR
	if GameMenu.last_quests_menu_state == "QUESTS_CURRENT_QUESTS":
		quests_current_button.grab_button_focus()
	elif GameMenu.last_quests_menu_state == "QUESTS_COMPLETED_QUESTS":
			quests_completed_button.grab_button_focus()
	GameMenu.menu_state = "QUESTS_SELECT_TYPE"
	clear_quest_description()
	#(each button should have an export variable to pass through to set last_quests_menu_state to be that when the button is pressed, clear quest list, update quest list, focus first in list)
	pass

func clear_quests_list()->void:
	#iterate through list, remove child, queue free
	for child in quests_list_v_box.get_children():
		quests_list_v_box.remove_child(child)
		child.queue_free()
	#clear description
	pass

func clear_quest_description()->void:
	quest_desc_h_sep_1.visible = false
	quest_desc_h_sep_2.visible = false
	quest_title.text = ""
	quest_desc.text = ""
	quest_step_desc.text = ""

func update_quests_list(type:String)->void: #type == last_quests_menu_state
	match type:
		"QUESTS_CURRENT_QUESTS":
			open_current_quests()
		"QUESTS_COMPLETED_QUESTS":
			open_completed_quests()
	setup_quests_focus_neighbors()

func update_quest_description(quest : Quest)->void:
	#passes quest held within quest_button to fill out the quest_description pane
	quest_desc_h_sep_1.visible = true
	quest_desc_h_sep_2.visible = true
	quest_title.text = quest.quest_name
	quest_desc.text = quest.description
	for step in quest.steps:
		if step.is_completed == true:
			continue
		else:
			quest_step_desc.text = step.description
			break


func setup_quests_focus_neighbors() -> void:
	var ilist := quests_list_v_box.get_children()
	var count := ilist.size()

	if count == 0:
		clear_quest_description()
		return

	# Only one entry, all neighbors point to itself
	if count == 1:
		var only_child = ilist[0]
		var btn = only_child.button
		var path = btn.get_path()
		btn.focus_neighbor_top = path
		btn.focus_neighbor_bottom = path
		btn.focus_neighbor_left = path
		btn.focus_neighbor_right = path
	else:
		# Two or more entries, use wraparound for top and bottom
		for i in range(count):
			
			var child = ilist[i]
			var btn = child.button

			var top_index := (i - 1 + count) % count
			var bottom_index := (i + 1) % count
			var top_btn = ilist[top_index].button
			var bottom_btn = ilist[bottom_index].button

			btn.focus_neighbor_top = top_btn.get_path()
			btn.focus_neighbor_bottom = bottom_btn.get_path()

			var self_path = btn.get_path()
			btn.focus_neighbor_left = self_path
			btn.focus_neighbor_right = self_path


func force_close_for_load() -> void:
	# Hide both panels, no tweens.
	quests_left_panel.visible = false
	description_panel.visible = false

	quests_left_panel.position = Vector2(-200, 0)
	description_panel.position = Vector2(200, 0)

	# Clear list and reset selection visuals.
	clear_quests_list()
	clear_quest_description()

	quests_current_button.is_active = false
	quests_completed_button.is_active = false
	quests_current_button.self_modulate = GameMenu.TRANS_COLOR
	quests_completed_button.self_modulate = GameMenu.TRANS_COLOR

#endregion quest menu
