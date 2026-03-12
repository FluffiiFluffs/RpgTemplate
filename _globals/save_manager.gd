## SaveManager
## Writes and reads plain text save files in user:// with .sav extension.
## Format:
##   [section.name]
##   key=value
## Values are encoded with _encode_value and decoded with _decode_value.

extends Control

@onready var save_load_menu: SaveLoadMenu = %SaveLoadMenu
@onready var confirm_window: SaveLoadConfirmWindow = %ConfirmWindow

var _loaded_save_sections: Dictionary = {}
var _loaded_options_sections: Dictionary = {}

var state_flags: Array[PackedStringArray] = []


## Slot number (1 based) last saved to or loaded from.
## Copy and erase do not update this.
var last_used_save_slot_number: int = 0

const FIELD_SCENES_ROOT_DIR: String = "res://field/scenes/field_scenes"

@export_category("Per Game Stats")
@export var time_played: int = 0
@export var times_saved: int = 0
@export var times_loaded: int = 0
@export var money: int = 0
@export var quests_completed: int = 0
@export var enemies_killed: int = 0
@export var party_member_deaths: int = 0
@export var items_used: int = 0
@export var skills_used: int = 0


func _ready()->void:
	load_options()

## Creates a save game. Save name is "save_slot#.sav"
func save_game(slot : int) -> void:
	var filename : String = "save_" + str(slot) + ".sav"
	var lines : PackedStringArray = PackedStringArray()

	# Statistics are stored inside the save file, so increment before writing.
	times_saved += 1

	lines.append_array(save_current_scene())
	lines.append_array(save_state_flags())
	lines.append_array(save_statistics())
	lines.append_array(save_characters())
	lines.append_array(save_inventory())
	lines.append_array(save_quests())

	_write_sav_lines("user://" + filename, lines)
	last_used_save_slot_number = slot

		

#region Options
## Saves options to file. 
## If there is no options file present, then one is created.
	## Options save file name = "game_ptions.sav"
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
	
	lines.append("[options.skills_sort_order]")
	for i in range(Options.skills_sort_order.size()):
		lines.append("skills_sort_order." + str(i) + "=" + _encode_value(String(Options.skills_sort_order[i])))
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
## Saves the field scene filename basename, plus a spawn position fallback.
func save_current_scene() -> PackedStringArray:
	var lines : PackedStringArray = PackedStringArray()
	lines.append("[current_field_scene]")

	var field_scene_filename : String = get_current_field_scene_filename()
	lines.append(_keyvalue_line("current_field_scene", field_scene_filename))

	var spawn_position : Vector2 = Vector2.ZERO
	if CharDataKeeper.controlled_character != null:
		spawn_position = CharDataKeeper.controlled_character.global_position

	lines.append(_keyvalue_line("position_x", spawn_position.x))
	lines.append(_keyvalue_line("position_y", spawn_position.y))
	lines.append("")
	return lines


func save_state_flags() -> PackedStringArray:
	var lines : PackedStringArray = PackedStringArray()
	lines.append("[state_flags]")
	lines.append("")

	var write_index: int = 0
	for entry in state_flags:
		if entry.size() != 2:
			continue

		var scene_filename: String = String(entry[0])
		var object_node_name: String = String(entry[1])
		if scene_filename == "":
			continue
		if object_node_name == "":
			continue

		lines.append("[state_flags." + str(write_index) + "]")
		lines.append(_keyvalue_line("scene_filename", scene_filename))
		lines.append(_keyvalue_line("object_node_name", object_node_name))
		lines.append("")
		write_index += 1

	return lines



## Returns the filename of the current field scene (no extension).
func get_current_field_scene_filename() -> String:
	var main_scene : Main = SceneManager.main_scene
	if main_scene == null:
		return "NO FIELD SCENE TO SAVE!"

	var field_scene : FieldScene = main_scene.current_field_scene as FieldScene
	if field_scene == null:
		return "NO FIELD SCENE TO SAVE!"

	return field_scene.scene_file_path.get_file().get_basename()
	
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
	
	
func _save_party_member_list(section_root : String, members : Array[PartyMemberData]) -> PackedStringArray:
	var lines : PackedStringArray = PackedStringArray()
	lines.append("[" + section_root + "]")
	lines.append("")

	for i in range(members.size()):
		var member : PartyMemberData = members[i]
		if member == null:
			continue

		lines.append("[" + section_root + "." + str(i) + "]")
		lines.append(_keyvalue_line("actor_id", String(member.actor_id)))
		lines.append(_keyvalue_line("display_name", member.display_name))
		lines.append(_keyvalue_line("level", member.level))
		lines.append(_keyvalue_line("current_exp", member.current_exp))
		lines.append(_keyvalue_line("next_level_exp", member.next_level_exp))
		lines.append(_keyvalue_line("total_exp", member.total_exp))
		lines.append(_keyvalue_line("current_hp", member.current_hp))
		lines.append(_keyvalue_line("current_sp", member.current_sp))

		for status_index in range(member.status_effects.size()):
			var status : StatusEffect = member.status_effects[status_index]
			if status == null:
				continue
			lines.append("status." + str(status_index) + "=" + _encode_value(String(status.status_id)))

		lines.append(_keyvalue_line("mainhand", _item_id_or_empty(member.mainhand)))
		lines.append(_keyvalue_line("offhand", _item_id_or_empty(member.offhand)))
		lines.append(_keyvalue_line("headslot", _item_id_or_empty(member.headslot)))
		lines.append(_keyvalue_line("chestslot", _item_id_or_empty(member.chestslot)))
		lines.append(_keyvalue_line("armslot", _item_id_or_empty(member.armslot)))
		lines.append(_keyvalue_line("legslot", _item_id_or_empty(member.legslot)))
		lines.append(_keyvalue_line("accy01", _item_id_or_empty(member.accy01)))
		lines.append(_keyvalue_line("accy02", _item_id_or_empty(member.accy02)))
		lines.append(_keyvalue_line("two_handing", member.two_handing))

		for skill_index in range(member.skills.size()):
			var skill : Skill = member.skills[skill_index]
			if skill == null:
				continue
			lines.append("skill." + str(skill_index) + "=" + _encode_value(String(skill.skill_id)))

		lines.append(_keyvalue_line("perm_max_hp_flat", member.perm_max_hp_flat))
		lines.append(_keyvalue_line("perm_max_sp_flat", member.perm_max_sp_flat))
		lines.append(_keyvalue_line("perm_atk_flat", member.perm_atk_flat))
		lines.append(_keyvalue_line("perm_def_flat", member.perm_def_flat))
		lines.append(_keyvalue_line("perm_strength_flat", member.perm_strength_flat))
		lines.append(_keyvalue_line("perm_stamina_flat", member.perm_stamina_flat))
		lines.append(_keyvalue_line("perm_agility_flat", member.perm_agility_flat))
		lines.append(_keyvalue_line("perm_magic_flat", member.perm_magic_flat))
		lines.append(_keyvalue_line("perm_luck_flat", member.perm_luck_flat))
		lines.append("")

	return lines	
	
	
