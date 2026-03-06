class_name SaveLoadMenu extends CanvasLayer
## Menu used for managing saves in game. menu_mode determines what the menu does.

@onready var exit_button: Button = %ExitButton
@onready var copy_button: Button = %CopyButton
@onready var menu_title_label: Label = %MenuTitleLabel
@onready var erase_button: Button = %EraseButton
@onready var confirm_window: SaveLoadConfirmWindow = %ConfirmWindow
@onready var save_slot_vbox: VBoxContainer = %SaveSlotVbox

enum MODE {SAVE, LOAD}
var _menu_mode: MODE = MODE.SAVE
@export var menu_mode : MODE:
	get:
		return _menu_mode
	set(value):
		if _menu_mode == value:
			return
		_menu_mode = value
		set_menu_title()

enum SUB_MODE {NONE, SAVE_CONFIRM, LOAD_CONFIRM, COPY, COPYING, COPYING_CONFIRM, ERASE, ERASE_CONFIRM}
var _sub_mode: SUB_MODE = SUB_MODE.NONE
@export var sub_mode : SUB_MODE:
	get:
		return _sub_mode
	set(value):
		if _sub_mode == value:
			return
		_sub_mode = value
		set_menu_title()

var max_saves : int = 10

var save_slot_index : Array[SaveSlot] = []

var selected_save_slot_number : int = 1

var copy_from_slot_number: int = 0
var copy_to_slot_number: int = 0

var last_game_state : GameState.State

const SAVE_SLOT = preload("uid://imgxh1mfdd2s")

func _ready()->void:
	visible = false
	confirm_window.visible = false
	exit_button.pressed.connect(on_exit_button_pressed)
	copy_button.pressed.connect(on_copy_button_pressed)
	erase_button.pressed.connect(on_erase_button_pressed)
	set_menu_title()

func set_menu_title()->void:
	match menu_mode:
		MODE.SAVE:
			match sub_mode:
				SUB_MODE.NONE:
					menu_title_label.text = "SAVE GAME"
				SUB_MODE.SAVE_CONFIRM:
					menu_title_label.text = "SAVE GAME"
				SUB_MODE.COPY:
					menu_title_label.text = "COPY"
				SUB_MODE.COPYING:
					menu_title_label.text = "COPYING"
				SUB_MODE.COPYING_CONFIRM:
					menu_title_label.text = "COPYING"
				SUB_MODE.ERASE:
					menu_title_label.text = "ERASE"
				SUB_MODE.ERASE_CONFIRM:
					menu_title_label.text = "ERASE"
		MODE.LOAD:
			match sub_mode:
				SUB_MODE.NONE:
					menu_title_label.text = "LOAD GAME"
				SUB_MODE.LOAD_CONFIRM:
					menu_title_label.text = "LOAD GAME"
				SUB_MODE.COPY:
					menu_title_label.text = "COPY"
				SUB_MODE.COPYING:
					menu_title_label.text = "COPYING"
				SUB_MODE.COPYING_CONFIRM:
					menu_title_label.text = "COPYING"
				SUB_MODE.ERASE:
					menu_title_label.text = "ERASE"
				SUB_MODE.ERASE_CONFIRM:
					menu_title_label.text = "ERASE"

func show_saveload_menu()->void:
	if CharDataKeeper.controlled_character:
		CharDataKeeper.controlled_character.state_machine.force_state_by_name("idle")
		CharDataKeeper.controlled_character.direction = Vector2.ZERO
		CharDataKeeper.controlled_character.velocity = Vector2.ZERO

	_reset_copy_ui_state()
	sub_mode = SUB_MODE.NONE

	visible = true
	confirm_window.visible = false
	last_game_state = GameState.gamestate
	if last_game_state == GameState.State.FIELD:
		SceneManager.set_field_enemies_paused(true)
	GameState.gamestate = GameState.State.SAVELOADMENU

	propagate_saves()
	call_deferred("_focus_on_open")

func hide_saveload_menu(restore_previous_state: bool = true) -> void:
	visible = false
	confirm_window.visible = false
	if restore_previous_state:
		if last_game_state == GameState.State.FIELD:
			SceneManager.set_field_enemies_paused(false)
		GameState.gamestate = last_game_state
	_reset_copy_ui_state()

func show_confirm_window()->void:
	confirm_window.visible = true

func hide_confirm_window()->void:
	confirm_window.visible = false

