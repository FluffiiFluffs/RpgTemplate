##quest_manager.gd
##global QuestManager
extends Node2D

@export var all_quests : Array[Quest] = []

var current_quests : Array[Quest] = []
var completed_quests : Array[Quest] = []

func _ready()->void:
	pass

##Called from outside to give the player a quest
func give_quest(quest_id:StringName)->void:
	var quest := _find_quest(quest_id)
	#Checks if quest_id given is valid
	if quest == null:
		printerr("Quest " + str(quest_id) + " invalid ID")
		return

	#Checks if quest was completed		
	if quest in completed_quests:
		return		

	##set quest step to 1 (active, 0 is inactive)
	quest.current_step = 0
	##Put quest into current_quests array
	current_quests.append(quest)

#region my original code
###Updates quest.action_taken variable. Called from outside.
#func advance_actions_taken(quest_id: StringName, quest_step: int)->void:
	#var quest :Quest= _find_quest_current(quest_id)
	#if quest == null:
		#printerr("Quest " + str(quest_id) + " invalid ID")
		#return
	#if quest not in current_quests:
		#give_quest(quest_id)
		#return
	#if quest.steps == []:
		#printerr("Quest " + str(quest_id) + " cannot be updated. No steps assigned!")
		#return
	#var qstep = quest.steps[quest_step] as QuestStep
	#print("Quest " + str(quest.quest_name) + " on step" + str(qstep))
	##if all the above conditions are met, advance actions taken within the step
	#qstep.actions_taken += 1
	#print("Quest " + str(quest.quest_name) + ", Step " + str(qstep) + ", actions_taken " + str(qstep.actions_taken) + "/" + str(qstep.actions_needed))
	##if actions_taken == actions_needed, complete the step
	#if qstep.actions_taken >= qstep.actions_needed:
		#print("Quest " + str(quest.quest_name) + " completed")
		#qstep.is_completed = true
		#give_step_rewards(qstep)
	##if the step is completed, advance to the next step
	#if qstep.is_completed == true:
		#quest.current_step += 1
		#print("Quest " + str(quest.quest_name) + " moving on to " + str(qstep))
	##if the current_step is above the amount of steps in the quest, complete the quest
	#if quest.current_step == quest.steps.size()+1:
		#_move_to_completed(quest)
		#print("Quest ")
	#pass
#endregion


##Updates quest.actions_taken variable. Called from outside.[br]
##Gives the player the quest and advances to step 1. Step 0 is simply there to help indicate how the quest is obtained in the first place (dev side). May or may not show up in the quest log.
func advance_actions_taken(quest_id: StringName, quest_step: int)->void:
	var quest: Quest = _find_quest(quest_id)
	if quest == null:
		printerr("Quest " + str(quest_id) + " invalid ID")
		return

	if quest not in current_quests:
		give_quest(quest_id)

	# Now quest is guaranteed to be in current_quests
	if quest.steps.is_empty():
		printerr("Quest " + str(quest_id) + " cannot be updated. No steps assigned!")
		return

	if quest_step < 0 or quest_step >= quest.steps.size():
		printerr("Quest " + str(quest_id) + " step " + str(quest_step) + " out of range")
		return

	var qstep := quest.steps[quest_step] as QuestStep
	print("Quest " + str(quest.quest_name) + " on step " + str(quest_step))

	# Advance actions taken within the step
	qstep.actions_taken += 1
	print("Quest " + str(quest.quest_name) + ", Step " + str(quest_step) + " " + str(qstep.actions_taken) + "/" + str(qstep.actions_needed))

	# If actions_taken >= actions_needed, complete the step
	if qstep.actions_taken >= qstep.actions_needed:
		print("Quest step " + str(quest_step) + " completed")
		qstep.is_completed = true
		give_step_rewards(qstep)

	# If the step is completed, advance the progress counter
	if qstep.is_completed:
		quest.current_step += 1
		print("Quest " + str(quest.quest_name) + " moving on, current_step " + str(quest.current_step))

	# If all steps are completed, complete the quest
	if quest.current_step >= quest.steps.size():
		_move_to_completed(quest)
		print("Quest " + str(quest.quest_name) + " fully completed")

#region my original code
###Helper function to move quest to completed_quests array
#func _move_to_completed(quest:Quest)->void:
	#if quest in current_quests:
		#current_quests.erase(quest)
	#if !quest.repeatable:
		#if quest not in completed_quests:
			#completed_quests.append(quest)
	#else:
		#quest.reset()
#endregion

##Erases quest from current_quest array and places it into completed_quests array
func _move_to_completed(quest: Quest)->void:
	if quest in current_quests:
		current_quests.erase(quest)

	quest.is_completed = true

	if !quest.repeatable:
		if quest not in completed_quests:
			completed_quests.append(quest)
	else:
		quest.reset()

##Helper function to locate quest by ID in all_quests
func _find_quest(_quest_id:StringName)->Quest:
	for q in all_quests:
		if q.quest_id == _quest_id:
			return q
	return null

##Helper function to locate quest by ID in current_quests
func _find_quest_current(_quest_id:StringName)->Quest:
	for q in current_quests:
		if q.quest_id == _quest_id:
			return q
	return null

##Disperses rewards (exp, money, items)
func give_step_rewards(_step:QuestStep)->void:
	##Give player's party experience.
	##Give player money
	##Put rewards in inventory.
	pass

##Used to determine if quest exists in current_quests.
func has_quest(_quest_id:StringName)->bool:
	for q in current_quests:
		if q.quest_id == _quest_id:
			return true
	return false

##Used quest_id to determine what step the current quest is on.
func on_step(_quest_id:StringName)->int:
	if has_quest(_quest_id):
		return _find_quest_current(_quest_id).current_step #returns quest step
	else:
		return -1 #returns -1, not on quest
		
func actions_have_been_taken(_quest_id:StringName, _step:QuestStep)->int:
	if has_quest(_quest_id):
		var quest = _find_quest(_quest_id)
		return quest.steps[_step].actions_taken
	return -1

func actions_to_be_needed(_quest_id:StringName, _step:QuestStep)->int:
	if has_quest(_quest_id):
		var quest = _find_quest(_quest_id)
		return quest.steps.size()
	return -1

func quest_is_completed(_quest_id:StringName)->bool:
	for q in completed_quests:
		if q.quest_id == _quest_id:
			return true
	return false
##Updates the quest UI[br]
##example: If an enemy is killed, item is picked up, objective is completed, etc.
func update_quest_ui()->void:
	pass



#region my original code
###If a new game is chosen from the menu after dying.
#func clear_quests()->void:
	#current_quests = []
	#completed_quests = []
#endregion

#region needs to be tested
func clear_quests()->void:
	for quest in all_quests:
		if quest:
			quest.reset()
	current_quests.clear()
	completed_quests.clear()
#endregion