func save_current_party_members() -> PackedStringArray:
	return _save_party_member_list("characters.current_party_members", CharDataKeeper.party_members)


func save_outside_party_members() -> PackedStringArray:
	return _save_party_member_list("characters.outside_party_members", CharDataKeeper.outside_members)
	
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
	var value_type : int = typeof(value)

	if value_type == TYPE_NIL:
		return ""

	if value_type == TYPE_BOOL:
		if bool(value):
			return "true"
		return "false"

	if value_type == TYPE_INT:
		return str(int(value))

	if value_type == TYPE_FLOAT:
		return _format_float(float(value))

	if value_type == TYPE_STRING:
		return _encode_string(String(value))

	if value_type == TYPE_STRING_NAME:
		return _encode_string(String(value))

	push_error("SaveManager: unsupported value type for save: " + str(value_type))
	return ""


func _encode_string(text: String) -> String:
	var escaped : String = text
	escaped = escaped.replace("\\", "\\\\")
	escaped = escaped.replace("\"", "\\\"")
	escaped = escaped.replace("\n", "\\n")
	return "\"" + escaped + "\""


func _item_id_or_empty(item: Item) -> String:
	if item != null:
		return String(item.item_id)
	return ""


func _format_float(value: float) -> String:
	var text: String = String.num(value, 6)
	while text.contains(".") and text.ends_with("0"):
		text = text.left(text.length() - 1)
	if text.ends_with("."):
		text += "0"
	return text



#endregion Save Helpers



#region Loading
## Loads the options file and sets their values. This should happen when the game loads
## Parses through game_options.sav and sets the values within Options
## Loads the options file and sets their values. This should happen when the game loads
## Parses through game_options.sav and sets the values within Options
func load_options()->void:
	_loaded_options_sections.clear()
	var file : FileAccess = FileAccess.open("user://game_options.sav", FileAccess.READ)
	if file == null:
		return

	_loaded_options_sections = _parse_sav_file(file)
	file.close()

	var vol : Dictionary = _get_section(_loaded_options_sections, "options.volume")
	if not vol.is_empty():
		Options.set_music_volume(_sec_get_float(vol, "music_volume", Options.music_volume))
		Options.set_sfx_volume(_sec_get_float(vol, "sfx_volume", Options.sfx_volume))
		Options.set_voices_volume(_sec_get_float(vol, "voices_volume", Options.voices_volume))

	var iso : Dictionary = _get_section(_loaded_options_sections, "options.item_sort_order")
	if not iso.is_empty():
		var order_pairs : Array = []
		for k in iso.keys():
			var key : String = String(k)
			if not key.begins_with("item_sort_order."):
				continue
			var idx_str : String = key.substr("item_sort_order.".length())
			if not idx_str.is_valid_int():
				continue
			order_pairs.append([int(idx_str), _sec_get_string(iso, key, "")])

		order_pairs.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
		Options.item_sort_order.clear()
		for pair in order_pairs:
			Options.item_sort_order.append(String(pair[1]))

	var sso : Dictionary = _get_section(_loaded_options_sections, "options.skills_sort_order")
	if not sso.is_empty():
		var order_pairs : Array = []
		for k in sso.keys():
			var key : String = String(k)
			if not key.begins_with("skills_sort_order."):
				continue
			var idx_str : String = key.substr("skills_sort_order.".length())
			if not idx_str.is_valid_int():
				continue
			order_pairs.append([int(idx_str), _sec_get_string(sso, key, "")])

		order_pairs.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
		Options.skills_sort_order.clear()
		for pair in order_pairs:
			Options.skills_sort_order.append(String(pair[1]))
	Options.validate_skills_sort_order()

	var dlg : Dictionary = _get_section(_loaded_options_sections, "options.dialogue")
	if not dlg.is_empty():
		Options.voices_type = _sec_get_int(dlg, "voices_type", Options.voices_type)
		Options.portrait_type = _sec_get_int(dlg, "portrait_type", Options.portrait_type)

	var mov : Dictionary = _get_section(_loaded_options_sections, "options.movement")
	if not mov.is_empty():
		Options.always_run = _sec_get_bool(mov, "always_run", Options.always_run)

	var spd : Dictionary = _get_section(_loaded_options_sections, "options.message_speeds")
	if not spd.is_empty():
		Options.message_speed = _sec_get_float(spd, "message_speed", Options.message_speed)
		Options.battle_message_speed = _sec_get_float(spd, "battle_message_speed", Options.battle_message_speed)

	var mem : Dictionary = _get_section(_loaded_options_sections, "options.menu_memory")
	if not mem.is_empty():
		Options.menu_memory = _sec_get_bool(mem, "menu_memory", Options.menu_memory)
		Options.battle_menu_memory = _sec_get_bool(mem, "battle_menu_memory", Options.battle_menu_memory)





