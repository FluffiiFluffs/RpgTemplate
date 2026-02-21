##save_manager.gd
##global class SaveManager
extends Node
##Save files to be made are saved within the user:// folder
##[br] Saves files are plain text (not json), with the .sav filename extension
##[br] Saves should be easy to decode:
##[br] Save section header example : [header]
##[br] Save key : "variable_name"
##[br] Save value : int/float/string/whatever

##[br][br]

## Current scenes are saved using their filename (no extension)
##[br] Scenes should be loaded by searching through res://field/scenes/field_scenes/ and subfolders to find the filename that matches
##[br] Field file names are unique, so there will never be an issue
	## No need for ID, Godot is not capable of looking into a .tscn file to see an exported variable's value without actually loading that file, which is not preferable.

#region To Do 
##Things to save/load


#Persistence data -- no system exists for this yet
	#recorded per scene
	#if special enemies were killed
	#if certain chests were opened
	#locked doors
	#if certain people have been talked to
	#One time events
	
#endregion To Do

#region Completed
#Arrays needing to be populated to rebuild a save during load
	#all skills list
		#needs script to populate array from files
	#all battleactions list
		#needs script to populate array from files
	#all status effects list
		#needs script to populate array from files
	#all quests list
		#needs script to populate array from files
	#all items list
		#needs script to populate array from files
	#all party members (already populated by hand. Reasonable due to low amount of possible party members)
#Battleactions, skills, and status effects should be okay to "just pull" from this list since they're defined in resources and any special cases would simply just be a different resouce with a different ID

#OPTIONS
	#Options -- needs to be its own save file to reduce player frustration
		#music volume
		#sfx volume
		#voices volume
		#item sort order array
		#voices type
		#portrait type
		#always run
		#message speed
		#battle message speed
		#menu memory
		#battle menu memory
	
	
#GAME SAVE(S)
	#current scene (should probably use a filename string or UID for this)
		#Which save point to spawn from 
		
	#Per Save Statistics (no implementation to increment these exist yet, but the variables exist within CharDataKeeper)
	#enemies_killed
	#party_member_deaths
	#items_used
	#skills_used
	#time_played
	#times_saved
	#times_loaded
	#quests_completede
	#money

#Quests
	#current quests
	#completed quests
	#Per Quest ID
		#current_step
		#is completed
		#repeatable
		#steps array (needs ID to repopulate easily)
			#actions taken
			#is completed


#CharDataKeeper Data
	#members in the party (partymemberdata)
		#Position in CharDataKeeper.party_member array so it can be repopulated accurately
			#first party member should be the one that is set to is_controlled and that should be reflected during repopulation within chardatakeeper

	#outside_members should be recorded, too
	
		#actor_data
			#current_exp
			#next level exp
			#total exp
			#display name
			#level
			#base_stats
				#max hp
				#max sp
				#atk value
				#def value
				#matk value
				#mdef value
				#strength
				#stamina
				#agility
				#magic
				#luck
			#current HP
			#current sp
			#status effects
			#Equipment
			#two handing true/false
			#skills
				#use skill ID to rebuild
	
#endregion Completed


## IN GAME STATS
## TODO no systems exist for this except for money
@export_category("Per Game Stats")
@export var time_played := 0 ##How long the game has been played
@export var times_saved : int = 0
@export var times_loaded : int = 0
@export var money : int = 0 ##How much money the party has
@export var quests_completed : int = 0
@export var enemies_killed : int = 0
@export var party_member_deaths : int = 0
@export var items_used : int = 0
@export var skills_used : int = 0

## Creates a save game. Save name is "save_slot#.sav"
func save_game(slot : int)->void:
	var slotnum : String = str(slot)
	var filename : String = "save_" + slotnum + ".sav"
	var lines: PackedStringArray = PackedStringArray()

	lines.append_array(save_current_scene())
	lines.append_array(save_statistics())
	lines.append_array(save_characters())
	lines.append_array(save_inventory())
	lines.append_array(save_quests())

	var saveloc : String = "user://" + filename
	_write_sav_lines(saveloc, lines)
		