func propagate_saves()->void:
	clear_save_slots()
	save_slot_index.clear()

	for slot_number in range(1, max_saves + 1):
		var slot: SaveSlot = SAVE_SLOT.instantiate() as SaveSlot
		save_slot_vbox.add_child(slot)
		slot.name = "SaveSlot" + str(slot_number)
		slot.set_slot_number(slot_number)
		slot.set_button_disabled(false)
		slot.is_active = false

		var summary: Dictionary = SaveManager.get_save_summary(slot_number)
		if summary.is_empty():
			slot.apply_empty_slot()
		else:
			slot.set_has_save_file(true)
			slot.set_player_name_label(String(summary.get("player_name", "")))
			slot.set_location_label(String(summary.get("location", "")))
			slot.set_money_amount(int(summary.get("money", 0)))
			slot.set_time_amount(_format_time_hhh_mm_ss(int(summary.get("time_played", 0))))
			slot.set_lv_amount(int(summary.get("level", 0)))
			slot.set_save_amount(int(summary.get("times_saved", 0)))

		save_slot_index.append(slot)

	_apply_copy_ui_state_if_needed()
	_setup_save_slot_focus_neighbors()

func clear_save_slots()->void:
	for child in save_slot_vbox.get_children():
		child.free()

func on_exit_button_pressed()->void:
	hide_saveload_menu()
	if GameMenu.menu_state == "OPTIONS_LOAD_MENU_OPEN":
		GameMenu.menu_state = "OPTIONS_OPEN"

func on_copy_button_pressed()->void:
	if sub_mode == SUB_MODE.COPY or sub_mode == SUB_MODE.COPYING:
		_reset_copy_ui_state()
		sub_mode = SUB_MODE.NONE
		call_deferred("focus_slot", selected_save_slot_number)
		return

	_reset_copy_ui_state()
	sub_mode = SUB_MODE.COPY
	call_deferred("focus_slot", selected_save_slot_number)

func on_erase_button_pressed()->void:
	_reset_copy_ui_state()
	if sub_mode == SUB_MODE.ERASE:
		sub_mode = SUB_MODE.NONE
		call_deferred("focus_slot", selected_save_slot_number)
		return
	sub_mode = SUB_MODE.ERASE
	call_deferred("focus_slot", selected_save_slot_number)

func focus_first_save_slot()->void:
	focus_slot(1)

func focus_last_used_save_slot()->void:
	var last_used_slot: int = SaveManager.last_used_save_slot_number
	if last_used_slot < 1:
		focus_slot(1)
		return
	if last_used_slot > max_saves:
		focus_slot(1)
		return
	focus_slot(last_used_slot)

func focus_slot(slot_number: int) -> void:
	if save_slot_index.is_empty():
		return
	var clamped_slot: int = slot_number
	if clamped_slot < 1:
		clamped_slot = 1
	if clamped_slot > max_saves:
		clamped_slot = max_saves
	var index: int = clamped_slot - 1
	if index < 0 or index >= save_slot_index.size():
		return
	save_slot_index[index].grab_button_focus()

func set_selected_save_slot(slot_number: int) -> void:
	selected_save_slot_number = slot_number

func on_slot_confirm(slot_number: int, slot_has_save: bool) -> void:
	set_selected_save_slot(slot_number)

	match sub_mode:
		SUB_MODE.NONE:
			if menu_mode == MODE.SAVE:
				sub_mode = SUB_MODE.SAVE_CONFIRM
				_open_confirm_window("SAVE TO SLOT " + str(slot_number) + "?")
				return

			if menu_mode == MODE.LOAD:
				if not slot_has_save:
					return
				sub_mode = SUB_MODE.LOAD_CONFIRM
				_open_confirm_window("LOAD THIS GAME?")
				return

		SUB_MODE.COPY:
			if not slot_has_save:
				return
			copy_from_slot_number = slot_number
			copy_to_slot_number = 0
			sub_mode = SUB_MODE.COPYING
			_apply_copy_ui_state_if_needed()
			return

		SUB_MODE.COPYING:
			if copy_from_slot_number == 0:
				return
			if slot_number == copy_from_slot_number:
				return
			copy_to_slot_number = slot_number
			sub_mode = SUB_MODE.COPYING_CONFIRM
			_open_confirm_window("COPY TO SLOT " + str(slot_number) + "?")
			return

		SUB_MODE.ERASE:
			if not slot_has_save:
				return
			sub_mode = SUB_MODE.ERASE_CONFIRM
			_open_confirm_window("ERASE THIS GAME?")
			return

		_:
			return

