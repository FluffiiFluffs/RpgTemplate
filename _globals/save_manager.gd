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


#current scene (should probably use a filename string or UID for this)
	#Which save point to spawn from 
	

#CharDataKeeper Data
	#members in the party (partymemberdata)
		#Position in CharDataKeeper.party_member array so it can be repopulated accurately
			#first party member should be the one that is set to is_controlled and that should be reflected during repopulation within chardatakeeper
	
	
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
	

#inventory
	#slots and items in those slots, probably needs a dictionary
	
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


#Persistence data
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

#endregion Completed

## Creates a save game. Save name is "save_slot#.sav"
func save_game(slot : int)->void:
	var slotnum : String = str(slot)
	var filename : String = "save_" + slotnum + ".sav"
	var lines: PackedStringArray = PackedStringArray()
	lines.append_array(save_current_scene())
	
	var saveloc : String = "user://" + filename
	_write_sav_lines(saveloc, lines)
	pass
	

#region Options
## Saves options to file. 
## If there is no options file present, then one is created.
	## Options save file name = "GameOptions.sav"
## Options save is separate from the user's save file, this way options persist across all game saves.
## Options are saved when the options menu is closed.
## Options are loaded only on save-game load
## Saves options to file.
## If there is no options file present, then one is created.
## Options save file name = "GameOptions.sav"
## Options save is separate from the user's save file, this way options persist across all game saves.
## Options are saved when the options menu is closed.
## Options are loaded only on save-game load
func save_options() -> void:
	var lines: PackedStringArray = PackedStringArray()

	lines.append("[volume]")
	lines.append(_keyvalue_line("music_volume", Options.music_volume))
	lines.append(_keyvalue_line("sfx_volume", Options.sfx_volume))
	lines.append(_keyvalue_line("voices_volume", Options.voices_volume))
	lines.append("")

	lines.append("[item_sort_order]")
	lines.append(_keyvalue_line("item_sort_order", Options.item_sort_order))
	lines.append("")

	lines.append("[dialogue]")
	lines.append(_keyvalue_line("voices_type", Options.voices_type))
	lines.append(_keyvalue_line("portrait_type", Options.portrait_type))
	lines.append("")

	lines.append("[movement]")
	lines.append(_keyvalue_line("always_run", Options.always_run))
	lines.append("")

	lines.append("[message_speeds]")
	lines.append(_keyvalue_line("message_speed", Options.message_speed))
	lines.append(_keyvalue_line("battle_message_speed", Options.battle_message_speed))
	lines.append("")

	lines.append("[menu_memory]")
	lines.append(_keyvalue_line("menu_memory", Options.menu_memory))
	lines.append(_keyvalue_line("battle_menu_memory", Options.battle_menu_memory))
	lines.append("")

	_write_sav_lines("user://GameOptions.sav", lines)
	
#endregion Options



#region Current Scene

## 
func save_current_scene()->PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[current_field_scene]")
	lines.append(get_current_field_scene_filename())
	lines.append("")
	return lines
	
#endregion Current Scene


#region Helpers

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
	if typeof(value) == TYPE_FLOAT:
		return _format_float(value)

	# Strings become quoted, Arrays become [..], bool becomes true or false, etc.
	# This stays plaintext and stays parseable later via str_to_var.
	return var_to_str(value)


func _format_float(v: float) -> String:
	# Keep floats as floats on disk so later parsing does not turn 7.0 into int 7.
	var _string: String = String.num(v, 3) # example: 7.000
	while _string.contains(".") and _string.ends_with("0"):
		_string = _string.left(_string.length() - 1)
	if _string.ends_with("."):
		_string += "0"
	return _string

## Returns the filename of the current field scene as a string
## Returns the filename of the current field scene as a string (no .tscn extension)
func get_current_field_scene_filename() -> String:
	if SceneManager.main_scene.current_field_scene != null:
		if SceneManager.main_scene.current_field_scene is FieldScene:
			var cur_f_scene: FieldScene = SceneManager.main_scene.current_field_scene

			var path: String = cur_f_scene.scene_file_path
			return path.get_file().get_basename()

	return "NO FIELD SCENE TO SAVE!"

#endregion Helpers


#region Testing
func test_save_slot_1()->void:
	save_game(1)

func test_save_slot_2()->void:
	pass

#endregion Testing