#region Options
## Saves options to file. 
## If there is no options file present, then one is created.
	## Options save file name = "game_ptions.sav"
## Options save is separate from the user's save file, this way options persist across all game saves.
## Options are saved when the options menu is closed.
## Options are loaded only on save-game load
## Saves options to file.
## If there is no options file present, then one is created.
## Options save file name = "game_options.sav"
## Options save is separate from the user's save file, this way options persist across all game saves.
## Options are saved when the options menu is closed.
## Options are loaded only on save-game load
func save_options() -> void:
	var lines: PackedStringArray = PackedStringArray()

	lines.append("[options.volume]")
	lines.append(_keyvalue_line("music_volume", Options.music_volume))
	lines.append(_keyvalue_line("sfx_volume", Options.sfx_volume))
	lines.append(_keyvalue_line("voices_volume", Options.voices_volume))
	lines.append("")

	lines.append("[options.item_sort_order]")
	for i in range(Options.item_sort_order.size()):
		lines.append("item_sort_order." + str(i) + "=" + _encode_value(String(Options.item_sort_order[i])))
	lines.append("")

	lines.append("[options.dialogue]")
	lines.append(_keyvalue_line("voices_type", Options.voices_type))
	lines.append(_keyvalue_line("portrait_type", Options.portrait_type))
	lines.append("")

	lines.append("[options.movement]")
	lines.append(_keyvalue_line("always_run", Options.always_run))
	lines.append("")

	lines.append("[options.message_speeds]")
	lines.append(_keyvalue_line("message_speed", Options.message_speed))
	lines.append(_keyvalue_line("battle_message_speed", Options.battle_message_speed))
	lines.append("")

	lines.append("[options.menu_memory]")
	lines.append(_keyvalue_line("menu_memory", Options.menu_memory))
	lines.append(_keyvalue_line("battle_menu_memory", Options.battle_menu_memory))
	lines.append("")

	_write_sav_lines("user://game_options.sav", lines)
#endregion Options

#region Statistics
## Gathers statistics from CharDataKeeper and returns a PackedStringArray
func save_statistics()->PackedStringArray:
	var lines : PackedStringArray = PackedStringArray()
	lines.append("[game_statistics]")
	lines.append(_keyvalue_line("time_played", time_played))
	lines.append(_keyvalue_line("times_saved", times_saved))
	lines.append(_keyvalue_line("times_loaded", times_loaded))
	lines.append(_keyvalue_line("money", money))
	lines.append(_keyvalue_line("quests_completed", quests_completed))
	lines.append(_keyvalue_line("enemies_killed", enemies_killed))
	lines.append(_keyvalue_line("party_member_deaths", party_member_deaths))
	lines.append(_keyvalue_line("items_used", items_used))
	lines.append(_keyvalue_line("skills_used", skills_used))
	lines.append("")
	
	return lines
#endregion Statistics

#region Current Scene

## Returns PackedStringArray for saving the current scene.
## Only returns the filename of the scene, no path or extension.
func save_current_scene()->PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[current_field_scene]")
	lines.append(_keyvalue_line("current_field_scene", get_current_field_scene_filename()))
	# This may be superceded later by save point node names when loading, but still needs to be in place as a redundant safeguard(?)
	lines.append(_keyvalue_line("position_x", CharDataKeeper.controlled_character.global_position.x))
	lines.append(_keyvalue_line("position_y", CharDataKeeper.controlled_character.global_position.y))
	lines.append("")
	return lines
	
## Returns the filename of the current field scene as a string
## Returns the filename of the current field scene as a string (no .tscn extension)
func get_current_field_scene_filename() -> String:
	if SceneManager.main_scene.current_field_scene != null:
		if SceneManager.main_scene.current_field_scene is FieldScene:
			var cur_f_scene: FieldScene = SceneManager.main_scene.current_field_scene

			var path: String = cur_f_scene.scene_file_path
			return path.get_file().get_basename()

	return "NO FIELD SCENE TO SAVE!"

	