##Loads a saved game file
func load_game(slot : int)->void:
	var saved_game_file : FileAccess = find_game_save(slot)
	if saved_game_file == null:
		var err : int = FileAccess.get_open_error()
		push_error("SaveManager: failed to open save slot " + str(slot) + " (" + error_string(err) + ")")
		return

	_loaded_save_sections.clear()
	_loaded_save_sections = _parse_sav_file(saved_game_file)
	saved_game_file.close()
	last_used_save_slot_number = slot
	
	load_options()
	clear_arrays_for_loading()

	load_state_flags()

	load_game_statistics()
	times_loaded += 1
	load_inventory()
	load_current_quests()
	load_completed_quests()
	load_current_party_members()
	load_outside_party_members()
	load_saved_game_field_scene()
	
	
##Finds the save file at the slot number requested
func find_game_save(slot : int)->FileAccess:
	var savename : String = "user://save_" + str(slot) + ".sav"
	var savefile = FileAccess.open(savename, FileAccess.READ)
	#return save file found in file system
	return savefile
	
	
func delete_save(slot: int) -> bool:
	if slot < 1:
		return false

	var filename: String = "save_" + str(slot) + ".sav"
	var full_path: String = "user://" + filename
	if not FileAccess.file_exists(full_path):
		return false

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return false

	var err: int = dir.remove(filename)
	return err == OK


func copy_save(src_slot: int, dst_slot: int) -> bool:
	if src_slot < 1:
		return false
	if dst_slot < 1:
		return false
	if src_slot == dst_slot:
		return false

	var src_path: String = _get_save_file_path(src_slot)
	var dst_path: String = _get_save_file_path(dst_slot)
	if not FileAccess.file_exists(src_path):
		return false

	var src: FileAccess = FileAccess.open(src_path, FileAccess.READ)
	if src == null:
		return false

	var dst: FileAccess = FileAccess.open(dst_path, FileAccess.WRITE)
	if dst == null:
		src.close()
		return false

	var bytes: PackedByteArray = src.get_buffer(src.get_length())
	dst.store_buffer(bytes)
	src.close()
	dst.close()
	return true


func get_save_summary(slot: int) -> Dictionary:
	var path: String = _get_save_file_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var sections: Dictionary = _parse_sav_file(file)
	file.close()

	var member0: Dictionary = _get_section(sections, "characters.current_party_members.0")
	var stats: Dictionary = _get_section(sections, "game_statistics")
	var field_scene: Dictionary = _get_section(sections, "current_field_scene")

	return {
		"player_name": _sec_get_string(member0, "display_name", ""),
		"level": _sec_get_int(member0, "level", 0),
		"location": _sec_get_string(field_scene, "current_field_scene", ""),
		"money": _sec_get_int(stats, "money", 0),
		"time_played": _sec_get_int(stats, "time_played", 0),
		"times_saved": _sec_get_int(stats, "times_saved", 0)
	}


func _get_save_file_path(slot: int) -> String:
	return "user://save_" + str(slot) + ".sav"
	
	
	
	
	
	
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
	
	state_flags.clear()
	
	CharDataKeeper.party_members.clear()
	CharDataKeeper.outside_members.clear()
	
	Inventory.current_inventory.clear()
	
	QuestManager.current_quests.clear()
	QuestManager.completed_quests.clear()
	
	
	
func load_state_flags() -> void:
	state_flags.clear()

	var prefix: String = "state_flags."
	var flag_sections: Array[String] = []

	for sec_name in _loaded_save_sections.keys():
		var section_name: String = String(sec_name)
		if not section_name.begins_with(prefix):
			continue

		var suffix: String = section_name.substr(prefix.length())
		if not suffix.is_valid_int():
			continue

		flag_sections.append(section_name)

	flag_sections.sort_custom(func(a, b):
		var ia: int = int(a.substr(prefix.length()))
		var ib: int = int(b.substr(prefix.length()))
		return ia < ib
	)

	for section_name in flag_sections:
		var data: Dictionary = _get_section(_loaded_save_sections, section_name)
		var scene_filename: String = _sec_get_string(data, "scene_filename", "")
		var object_node_name: String = _sec_get_string(data, "object_node_name", "")
		if scene_filename == "":
			continue
		if object_node_name == "":
			continue

		state_flags.append(PackedStringArray([scene_filename, object_node_name]))
	
	