func on_confirm_accepted() -> void:
	match sub_mode:
		SUB_MODE.SAVE_CONFIRM:
			hide_confirm_window()
			SaveManager.save_game(selected_save_slot_number)
			hide_saveload_menu()
			return

		SUB_MODE.LOAD_CONFIRM:
			hide_confirm_window()
			SceneManager.set_field_enemies_paused(true)
			if last_game_state == GameState.State.GAMEMENU:
				_force_close_game_menu_for_load()

			GameState.gamestate = GameState.State.LOADING
			hide_saveload_menu(false)
			SaveManager.load_game(selected_save_slot_number)
			return

		SUB_MODE.COPYING_CONFIRM:
			hide_confirm_window()
			SaveManager.copy_save(copy_from_slot_number, copy_to_slot_number)
			sub_mode = SUB_MODE.COPY
			propagate_saves()
			call_deferred("focus_slot", copy_from_slot_number)
			return

		SUB_MODE.ERASE_CONFIRM:
			hide_confirm_window()
			SaveManager.delete_save(selected_save_slot_number)
			sub_mode = SUB_MODE.ERASE
			propagate_saves()
			call_deferred("focus_slot", selected_save_slot_number)
			return

		_:
			hide_confirm_window()
			sub_mode = SUB_MODE.NONE
			call_deferred("focus_slot", selected_save_slot_number)

func on_confirm_cancelled() -> void:
	hide_confirm_window()

	match sub_mode:
		SUB_MODE.SAVE_CONFIRM:
			sub_mode = SUB_MODE.NONE
			call_deferred("focus_slot", selected_save_slot_number)
			return

		SUB_MODE.LOAD_CONFIRM:
			sub_mode = SUB_MODE.NONE
			call_deferred("focus_slot", selected_save_slot_number)
			return

		SUB_MODE.COPYING_CONFIRM:
			sub_mode = SUB_MODE.COPYING
			_apply_copy_ui_state_if_needed()
			call_deferred("focus_slot", copy_to_slot_number)
			return

		SUB_MODE.ERASE_CONFIRM:
			sub_mode = SUB_MODE.ERASE
			call_deferred("focus_slot", selected_save_slot_number)
			return

		_:
			sub_mode = SUB_MODE.NONE
			call_deferred("focus_slot", selected_save_slot_number)

func _open_confirm_window(message_text: String) -> void:
	confirm_window.set_confirm_text(message_text)
	show_confirm_window()
	confirm_window.focus_default_button()

func _copy_save_file(from_slot_number: int, to_slot_number: int) -> void:
	if from_slot_number < 1:
		return
	if to_slot_number < 1:
		return
	if from_slot_number > max_saves:
		return
	if to_slot_number > max_saves:
		return
	if from_slot_number == to_slot_number:
		return

	var src_path: String = _get_save_path(from_slot_number)
	var dst_path: String = _get_save_path(to_slot_number)
	if not FileAccess.file_exists(src_path):
		return

	var src: FileAccess = FileAccess.open(src_path, FileAccess.READ)
	if src == null:
		return
	var dst: FileAccess = FileAccess.open(dst_path, FileAccess.WRITE)
	if dst == null:
		src.close()
		return

	var bytes: PackedByteArray = src.get_buffer(src.get_length())
	dst.store_buffer(bytes)
	src.close()
	dst.close()

func _erase_save_file(slot_number: int) -> void:
	if slot_number < 1:
		return
	if slot_number > max_saves:
		return

	var filename: String = "save_" + str(slot_number) + ".sav"
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if not FileAccess.file_exists("user://" + filename):
		return
	dir.remove(filename)

func _read_save_summary(slot_number: int) -> Dictionary:
	var path: String = _get_save_path(slot_number)
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var sections: Dictionary = SaveManager._parse_sav_file(file)
	file.close()

	var member0: Dictionary = SaveManager._get_section(sections, "characters.current_party_members.0")
	var stats: Dictionary = SaveManager._get_section(sections, "game_statistics")
	var field_scene: Dictionary = SaveManager._get_section(sections, "current_field_scene")

	return {
		"player_name": SaveManager._sec_get_string(member0, "display_name", ""),
		"level": SaveManager._sec_get_int(member0, "level", 0),
		"location": SaveManager._sec_get_string(field_scene, "current_field_scene", ""),
		"money": SaveManager._sec_get_int(stats, "money", 0),
		"time_played": SaveManager._sec_get_int(stats, "time_played", 0),
		"times_saved": SaveManager._sec_get_int(stats, "times_saved", 0)
	}

func _get_save_path(slot_number: int) -> String:
	return "user://save_" + str(slot_number) + ".sav"

func _format_time_hhh_mm_ss(total_seconds: int) -> String:
	var clamped_seconds: int = total_seconds
	if clamped_seconds < 0:
		clamped_seconds = 0

	var hours: int = clamped_seconds / 3600
	var minutes: int = (clamped_seconds / 60) % 60
	var seconds: int = clamped_seconds % 60

	return str(hours).pad_zeros(3) + ":" + str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)

func _focus_on_open() -> void:
	if last_game_state != GameState.State.STARTMENU:
		focus_first_save_slot()
		return
	focus_last_used_save_slot()

func _reset_copy_ui_state() -> void:
	copy_from_slot_number = 0
	copy_to_slot_number = 0

	for slot in save_slot_index:
		slot.is_active = false
		slot.set_button_disabled(false)
		