#endregion Current Scene

#region Inventory
func save_inventory()->PackedStringArray:
	var lines : PackedStringArray = PackedStringArray()
	lines.append("[inventory]")
	lines.append("")
	for i in range(Inventory.current_inventory.size()):
		var islot : InventorySlot = Inventory.current_inventory[i]
		if islot == null:
			continue
		if islot.item == null:
			continue

		lines.append("[inventory.item_slot_" + str(i) + "]")
		lines.append(_keyvalue_line("qty", islot.quantity))
		lines.append(_keyvalue_line("item_id", String(islot.item.item_id)))
		lines.append("")

	return lines
#endregion Inventory

#region Quests
func save_quests() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append_array(save_current_quests())
	lines.append_array(save_completed_quests())
	return lines

func save_current_quests() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[quests.current]")
	lines.append("")
	for quest in QuestManager.current_quests:
		var qid : String = String(quest.quest_id)
		var qsec : String = "quests.current." + qid

		lines.append("[" + qsec + "]")
		lines.append(_keyvalue_line("quest_id", qid))
		lines.append(_keyvalue_line("current_step", quest.current_step))
		lines.append(_keyvalue_line("is_completed", quest.is_completed))
		lines.append(_keyvalue_line("repeatable", quest.repeatable))
		lines.append("")

		for si in range(quest.steps.size()):
			var step : QuestStep = quest.steps[si]
			if step == null:
				continue

			var ssec : String = qsec + ".steps." + str(si)
			lines.append("[" + ssec + "]")
			lines.append(_keyvalue_line("quest_step_id", String(step.quest_step_id)))
			lines.append(_keyvalue_line("actions_taken", step.actions_taken))
			lines.append(_keyvalue_line("is_completed", step.is_completed))
			lines.append("")

	return lines
func save_completed_quests() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	
	# Root section is useful as an explicit anchor, even when empty.
	lines.append("[quests.completed]")
	lines.append("")

	for quest in QuestManager.completed_quests:
		var qid : String = String(quest.quest_id)
		var qsec : String = "quests.completed." + qid

		lines.append("[" + qsec + "]")
		lines.append(_keyvalue_line("quest_id", qid))
		lines.append(_keyvalue_line("description", quest.description))
		lines.append(_keyvalue_line("is_completed", quest.is_completed))
		lines.append("")

		for si in range(quest.steps.size()):
			var step : QuestStep = quest.steps[si]
			if step == null:
				continue

			var ssec : String = qsec + ".steps." + str(si)
			lines.append("[" + ssec + "]")
			lines.append(_keyvalue_line("quest_step_id", String(step.quest_step_id)))
			lines.append(_keyvalue_line("description", step.description))
			lines.append(_keyvalue_line("actions_taken", step.actions_taken))
			lines.append(_keyvalue_line("is_completed", step.is_completed))
			lines.append("")

	return lines
	

#endregion Quests

#region Party Members
func save_characters() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append_array(save_current_party_members())
	lines.append_array(save_outside_party_members())
	return lines
	
	