## Parses selected save file and sets the game statistics (in this global script) to the correct values
## Reads data under the [game_statistics] heading
func load_game_statistics()->void:
	var stats : Dictionary = _get_section(_loaded_save_sections, "game_statistics")
	if stats.is_empty():
		return
	
	time_played = _sec_get_int(stats, "time_played", 0)
	times_saved = _sec_get_int(stats, "times_saved", 0)
	times_loaded = _sec_get_int(stats, "times_loaded", 0)
	money = _sec_get_int(stats, "money", 0)
	quests_completed = _sec_get_int(stats, "quests_completed", 0)
	enemies_killed = _sec_get_int(stats, "enemies_killed", 0)
	party_member_deaths = _sec_get_int(stats, "party_member_deaths", 0)
	items_used = _sec_get_int(stats, "items_used", 0)
	skills_used = _sec_get_int(stats, "skills_used", 0)
	
## Parses the selected save file and sets up the Inventory.current_inventory.
## Reads data under the [inventory] heading
## Uses InventorySlot.new() to set up a new item slot
## Sets the InventorySlot.quantity using slot_qty
## Uses Registry.find_item_by_id(item_id) to set the item

	
## Parses the selected save file and sets up the Inventory.current_inventory.
## Reads data under the [inventory] heading
## Uses InventorySlot.new() to set up a new item slot
## Sets the InventorySlot.quantity using slot_qty
## Uses Registry.find_item_by_id(item_id) to set the item
func load_inventory()->void:
	Inventory.current_inventory.clear()

	var prefix : String = "inventory.item_slot_"
	var slot_sections : Array[String] = []
	for sec_name in _loaded_save_sections.keys():
		var s : String = String(sec_name)
		if s.begins_with(prefix):
			slot_sections.append(s)

	slot_sections.sort_custom(func(a, b):
		var ia : int = int(a.substr(prefix.length()))
		var ib : int = int(b.substr(prefix.length()))
		return ia < ib
	)

	for sec in slot_sections:
		var data : Dictionary = _get_section(_loaded_save_sections, sec)
		var qty : int = _sec_get_int(data, "qty", 0)
		var item_id : String = _sec_get_string(data, "item_id", "")
		if qty <= 0:
			continue
		if item_id == "":
			continue

		var item : Item = Registry.find_item_by_id(item_id)
		if item == null:
			continue

		var islot : InventorySlot = InventorySlot.new()
		islot.item = item
		islot.quantity = qty
		Inventory.current_inventory.append(islot)
		

## Parses the selected save file and sets up QuestManager.current_quests
## Reads data under [quests.current_quests]
## Uses Registry.find_quest_by_id(quest_id) to duplicate(true) quests into their respective arrays
## Though redundant, uses is_completed flag that proceeds quest_id to set the quest's is_complete flag
## Parses quest_step_id
	##the next actions_taken is what the quest step's actions taken is set to
	##the next is_completed is what the quest step's is_completed flag is set to
func load_current_quests()->void:
	var prefix : String = "quests.current."
	var quest_sections : Array[String] = []
	for sec_name in _loaded_save_sections.keys():
		var s : String = String(sec_name)
		if s.begins_with(prefix) and s.find(".steps.") == -1:
			quest_sections.append(s)

	quest_sections.sort()

	for qsec in quest_sections:
		var qdata : Dictionary = _get_section(_loaded_save_sections, qsec)
		var qid : String = _sec_get_string(qdata, "quest_id", "")
		if qid == "":
			continue

		var qtemplate : Quest = Registry.find_quest_by_id(qid)
		if qtemplate == null:
			continue

		var quest : Quest = qtemplate.duplicate(true) as Quest
		quest.current_step = _sec_get_int(qdata, "current_step", quest.current_step)
		quest.is_completed = _sec_get_bool(qdata, "is_completed", quest.is_completed)
		quest.repeatable = _sec_get_bool(qdata, "repeatable", quest.repeatable)

		for step_idx in range(quest.steps.size()):
			var ssec : String = qsec + ".steps." + str(step_idx)
			var sdata : Dictionary = _get_section(_loaded_save_sections, ssec)
			if sdata.is_empty():
				continue

			var step : QuestStep = quest.steps[step_idx]
			if step == null:
				continue

			var saved_step_id : String = _sec_get_string(sdata, "quest_step_id", "")
			if saved_step_id != "" and String(step.quest_step_id) != saved_step_id:
				continue

			step.actions_taken = _sec_get_int(sdata, "actions_taken", step.actions_taken)
			step.is_completed = _sec_get_bool(sdata, "is_completed", step.is_completed)

		QuestManager.current_quests.append(quest)


## Parses the selected save file and sets up QuestManager.completed_quests
## Reads data under [quests.completed_quests]
## Though redundant, uses is_completed flag that proceeds quest_id to set the quest's is_complete flag
## Uses Registry.find_quest_by_id(quest_id) to duplicate(true) quests into their respective arrays
## Parses quest_step_id
	##the next actions_taken is what the quest step's actions taken is set to
	##the next is_completed is what the quest step's is_completed flag is set to
