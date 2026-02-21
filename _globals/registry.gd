##Global Script Registry
##Holds arrays of objects needed to be found by their ID
##Field Scenes are NOT held here, and are instead found by their filename
##Objects using these arrays should duplicate(true) so these objects are not altered during their use
extends Node


##Arrays keeping a list of all available Party Members, BattleActions, Skills, Effects, and StatusEffects. 
##Arrays for all Item data are kept within InventoryManager and Quest data are kept within QuestManager. 
##Primarily used for loading these objects by ID.
@export_category("Base Data Arrays")
##All recruitable party members's data within the game. 
##This array is manually populated from within the inspector
@export var all_party_members : Array[PartyMemberData] = []


##All BattleActions available within the game. 
##This array is auto-populated during game load via function
@export var all_battle_actions : Array[BattleAction] = []

##All Skills available in the game. 
##This array is auto-populated during game load via function
@export var all_skills : Array[Skill] = []

## All StatusEffect templates available within the game, keyed by status_id.
## Values are templates loaded from .tres and treated as read only.
@export var all_status_effects : Dictionary = {}

##All Quests available within the game.
##This array is auto-populated during game load via function
@export var all_quests : Array[Quest] = []

##All the items in the game so they're easily accessed
##This array is auto-populated during game load via function
@export var all_items : Array[Item]


func _ready()->void:
	populate_all_arrays()


#region Registry Population

##Calls all functions to populate base data arrays (including quest and items, even though they live outside CharDataKeeper).
func populate_all_arrays()->void:
	populate_battle_actions_array()
	populate_skills_array()
	populate_status_effects_array()
	populate_all_quests_array()
	populate_all_items_array()


##Finds all battle actions within res://battle/actions/battle_actions/ and its nested folders
##Adds battle action resources to all_battle_actions array
##Does not include script files defining the battle actions, only the .tres resources
func populate_battle_actions_array()->void:
	all_battle_actions.clear()

	var root_dir = "res://battle/actions/battle_actions"
	var dir_stack: Array[String] = [root_dir]

	while dir_stack.size() > 0:
		var dir_path = dir_stack.pop_back()

		for subdir_name in DirAccess.get_directories_at(dir_path):
			dir_stack.append(dir_path.path_join(subdir_name))

		for file_name in DirAccess.get_files_at(dir_path):
			if not file_name.ends_with(".tres"):
				continue

			var res_path = dir_path.path_join(file_name)
			var res = ResourceLoader.load(res_path, "BattleAction")

			if res is BattleAction:
				all_battle_actions.append(res)


##Finds all skills within res://skill/skills/ and its nested folders. 
##Adds Skill resources to all_skills array
##Does not include script files defining the skills, only the .tres resources
func populate_skills_array()->void:
	all_skills.clear()

	var root_dir = "res://skill/skills"
	var dir_stack: Array[String] = [root_dir]

	while dir_stack.size() > 0:
		var dir_path = dir_stack.pop_back()

		for subdir_name in DirAccess.get_directories_at(dir_path):
			dir_stack.append(dir_path.path_join(subdir_name))

		for file_name in DirAccess.get_files_at(dir_path):
			if not file_name.ends_with(".tres"):
				continue

			var res_path = dir_path.path_join(file_name)
			var res = ResourceLoader.load(res_path, "Skill")

			if res is Skill:
				all_skills.append(res)

##Finds all StatusEffects within res://battle/status_effects/status_effects/ and its nested folders
##Adds all StatusEffect resources to all_status_effects
##Does not include script files defining the status effects, only the .tres resrouces
func populate_status_effects_array()->void:
	all_status_effects.clear()

	var root_dir = "res://battle/status_effects/status_effects"
	var dir_stack: Array[String] = [root_dir]

	while dir_stack.size() > 0:
		var dir_path = dir_stack.pop_back()

		for subdir_name in DirAccess.get_directories_at(dir_path):
			dir_stack.append(dir_path.path_join(subdir_name))

		for file_name in DirAccess.get_files_at(dir_path):
			if not file_name.ends_with(".tres"):
				continue

			var res_path = dir_path.path_join(file_name)
			var res = ResourceLoader.load(res_path, "StatusEffect")
			if not (res is StatusEffect):
				continue

			var status : StatusEffect = res as StatusEffect
			var id : StringName = status.status_id

			all_status_effects[id] = status
			
			
			
			
##Finds all Quests within res://quest_system/quests/ and its nested folders
##Adds all Quest resources to QuestManager.all_quests
##Does not include quest steps since they are by default nested within the .tres resrouces
func populate_all_quests_array()->void:
	all_quests.clear()

	var root_dir = "res://quest_system/quests"
	var dir_stack: Array[String] = [root_dir]

	while dir_stack.size() > 0:
		var dir_path = dir_stack.pop_back()

		for subdir_name in DirAccess.get_directories_at(dir_path):
			dir_stack.append(dir_path.path_join(subdir_name))

		for file_name in DirAccess.get_files_at(dir_path):
			if not file_name.ends_with(".tres"):
				continue

			var res_path = dir_path.path_join(file_name)
			var res = ResourceLoader.load(res_path, "Quest")

			if res is Quest:
				all_quests.append(res)


##Finds all items within res://inventory/items/ and its nested folders
##Adds all Item resources to Inventory.all_items
##Does not include script files defining the items (if any), only the .tres resrouces
func populate_all_items_array()->void:
	all_items.clear()

	var root_dir = "res://inventory/items/"
	var dir_stack: Array[String] = [root_dir]

	while dir_stack.size() > 0:
		var dir_path = dir_stack.pop_back()

		for subdir_name in DirAccess.get_directories_at(dir_path):
			dir_stack.append(dir_path.path_join(subdir_name))

		for file_name in DirAccess.get_files_at(dir_path):
			if not file_name.ends_with(".tres"):
				continue

			var res_path = dir_path.path_join(file_name)
			var res = ResourceLoader.load(res_path, "Item")

			if res is Item:
				all_items.append(res)

#endregion Registry Population


func instantiate_status(status_id : StringName) -> StatusEffect:
	var template : StatusEffect = all_status_effects[status_id] as StatusEffect
	var instance : StatusEffect = template.duplicate(true) as StatusEffect
	instance.reset_runtime_state()
	return instance