func save_current_party_members()->PackedStringArray:
	var lines : PackedStringArray = PackedStringArray()
	
	lines.append("[characters.current_party_members]")
	lines.append("")
	
	for i in range(CharDataKeeper.party_members.size()):
		var pm : PartyMemberData = CharDataKeeper.party_members[i]
		lines.append("[characters.current_party_members." + str(i) + "]")
		lines.append(_keyvalue_line("actor_id", String(pm.actor_id)))
		lines.append(_keyvalue_line("display_name", pm.display_name))
		lines.append(_keyvalue_line("level", pm.level))
		lines.append(_keyvalue_line("current_exp", pm.current_exp))
		lines.append(_keyvalue_line("next_level_exp", pm.next_level_exp))
		lines.append(_keyvalue_line("total_exp", pm.total_exp))
		lines.append(_keyvalue_line("current_hp", pm.current_hp))
		lines.append(_keyvalue_line("current_sp", pm.current_sp))

		for s in range(pm.status_effects.size()):
			var status : StatusEffect = pm.status_effects[s]
			if status == null:
				continue
			lines.append("status." + str(s) + "=" + _encode_value(String(status.status_id)))

		lines.append(_keyvalue_line("mainhand", _item_id_or_empty(pm.mainhand)))
		lines.append(_keyvalue_line("offhand", _item_id_or_empty(pm.offhand)))
		lines.append(_keyvalue_line("headslot", _item_id_or_empty(pm.headslot)))
		lines.append(_keyvalue_line("chestslot", _item_id_or_empty(pm.chestslot)))
		lines.append(_keyvalue_line("armslot", _item_id_or_empty(pm.armslot)))
		lines.append(_keyvalue_line("legslot", _item_id_or_empty(pm.legslot)))
		lines.append(_keyvalue_line("accy01", _item_id_or_empty(pm.accy01)))
		lines.append(_keyvalue_line("accy02", _item_id_or_empty(pm.accy02)))
		lines.append(_keyvalue_line("two_handing", pm.two_handing))

		for k in range(pm.skills.size()):
			var skill : Skill = pm.skills[k]
			if skill == null:
				continue
			lines.append("skill." + str(k) + "=" + _encode_value(String(skill.skill_id)))

		lines.append(_keyvalue_line("perm_max_hp_flat", pm.perm_max_hp_flat))
		lines.append(_keyvalue_line("perm_max_sp_flat", pm.perm_max_sp_flat))
		lines.append(_keyvalue_line("perm_atk_flat", pm.perm_atk_flat))
		lines.append(_keyvalue_line("perm_def_flat", pm.perm_def_flat))
		lines.append(_keyvalue_line("perm_strength_flat", pm.perm_strength_flat))
		lines.append(_keyvalue_line("perm_stamina_flat", pm.perm_stamina_flat))
		lines.append(_keyvalue_line("perm_agility_flat", pm.perm_agility_flat))
		lines.append(_keyvalue_line("perm_magic_flat", pm.perm_magic_flat))
		lines.append(_keyvalue_line("perm_luck_flat", pm.perm_luck_flat))
		lines.append("")

	return lines
func save_outside_party_members()->PackedStringArray:
	var lines : PackedStringArray = PackedStringArray()
	lines.append("[characters.outside_party_members]")
	lines.append("")
	for i in range(CharDataKeeper.outside_members.size()):
		
		var pm : PartyMemberData = CharDataKeeper.outside_members[i]

		lines.append("[characters.outside_party_members." + str(i) + "]")
		lines.append(_keyvalue_line("actor_id", String(pm.actor_id)))
		lines.append(_keyvalue_line("display_name", pm.display_name))
		lines.append(_keyvalue_line("level", pm.level))
		lines.append(_keyvalue_line("current_exp", pm.current_exp))
		lines.append(_keyvalue_line("next_level_exp", pm.next_level_exp))
		lines.append(_keyvalue_line("total_exp", pm.total_exp))
		lines.append(_keyvalue_line("current_hp", pm.current_hp))
		lines.append(_keyvalue_line("current_sp", pm.current_sp))

		for s in range(pm.status_effects.size()):
			var status : StatusEffect = pm.status_effects[s]
			if status == null:
				continue
			lines.append("status." + str(s) + "=" + _encode_value(String(status.status_id)))

		lines.append(_keyvalue_line("mainhand", _item_id_or_empty(pm.mainhand)))
		lines.append(_keyvalue_line("offhand", _item_id_or_empty(pm.offhand)))
		lines.append(_keyvalue_line("headslot", _item_id_or_empty(pm.headslot)))
		lines.append(_keyvalue_line("chestslot", _item_id_or_empty(pm.chestslot)))
		lines.append(_keyvalue_line("armslot", _item_id_or_empty(pm.armslot)))
		lines.append(_keyvalue_line("legslot", _item_id_or_empty(pm.legslot)))
		lines.append(_keyvalue_line("accy01", _item_id_or_empty(pm.accy01)))
		lines.append(_keyvalue_line("accy02", _item_id_or_empty(pm.accy02)))
		lines.append(_keyvalue_line("two_handing", pm.two_handing))

		for k in range(pm.skills.size()):
			var skill : Skill = pm.skills[k]
			if skill == null:
				continue
			lines.append("skill." + str(k) + "=" + _encode_value(String(skill.skill_id)))

		lines.append(_keyvalue_line("perm_max_hp_flat", pm.perm_max_hp_flat))
		lines.append(_keyvalue_line("perm_max_sp_flat", pm.perm_max_sp_flat))
		lines.append(_keyvalue_line("perm_atk_flat", pm.perm_atk_flat))
		lines.append(_keyvalue_line("perm_def_flat", pm.perm_def_flat))
		lines.append(_keyvalue_line("perm_strength_flat", pm.perm_strength_flat))
		lines.append(_keyvalue_line("perm_stamina_flat", pm.perm_stamina_flat))
		lines.append(_keyvalue_line("perm_agility_flat", pm.perm_agility_flat))
		lines.append(_keyvalue_line("perm_magic_flat", pm.perm_magic_flat))
		lines.append(_keyvalue_line("perm_luck_flat", pm.perm_luck_flat))
		lines.append("")

	return lines
	