func load_completed_quests()->void:
	var prefix : String = "quests.completed."
	var quest_sections : Array[String] = []
	for sec_name in _loaded_save_sections.keys():
		var s : String = String(sec_name)
		if s.begins_with(prefix) and s.find(".steps.") == -1:
			quest_sections.append(s)

	quest_sections.sort()

	for qsec in quest_sections:
		var qdata : Dictionary = _get_section(_loaded_save_sections, qsec)
		var qid : String = _sec_get_string(qdata, "quest_id", "")
		if qid == "":
			continue

		var qtemplate : Quest = Registry.find_quest_by_id(qid)
		if qtemplate == null:
			continue

		var quest : Quest = qtemplate.duplicate(true) as Quest
		quest.is_completed = _sec_get_bool(qdata, "is_completed", true)

		for step_idx in range(quest.steps.size()):
			var ssec : String = qsec + ".steps." + str(step_idx)
			var sdata : Dictionary = _get_section(_loaded_save_sections, ssec)
			if sdata.is_empty():
				continue

			var step : QuestStep = quest.steps[step_idx]
			if step == null:
				continue

			var saved_step_id : String = _sec_get_string(sdata, "quest_step_id", "")
			if saved_step_id != "" and String(step.quest_step_id) != saved_step_id:
				continue

			step.actions_taken = _sec_get_int(sdata, "actions_taken", step.actions_taken)
			step.is_completed = _sec_get_bool(sdata, "is_completed", step.is_completed)

		QuestManager.completed_quests.append(quest)
	
	
	
## parses until [characters.current_party_members] is found
## parses until actor_id found in save file, then uses Registry.find_party_member_by_id(actor_id)
## Uses Duplicate(true) using the matched data from all_party_members to put a party member into CharDataKeeper.party_members
## Parses and sets up level, current_exp, next_level_exp, total_exp, current_hp, current_sp
## When reaching mainhand, uses Registry.find_item_by_id to set the item in each equip slot until accy02
## Parses skills and sets the Skills array
## Prases perm stats and sets their values
## Repeats for each party member found within the CharDataKeeper.party_memebers array
func load_current_party_members()->void:
	var prefix : String = "characters.current_party_members."
	var member_sections : Array[String] = []
	for sec_name in _loaded_save_sections.keys():
		var s : String = String(sec_name)
		if s.begins_with(prefix):
			member_sections.append(s)

	member_sections.sort_custom(func(a, b):
		var ia_str : String = a.substr(prefix.length())
		var ib_str : String = b.substr(prefix.length())
		var ia : int = 0
		var ib : int = 0
		if ia_str.is_valid_int():
			ia = int(ia_str)
		if ib_str.is_valid_int():
			ib = int(ib_str)
		return ia < ib
	)

	for msec in member_sections:
		var data : Dictionary = _get_section(_loaded_save_sections, msec)
		var actor_id : String = _sec_get_string(data, "actor_id", "")
		if actor_id == "":
			continue

		var template : PartyMemberData = Registry.find_party_member_by_id(actor_id)
		if template == null:
			continue

		var pm : PartyMemberData = template.duplicate(true) as PartyMemberData

		pm.display_name = _sec_get_string(data, "display_name", pm.display_name)
		pm.level = _sec_get_int(data, "level", pm.level)
		pm.current_exp = _sec_get_int(data, "current_exp", pm.current_exp)
		pm.next_level_exp = _sec_get_int(data, "next_level_exp", pm.next_level_exp)
		pm.total_exp = _sec_get_int(data, "total_exp", pm.total_exp)

		pm.perm_max_hp_flat = _sec_get_int(data, "perm_max_hp_flat", pm.perm_max_hp_flat)
		pm.perm_max_sp_flat = _sec_get_int(data, "perm_max_sp_flat", pm.perm_max_sp_flat)
		pm.perm_atk_flat = _sec_get_int(data, "perm_atk_flat", pm.perm_atk_flat)
		pm.perm_def_flat = _sec_get_int(data, "perm_def_flat", pm.perm_def_flat)
		pm.perm_strength_flat = _sec_get_int(data, "perm_strength_flat", pm.perm_strength_flat)
		pm.perm_stamina_flat = _sec_get_int(data, "perm_stamina_flat", pm.perm_stamina_flat)
		pm.perm_agility_flat = _sec_get_int(data, "perm_agility_flat", pm.perm_agility_flat)
		pm.perm_magic_flat = _sec_get_int(data, "perm_magic_flat", pm.perm_magic_flat)
		pm.perm_luck_flat = _sec_get_int(data, "perm_luck_flat", pm.perm_luck_flat)

		pm.mainhand = _load_item_or_null(_sec_get_string(data, "mainhand", ""))
		pm.offhand = _load_item_or_null(_sec_get_string(data, "offhand", ""))
		pm.headslot = _load_item_or_null(_sec_get_string(data, "headslot", ""))
		pm.chestslot = _load_item_or_null(_sec_get_string(data, "chestslot", ""))
		pm.armslot = _load_item_or_null(_sec_get_string(data, "armslot", ""))
		pm.legslot = _load_item_or_null(_sec_get_string(data, "legslot", ""))
		pm.accy01 = _load_item_or_null(_sec_get_string(data, "accy01", ""))
		pm.accy02 = _load_item_or_null(_sec_get_string(data, "accy02", ""))
		pm.two_handing = _sec_get_bool(data, "two_handing", pm.two_handing)

		pm.skills.clear()
		var skill_pairs : Array = []
		for k in data.keys():
			var key : String = String(k)
			if not key.begins_with("skill."):
				continue
			var idx_str : String = key.substr("skill.".length())
			if not idx_str.is_valid_int():
				continue
			skill_pairs.append([int(idx_str), _sec_get_string(data, key, "")])
		skill_pairs.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
		for pair in skill_pairs:
			var sid : String = String(pair[1])
			if sid == "":
				continue
			var skill : Skill = Registry.find_skill_by_id(sid)
			if skill != null:
				pm.skills.append(skill)

		pm.status_effects.clear()
		var status_pairs : Array = []
		for k in data.keys():
			var key : String = String(k)
			if not key.begins_with("status."):
				continue
			var idx_str : String = key.substr("status.".length())
			if not idx_str.is_valid_int():
				continue
			status_pairs.append([int(idx_str), _sec_get_string(data, key, "")])
		status_pairs.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
		for pair in status_pairs:
			var stid : String = String(pair[1])
			if stid == "":
				continue
			var status : StatusEffect = Registry.instantiate_status(StringName(stid))
			if status != null:
				pm.status_effects.append(status)

		pm.rebuild_base_stats()
		pm.current_hp = _sec_get_int(data, "current_hp", pm.current_hp)
		pm.current_sp = _sec_get_int(data, "current_sp", pm.current_sp)
		pm.clamp_vitals()

		CharDataKeeper.party_members.append(pm)
	