func _apply_copy_ui_state_if_needed() -> void:
	if sub_mode != SUB_MODE.COPYING:
		return
	if copy_from_slot_number < 1:
		return
	if copy_from_slot_number > save_slot_index.size():
		return

	var source_slot: SaveSlot = save_slot_index[copy_from_slot_number - 1]
	source_slot.is_active = true
	source_slot.set_button_disabled(false)

func _unhandled_input(_event: InputEvent) -> void:
	if GameState.gamestate != GameState.State.SAVELOADMENU:
		return

	if not Input.is_action_just_pressed("cancel_input"):
		return

	if confirm_window.visible:
		on_confirm_cancelled()
		return

	match sub_mode:
		SUB_MODE.NONE:
			hide_saveload_menu()
			if GameMenu.menu_state == "OPTIONS_LOAD_MENU_OPEN":
				GameMenu.menu_state = "OPTIONS_OPEN"
		SUB_MODE.COPY:
			_reset_copy_ui_state()
			sub_mode = SUB_MODE.NONE
			call_deferred("focus_slot", selected_save_slot_number)
		SUB_MODE.COPYING:
			_reset_copy_ui_state()
			sub_mode = SUB_MODE.COPY
			call_deferred("focus_slot", selected_save_slot_number)
		SUB_MODE.ERASE:
			sub_mode = SUB_MODE.NONE
			call_deferred("focus_slot", selected_save_slot_number)
		_:
			sub_mode = SUB_MODE.NONE
			call_deferred("focus_slot", selected_save_slot_number)

func _setup_save_slot_focus_neighbors() -> void:
	if save_slot_index.is_empty():
		return

	var first_slot_button: Button = save_slot_index[0].get_node("Button") as Button
	var first_slot_button_path: NodePath = first_slot_button.get_path()

	var exit_button_path: NodePath = exit_button.get_path()
	var copy_button_path: NodePath = copy_button.get_path()
	var erase_button_path: NodePath = erase_button.get_path()

	# Bottom row: wrap between EXIT, COPY, ERASE (left and right)
	exit_button.focus_neighbor_left = erase_button_path
	exit_button.focus_neighbor_right = copy_button_path

	copy_button.focus_neighbor_left = exit_button_path
	copy_button.focus_neighbor_right = erase_button_path

	erase_button.focus_neighbor_left = copy_button_path
	erase_button.focus_neighbor_right = exit_button_path

	# Bottom row: up and down go to the first save slot
	exit_button.focus_neighbor_top = first_slot_button_path
	exit_button.focus_neighbor_bottom = first_slot_button_path

	copy_button.focus_neighbor_top = first_slot_button_path
	copy_button.focus_neighbor_bottom = first_slot_button_path

	erase_button.focus_neighbor_top = first_slot_button_path
	erase_button.focus_neighbor_bottom = first_slot_button_path

	# Save slots: left and right stay on the same slot button
	# Up and down move to previous and next slot
	# First slot up goes to EXIT
	# Last slot down goes to EXIT
	for slot_index in range(save_slot_index.size()):
		var slot: SaveSlot = save_slot_index[slot_index]
		var slot_button: Button = slot.get_node("Button") as Button
		var slot_button_path: NodePath = slot_button.get_path()

		slot_button.focus_neighbor_left = slot_button_path
		slot_button.focus_neighbor_right = slot_button_path

		if slot_index == 0:
			slot_button.focus_neighbor_top = exit_button_path
		else:
			var previous_button: Button = save_slot_index[slot_index - 1].get_node("Button") as Button
			slot_button.focus_neighbor_top = previous_button.get_path()

		if slot_index == save_slot_index.size() - 1:
			slot_button.focus_neighbor_bottom = exit_button_path
		else:
			var next_button: Button = save_slot_index[slot_index + 1].get_node("Button") as Button
			slot_button.focus_neighbor_bottom = next_button.get_path()


func _force_close_game_menu_for_load() -> void:
	get_viewport().gui_release_focus()
	GameMenu.current_selected_party_member = null
	GameMenu.selected_skill_button = null
	GameMenu.selected_skill = null
	GameMenu.last_selected_skills_option_button = null
	GameMenu.last_top_level_stats_focused = null

	# Close any overlays first
	GameMenu.sort_order.force_close_for_load()

	# Close sub menus
	GameMenu.options.force_close_for_load()
	GameMenu.quests.force_close_for_load()
	GameMenu.stats.force_close_for_load()
	GameMenu.equip.force_close_for_load()
	GameMenu.inventory.force_close_for_load()
	GameMenu.skills.force_close_for_load()

	# Close the top level UI last (positioners, money, etc)
	GameMenu.top_level.force_close_for_load()

	GameMenu.menu_state = "TOP_MENU_CLOSED"