#endregion Party Members


#region Save Helpers

func _write_sav_lines(path: String, lines: PackedStringArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var err: int = FileAccess.get_open_error()
		push_error("SaveManager: failed to open for write: " + path + " (" + error_string(err) + ")")
		return

	for line in lines:
		file.store_line(line)

	file.close()

func _keyvalue_line(key: String, value: Variant) -> String:
	return key + "=" + _encode_value(value)



func _encode_value(value: Variant) -> String:
	var t : int = typeof(value)

	if t == TYPE_NIL:
		return ""

	if t == TYPE_BOOL:
		if bool(value):
			return "true"
		return "false"

	if t == TYPE_INT:
		return str(int(value))

	if t == TYPE_FLOAT:
		return _format_float(float(value))

	if t == TYPE_STRING:
		return _encode_string(String(value))

	if t == TYPE_STRING_NAME:
		return _encode_string(String(value))

	push_error("SaveManager: unsupported value type for save: " + str(t))
	return ""


func _encode_string(s: String) -> String:
	var out : String = s
	out = out.replace("\\", "\\\\")
	out = out.replace("\"", "\\\"")
	out = out.replace("\n", "\\n")
	return "\"" + out + "\""


func _item_id_or_empty(item: Item) -> String:
	if item != null:
		return String(item.item_id)
	return ""



func _format_float(v: float) -> String:
	var s : String = String.num(v, 6)
	while s.contains(".") and s.ends_with("0"):
		s = s.left(s.length() - 1)
	if s.ends_with("."):
		s += "0"
	return s



#endregion Save Helpers



#region Loading
## Loads the options file and sets their values. This should happen when the game loads
## Parses through game_options.sav and sets the values within Options
func load_options()->void:
	pass



##Loads a saved game file
func load_game(slot : int)->void:
	#find the saved game from requested slot
	var saved_game_file = find_game_save(slot)
	clear_arrays_for_loading()
	
	load_game_statistics()
	load_inventory()
	load_current_quests()
	load_completed_quests()
	load_current_party_members()
	load_outside_party_members()
	
		
	load_saved_game_field_scene()	
	
	pass
	
	
##Finds the save file at the slot number requested
func find_game_save(slot : int)->FileAccess:
	var savename : String = "user://save_" + str(slot) + ".sav"
	var savefile = FileAccess.open(savename, FileAccess.READ)
	return savefile
	#return save file found in file system
	
## Clears all arrays for loading so new objects can be created
func clear_arrays_for_loading()->void:
	time_played = 0
	times_saved = 0
	times_loaded = 0
	money = 0
	quests_completed = 0
	enemies_killed = 0
	party_member_deaths = 0
	items_used = 0
	skills_used = 0
	
	CharDataKeeper.party_members.clear()
	CharDataKeeper.outside_members.clear()
	
	Inventory.current_inventory.clear()
	
	QuestManager.current_quests.clear()
	QuestManager.completed_quests.clear()
	
	

## Parses selected save file and sets the game statistics (in this global script) to the correct values
## Reads data under the [game_statistics] heading
func load_game_statistics()->void:
	pass
	
## Parses the selected save file and sets up the Inventory.current_inventory.
## Reads data under the [inventory] heading
## Uses InventorySlot.new() to set up a new item slot
## Sets the InventorySlot.quantity using slot_qty
## Uses Registry.find_item_by_id(item_id) to set the item
func load_inventory()->void:
	pass

## Parses the selected save file and sets up QuestManager.current_quests
## Reads data under [quests.current_quests]
## Uses Registry.find_quest_by_id(quest_id) to duplicate(true) quests into their respective arrays
## Though redundant, uses is_completed flag that proceeds quest_id to set the quest's is_complete flag
## Parses quest_step_id
	##the next actions_taken is what the quest step's actions taken is set to
	##the next is_completed is what the quest step's is_completed flag is set to
func load_current_quests()->void:

	pass


## Parses the selected save file and sets up QuestManager.completed_quests
## Reads data under [quests.completed_quests]
## Though redundant, uses is_completed flag that proceeds quest_id to set the quest's is_complete flag
## Uses Registry.find_quest_by_id(quest_id) to duplicate(true) quests into their respective arrays
## Parses quest_step_id
	##the next actions_taken is what the quest step's actions taken is set to
	##the next is_completed is what the quest step's is_completed flag is set to
func load_completed_quests()->void:
	pass
	
	
## parses until [characters.current_party_members] is found
## parses until actor_id found in save file, then uses Registry.find_party_member_by_id(actor_id)
## Uses Duplicate(true) using the matched data from all_party_members to put a party member into CharDataKeeper.party_members
## Parses and sets up level, current_exp, next_level_exp, total_exp, current_hp, current_sp
## When reaching mainhand, uses Registry.find_item_by_id to set the item in each equip slot until accy02
## Parses skills and sets the Skills array
## Prases perm stats and sets their values
## Repeats for each party member found within the CharDataKeeper.party_memebers array
func load_current_party_members()->void:
	pass
	
	
## parses until [characters.outside_party_members] is found
## parses until actor_id found in save file, then uses Registry.find_party_member_by_id(actor_id)
## Uses Duplicate(true) using the matched data from all_party_members to put a party member into CharDataKeeper.outside_members
## Parses and sets up level, current_exp, next_level_exp, total_exp, current_hp, current_sp
## When reaching mainhand, uses Registry.find_item_by_id to set the item in each equip slot until accy02
## Parses skills and sets the Skills array
## Prases perm stats and sets their values
## Repeats for each party member found within the CharDataKeeper.outside_party_members array
func load_outside_party_members()->void:
	pass

## Loads the saved game scene. Needs to be done last so party members are loaded first
## Parses the current_field_scene, searches the filesystem under res://field/scenes/field_scenes and subfolders for the filename. Uses SceneManager.load_scene_by_filename(filename)
## Instantiates CharDataKeeper.party_members at position_x and position_y (as if just spawning in, should be a simliar action to SceneManager.make_party_at_spawn_point(), except it uses the x and y locations instead of the spawn point. Player always faces down when loading.
func load_saved_game_field_scene()->void:
	pass

#endregion Loading





#region Testing
func test_save_slot_1()->void:
	save_game(1)

func test_save_slot_2()->void:
	save_game(2)

func test_load_game_1()->void:
	load_game(1)
	
func test_load_game_2()->void:
	load_game(2)
#endregion Testing