## parses until [characters.outside_party_members] is found
## parses until actor_id found in save file, then uses Registry.find_party_member_by_id(actor_id)
## Uses Duplicate(true) using the matched data from all_party_members to put a party member into CharDataKeeper.outside_members
## Parses and sets up level, current_exp, next_level_exp, total_exp, current_hp, current_sp
## When reaching mainhand, uses Registry.find_item_by_id to set the item in each equip slot until accy02
## Parses skills and sets the Skills array
## Prases perm stats and sets their values
## Repeats for each party member found within the CharDataKeeper.outside_party_members array
func load_outside_party_members()->void:
	var prefix : String = "characters.outside_party_members."
	var member_sections : Array[String] = []
	for sec_name in _loaded_save_sections.keys():
		var s : String = String(sec_name)
		if s.begins_with(prefix):
			member_sections.append(s)

	member_sections.sort_custom(func(a, b):
		var ia_str : String = a.substr(prefix.length())
		var ib_str : String = b.substr(prefix.length())
		var ia : int = 0
		var ib : int = 0
		if ia_str.is_valid_int():
			ia = int(ia_str)
		if ib_str.is_valid_int():
			ib = int(ib_str)
		return ia < ib
	)

	for msec in member_sections:
		var data : Dictionary = _get_section(_loaded_save_sections, msec)
		var actor_id : String = _sec_get_string(data, "actor_id", "")
		if actor_id == "":
			continue

		var template : PartyMemberData = Registry.find_party_member_by_id(actor_id)
		if template == null:
			continue

		var pm : PartyMemberData = template.duplicate(true) as PartyMemberData

		pm.display_name = _sec_get_string(data, "display_name", pm.display_name)
		pm.level = _sec_get_int(data, "level", pm.level)
		pm.current_exp = _sec_get_int(data, "current_exp", pm.current_exp)
		pm.next_level_exp = _sec_get_int(data, "next_level_exp", pm.next_level_exp)
		pm.total_exp = _sec_get_int(data, "total_exp", pm.total_exp)

		pm.perm_max_hp_flat = _sec_get_int(data, "perm_max_hp_flat", pm.perm_max_hp_flat)
		pm.perm_max_sp_flat = _sec_get_int(data, "perm_max_sp_flat", pm.perm_max_sp_flat)
		pm.perm_atk_flat = _sec_get_int(data, "perm_atk_flat", pm.perm_atk_flat)
		pm.perm_def_flat = _sec_get_int(data, "perm_def_flat", pm.perm_def_flat)
		pm.perm_strength_flat = _sec_get_int(data, "perm_strength_flat", pm.perm_strength_flat)
		pm.perm_stamina_flat = _sec_get_int(data, "perm_stamina_flat", pm.perm_stamina_flat)
		pm.perm_agility_flat = _sec_get_int(data, "perm_agility_flat", pm.perm_agility_flat)
		pm.perm_magic_flat = _sec_get_int(data, "perm_magic_flat", pm.perm_magic_flat)
		pm.perm_luck_flat = _sec_get_int(data, "perm_luck_flat", pm.perm_luck_flat)

		pm.mainhand = _load_item_or_null(_sec_get_string(data, "mainhand", ""))
		pm.offhand = _load_item_or_null(_sec_get_string(data, "offhand", ""))
		pm.headslot = _load_item_or_null(_sec_get_string(data, "headslot", ""))
		pm.chestslot = _load_item_or_null(_sec_get_string(data, "chestslot", ""))
		pm.armslot = _load_item_or_null(_sec_get_string(data, "armslot", ""))
		pm.legslot = _load_item_or_null(_sec_get_string(data, "legslot", ""))
		pm.accy01 = _load_item_or_null(_sec_get_string(data, "accy01", ""))
		pm.accy02 = _load_item_or_null(_sec_get_string(data, "accy02", ""))
		pm.two_handing = _sec_get_bool(data, "two_handing", pm.two_handing)

		pm.skills.clear()
		var skill_pairs : Array = []
		for k in data.keys():
			var key : String = String(k)
			if not key.begins_with("skill."):
				continue
			var idx_str : String = key.substr("skill.".length())
			if not idx_str.is_valid_int():
				continue
			skill_pairs.append([int(idx_str), _sec_get_string(data, key, "")])
		skill_pairs.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
		for pair in skill_pairs:
			var sid : String = String(pair[1])
			if sid == "":
				continue
			var skill : Skill = Registry.find_skill_by_id(sid)
			if skill != null:
				pm.skills.append(skill)

		pm.status_effects.clear()
		var status_pairs : Array = []
		for k in data.keys():
			var key : String = String(k)
			if not key.begins_with("status."):
				continue
			var idx_str : String = key.substr("status.".length())
			if not idx_str.is_valid_int():
				continue
			status_pairs.append([int(idx_str), _sec_get_string(data, key, "")])
		status_pairs.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
		for pair in status_pairs:
			var stid : String = String(pair[1])
			if stid == "":
				continue
			var status : StatusEffect = Registry.instantiate_status(StringName(stid))
			if status != null:
				pm.status_effects.append(status)

		pm.rebuild_base_stats()
		pm.current_hp = _sec_get_int(data, "current_hp", pm.current_hp)
		pm.current_sp = _sec_get_int(data, "current_sp", pm.current_sp)
		pm.clamp_vitals()

		CharDataKeeper.outside_members.append(pm)

## Loads the saved game scene. Needs to be done last so party members are loaded first
## Parses the current_field_scene, searches the filesystem under res://field/scenes/field_scenes and subfolders for the filename. Uses SceneManager.load_scene_by_filename(filename)
## Instantiates CharDataKeeper.party_members at position_x and position_y (as if just spawning in, should be a simliar action to SceneManager.make_party_at_spawn_point(), except it uses the x and y locations instead of the spawn point. Player always faces down when loading.
func load_saved_game_field_scene()->void:
	
	SceneManager.set_field_enemies_paused(true)

	var sec : Dictionary = _get_section(_loaded_save_sections, "current_field_scene")
	if sec.is_empty():
		return

	var filename : String = _sec_get_string(sec, "current_field_scene", "")
	if filename == "":
		return

	var pos_x : float = _sec_get_float(sec, "position_x", 0.0)
	var pos_y : float = _sec_get_float(sec, "position_y", 0.0)
	var spawn_pos : Vector2 = Vector2(pos_x, pos_y)

	var scene_path : String = _find_field_scene_path_by_filename(filename)
	if scene_path == "":
		push_error("SaveManager: field scene not found for filename: " + filename)
		return

	var main : Main = SceneManager.main_scene
	if main == null:
		return

	# Clear out the field party nodes array so it can be populated again
	CharDataKeeper.field_party_nodes.clear()
	CharDataKeeper.controlled_character = null

	# Remove any existing field or title scenes under the container
	for child in main.field_scene_container.get_children():
		child.queue_free()
	main.current_field_scene = null
	main.title_scene = null

	# Load and instantiate the saved field scene
	var new_scene : FieldScene = load(scene_path).instantiate() as FieldScene
	main.field_scene_container.add_child(new_scene)
	main.current_field_scene = new_scene
	
	# Registers the new scene within CutsceneManager
	CutsceneManager.register_field_scene(main.current_field_scene)
	
	main.field_root.visible = true
	main.field_root.process_mode = Node.PROCESS_MODE_INHERIT
	GameState.gamestate = GameState.State.FIELD

	_make_party_at_position(new_scene, spawn_pos)
	main.field_camera_rig.activate()
	main.field_camera_rig.follow_player()
	SceneManager.set_field_enemies_paused(false)


func _make_party_at_position(fscene : FieldScene, pos : Vector2) -> void:
	if fscene == null:
		return
	if CharDataKeeper.party_members.is_empty():
		return

	var last_actor : FieldPartyMember = null

	for i in range(CharDataKeeper.party_members.size()):
		if i > CharDataKeeper.party_size - 1:
			break
		var pmember : PartyMemberData = CharDataKeeper.party_members[i]
		if pmember == null:
			continue

		var pmemberscene : FieldPartyMember = pmember.field_scene.instantiate() as FieldPartyMember
		fscene.party.add_child(pmemberscene)
		pmemberscene.name = pmember.get_display_name()
		pmemberscene.field_actor_id = pmember.actor_id
		pmemberscene.force_face_direction(Vector2.DOWN)

		if i == 0:
			CharDataKeeper.controlled_character = pmemberscene
			pmemberscene.global_position = pos
			pmemberscene.set_controlled_on()
			pmemberscene.is_controlled = true
			last_actor = pmemberscene
			CharDataKeeper.field_party_nodes.append(pmemberscene)
		else:
			pmemberscene.actor_to_follow = last_actor
			pmemberscene.is_controlled = false
			pmemberscene.is_following = true
			pmemberscene.set_controlled_off()
			pmemberscene.global_position = last_actor.global_position + Vector2(0, -1)
			last_actor = pmemberscene
			CharDataKeeper.field_party_nodes.append(pmemberscene)

func _find_field_scene_path_by_filename(filename : String) -> String:
	var fname : String = filename.get_basename()
	var dir_stack : Array[String] = [FIELD_SCENES_ROOT_DIR]

	while dir_stack.size() > 0:
		var dir_path : String = dir_stack.pop_back()

		for subdir_name in DirAccess.get_directories_at(dir_path):
			dir_stack.append(dir_path.path_join(subdir_name))

		for file_name in DirAccess.get_files_at(dir_path):
			if not file_name.ends_with(".tscn"):
				continue
			if file_name.get_basename() == fname:
				return dir_path.path_join(file_name)

	return ""
#endregion Loading

#region Loading Helpers

func _load_item_or_null(item_id : String) -> Item:
	if item_id == "":
		return null
	return Registry.find_item_by_id(item_id)


func _parse_sav_file(file: FileAccess) -> Dictionary:
	var sections: Dictionary = {}
	var current_section: String = ""

	while not file.eof_reached():
		var raw_line: String = file.get_line().strip_edges()
		if raw_line == "":
			continue
		if raw_line.begins_with(";") or raw_line.begins_with("#"):
			continue

		if raw_line.begins_with("[") and raw_line.ends_with("]") and raw_line.length() >= 2:
			current_section = raw_line.substr(1, raw_line.length() - 2)
			if not sections.has(current_section):
				sections[current_section] = {}
			continue

		if current_section == "":
			continue

		var equals_index: int = raw_line.find("=")
		if equals_index == -1:
			continue

		var key: String = raw_line.substr(0, equals_index).strip_edges()
		var raw_value: String = raw_line.substr(equals_index + 1).strip_edges()
		var decoded_value: Variant = _decode_value(raw_value)

		var section_dict: Dictionary = sections.get(current_section, {})
		section_dict[key] = decoded_value
		sections[current_section] = section_dict

	return sections




func _decode_value(raw: String) -> Variant:
	if raw == "":
		return ""

	if raw == "true":
		return true
	if raw == "false":
		return false

	if raw.begins_with("\"") and raw.ends_with("\"") and raw.length() >= 2:
		return _decode_string(raw.substr(1, raw.length() - 2))

	if raw.is_valid_int():
		return int(raw)
	if raw.is_valid_float():
		return float(raw)

	return raw



func _decode_string(encoded: String) -> String:
	var output: String = ""
	var index: int = 0

	while index < encoded.length():
		var ch: String = encoded[index]

		if ch == "\\" and index + 1 < encoded.length():
			var next_ch: String = encoded[index + 1]
			if next_ch == "n":
				output += "\n"
			elif next_ch == "\\":
				output += "\\"
			elif next_ch == "\"":
				output += "\""
			else:
				output += next_ch

			index += 2
			continue

		output += ch
		index += 1

	return output



func _get_section(all_sections : Dictionary, _name : String) -> Dictionary:
	if all_sections.has(_name):
		var v : Variant = all_sections[_name]
		if typeof(v) == TYPE_DICTIONARY:
			return v
	return {}


func _sec_get_string(sec : Dictionary, key : String, fallback : String) -> String:
	if not sec.has(key):
		return fallback
	var v : Variant = sec[key]
	if typeof(v) == TYPE_STRING:
		return String(v)
	if typeof(v) == TYPE_STRING_NAME:
		return String(v)
	return str(v)


func _sec_get_int(sec : Dictionary, key : String, fallback : int) -> int:
	if not sec.has(key):
		return fallback
	var v : Variant = sec[key]
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_FLOAT:
		return int(v)
	if typeof(v) == TYPE_STRING and String(v).is_valid_int():
		return int(String(v))
	return fallback


func _sec_get_float(sec : Dictionary, key : String, fallback : float) -> float:
	if not sec.has(key):
		return fallback
	var v : Variant = sec[key]
	if typeof(v) == TYPE_FLOAT:
		return float(v)
	if typeof(v) == TYPE_INT:
		return float(v)
	if typeof(v) == TYPE_STRING and String(v).is_valid_float():
		return float(String(v))
	return fallback


func _sec_get_bool(sec : Dictionary, key : String, fallback : bool) -> bool:
	if not sec.has(key):
		return fallback
	var v : Variant = sec[key]
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	if typeof(v) == TYPE_INT:
		return int(v) != 0
	if typeof(v) == TYPE_STRING:
		var s : String = String(v).to_lower()
		if s == "true":
			return true
		if s == "false":
			return false
	return fallback

#endregion Loading
#endregion Loading Helpers

#region State Flags


func has_state_flag(scene_filename: String, object_node_name: String) -> bool:
	if scene_filename == "":
		return false
	if object_node_name == "":
		return false

	for entry in state_flags:
		if String(entry[0]) == scene_filename and String(entry[1]) == object_node_name:
			return true

	return false

func set_state_flag(scene_filename: String, object_node_name: String) -> void:
	if scene_filename == "":
		return
	if object_node_name == "":
		return
	if has_state_flag(scene_filename, object_node_name):
		return

	state_flags.append(PackedStringArray([scene_filename, object_node_name]))


func clear_state_flag(scene_filename: String, object_node_name: String) -> void:
	if scene_filename == "":
		return
	if object_node_name == "":
		return

	for i in range(state_flags.size() - 1, -1, -1):
		var entry: PackedStringArray = state_flags[i]
		if String(entry[0]) == scene_filename and String(entry[1]) == object_node_name:
			state_flags.remove_at(i)


func get_state_flags() -> Array[PackedStringArray]:
	return state_flags.duplicate()


func set_state_flags(new_state_flags: Array[PackedStringArray]) -> void:
	state_flags.clear()

	for entry in new_state_flags:
		if entry.size() != 2:
			continue

		var scene_filename: String = String(entry[0])
		var object_node_name: String = String(entry[1])

		if scene_filename == "":
			continue
		if object_node_name == "":
			continue

		state_flags.append(PackedStringArray([scene_filename, object_node_name]))


#endregion




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
