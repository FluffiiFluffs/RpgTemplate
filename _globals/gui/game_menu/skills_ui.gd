class_name SkillsUI extends Control

@onready var hider: PanelContainer = %Hider
@onready var panel_container: PanelContainer = %PanelContainer
@onready var stats_portrait: TextureRect = %StatsPortrait
@onready var use_button: SkillsOptionsButton = %UseButton
@onready var sort_button: SkillsOptionsButton = %SortButton
@onready var reorder_button: SkillsOptionsButton = %ReorderButton
@onready var exit_button: SkillsOptionsButton = %ExitButton
@onready var options_button_h_box: HBoxContainer = $PanelContainer/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer
@onready var grid_container: GridContainer = %GridContainer
@onready var description_label: Label = %DescriptionLabel
@onready var cost_value_label: Label = $PanelContainer/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/PanelContainer2/HBoxContainer/CostValue
@onready var cost_title_label: Label = %CostTitleLabel

const HIDDEN_POSITION: Vector2 = Vector2(0, -224)
const VISIBLE_POSITION: Vector2 = Vector2(0, 0)

var use_sorted_display: bool = false


func _ready() -> void:
	hider.queue_free()
	panel_container.visible = false
	panel_container.position = HIDDEN_POSITION

	clear_skill_buttons()
	reset_skill_details()
	update_option_buttons_state(null)

	use_button.button.pressed.connect(on_use_button_pressed)
	sort_button.button.pressed.connect(on_sort_button_pressed)
	reorder_button.button.pressed.connect(on_reorder_button_pressed)
	exit_button.button.pressed.connect(on_exit_button_pressed)

	GameMenu.setup_horizontal_focus_neighbors(options_button_h_box)


func enter_skills_selection() -> void:
	if !GameMenu.top_level.party_h_box_container.get_children().is_empty():
		GameMenu.top_level.skills_button.is_active = true
		GameMenu.last_top_button_focused = GameMenu.top_level.skills_button
		GameMenu.top_level.focus_last_top_level_stats()
		GameMenu.menu_state = "SKILLS_PARTY_SELECT"


## Opens the skills menu after a party member is chosen.
func skills_menu_open() -> void:
	use_sorted_display = false
	GameMenu.selected_skill_button = null
	GameMenu.selected_skill = null

	propagate_skills()
	reset_skill_details()

	GameMenu.last_selected_skills_option_button = use_button
	update_option_buttons_state(use_button)

	await skills_menu_show()

	if get_skill_buttons().is_empty():
		GameMenu.menu_state = "SKILLS_OPTION_SELECT"
		use_button.grab_button_focus()
		return

	GameMenu.menu_state = "SKILLS_SELECT_SKILL"
	focus_remembered_skill_or_first()


## Closes the skills menu and returns to party selection.
func skills_menu_close() -> void:
	GameMenu.selected_skill_button = null
	GameMenu.selected_skill = null

	clear_skill_selection_visuals()
	update_option_buttons_state(null)
	reset_skill_details()

	await skills_menu_hide()
	GameMenu.menu_state = "SKILLS_PARTY_SELECT"


## Forces the menu closed for loading.
func force_close_for_load() -> void:
	panel_container.position = HIDDEN_POSITION
	panel_container.visible = false

	use_sorted_display = false

	clear_skill_buttons()
	clear_skill_selection_visuals()
	update_option_buttons_state(null)
	reset_skill_details()
	stats_portrait.texture = null

	GameMenu.selected_skill_button = null
	GameMenu.selected_skill = null
	GameMenu.last_selected_skills_option_button = null

## Visual tween function for showing the menu.
func skills_menu_show() -> void:
	GameMenu.menu_is_animating = true
	await GameMenu.top_level.top_level_bottom_only()
	panel_container.position = HIDDEN_POSITION
	panel_container.visible = true
	var tween = create_tween()
	tween.tween_property(panel_container, "position", VISIBLE_POSITION, 0.15)
	await tween.finished
	GameMenu.menu_is_animating = false


## Visual tween function for hiding the menu.
func skills_menu_hide() -> void:
	GameMenu.menu_is_animating = true
	panel_container.position = VISIBLE_POSITION
	var tween = create_tween()
	tween.tween_property(panel_container, "position", HIDDEN_POSITION, 0.15)
	await tween.finished
	await GameMenu.top_level.top_level_bottom_only_return()
	panel_container.visible = false
	GameMenu.menu_is_animating = false


## Instantiates buttons for the current selected party member.
func propagate_skills() -> void:
	clear_skill_buttons()
	clear_skill_selection_visuals()
	update_party_portrait()
	reset_skill_details()

	var member: PartyMemberData = GameMenu.current_selected_party_member
	if member == null:
		return

	var display_skills: Array[Skill] = _get_displayed_skills(member)
	for skill in display_skills:
		make_skills_button(skill)

	setup_skill_focus_neighbors()


## Instantiates a SkillsSkillButton into the grid.
func make_skills_button(skill: Skill) -> void:
	if skill == null:
		return

	var new_skill_button: SkillsSkillButton = GameMenu.SKILLS_SKILL_BUTTON.instantiate() as SkillsSkillButton
	grid_container.add_child(new_skill_button)

	new_skill_button.skill = skill
	new_skill_button.skill_button.text = skill.name
	new_skill_button.skill_cost.text = str(skill.sp_cost)
	new_skill_button.set_selected(false)
	refresh_skill_button_state(new_skill_button)

	new_skill_button.skill_button.pressed.connect(
		func() -> void:
			_on_skill_button_pressed(new_skill_button)
	)

	new_skill_button.skill_button.focus_entered.connect(
		func() -> void:
			update_skill_details(skill)
			new_skill_button.refresh_visual_state()
	)

	new_skill_button.skill_button.focus_exited.connect(
		func() -> void:
			new_skill_button.refresh_visual_state()
	)

## Enters skill selection and focuses remembered or first skill.
func on_use_button_pressed() -> void:
	GameMenu.last_selected_skills_option_button = use_button
	update_option_buttons_state(use_button)

	if get_skill_buttons().is_empty():
		GameMenu.play_error_sound()
		return

	GameMenu.menu_state = "SKILLS_SELECT_SKILL"
	focus_remembered_skill_or_first()


## Sorts the displayed list for the current view.
func on_sort_button_pressed() -> void:
	if get_skill_buttons().is_empty():
		GameMenu.play_error_sound()
		return

	use_sorted_display = not use_sorted_display
	propagate_skills()

	GameMenu.last_selected_skills_option_button = use_button
	update_option_buttons_state(use_button)
	GameMenu.menu_state = "SKILLS_SELECT_SKILL"
	focus_remembered_skill_or_first()

## Enters reorder state and focuses the first skill.
func on_reorder_button_pressed() -> void:
	if get_skill_buttons().size() < 2:
		GameMenu.play_error_sound()
		return

	GameMenu.last_selected_skills_option_button = reorder_button
	update_option_buttons_state(reorder_button)

	if use_sorted_display == true:
		use_sorted_display = false
		propagate_skills()

	GameMenu.selected_skill_button = null
	GameMenu.selected_skill = null
	clear_skill_selection_visuals()
	reset_skill_details()

	GameMenu.menu_state = "SKILLS_REORDER"
	focus_first_skill_button()


## Closes the skills menu back to party select.
func on_exit_button_pressed() -> void:
	GameMenu.last_selected_skills_option_button = exit_button
	update_option_buttons_state(exit_button)

	await skills_menu_close()
	GameMenu.top_level.focus_last_top_level_stats()


func cancel_skill_selection() -> void:
	GameMenu.selected_skill_button = null
	GameMenu.selected_skill = null

	clear_skill_selection_visuals()
	reset_skill_details()
	update_option_buttons_state(GameMenu.last_selected_skills_option_button)

	GameMenu.menu_state = "SKILLS_OPTION_SELECT"
	focus_last_skills_option_button()


func cancel_skill_target_selection() -> void:
	return_focus_to_selected_skill()


func return_focus_to_selected_skill() -> void:
	GameMenu.menu_state = "SKILLS_SELECT_SKILL"

	if GameMenu.selected_skill_button != null:
		if is_instance_valid(GameMenu.selected_skill_button):
			GameMenu.selected_skill_button.grab_button_focus()
			return

	focus_remembered_skill_or_first()


func refresh_selected_skill_after_field_use() -> void:
	refresh_skill_button_states()

	if GameMenu.selected_skill_button == null:
		return
	if not is_instance_valid(GameMenu.selected_skill_button):
		return

	var skill_button: SkillsSkillButton = GameMenu.selected_skill_button
	if skill_button.skill == null:
		return

	skill_button.skill_button.text = skill_button.skill.name
	skill_button.skill_cost.text = str(skill_button.skill.sp_cost)
	skill_button.set_selected(skill_button.is_selected)
	update_skill_details(skill_button.skill)

func refresh_skill_button_states() -> void:
	for skill_button in get_skill_buttons():
		refresh_skill_button_state(skill_button)


func refresh_skill_button_state(skill_button: SkillsSkillButton) -> void:
	if skill_button == null:
		return
	if skill_button.skill == null:
		return

	var usability: Dictionary = get_field_skill_usability(skill_button.skill, GameMenu.current_selected_party_member)
	var can_proceed: bool = bool(usability.get("can_proceed", false))
	skill_button.skill_cost.text = str(skill_button.skill.sp_cost)
	skill_button.set_blocked(not can_proceed)


func cancel_reorder_selection() -> void:
	GameMenu.selected_skill_button = null
	GameMenu.selected_skill = null

	clear_skill_selection_visuals()
	reset_skill_details()
	update_option_buttons_state(reorder_button)

	GameMenu.menu_state = "SKILLS_OPTION_SELECT"
	reorder_button.grab_button_focus()


func update_description_label(skill: Skill = null) -> void:
	if skill == null:
		description_label.text = ""
		return

	description_label.text = skill.description


func update_cost_value_label(skill: Skill = null) -> void:
	if skill == null:
		cost_value_label.text = ""
		cost_title_label.visible = false
		return

	cost_title_label.visible = true
	cost_value_label.text = str(skill.sp_cost)


func reset_skill_details() -> void:
	description_label.text = ""
	cost_value_label.text = ""
	cost_title_label.visible = false


func update_party_portrait() -> void:
	var member: PartyMemberData = GameMenu.current_selected_party_member
	if member == null:
		stats_portrait.texture = null
		return

	stats_portrait.texture = member.stats_sprite


func update_option_buttons_state(active_button: SkillsOptionsButton = null) -> void:
	for child in options_button_h_box.get_children():
		if child is SkillsOptionsButton:
			var option_button := child as SkillsOptionsButton
			option_button.is_active = option_button == active_button
			option_button.set_color()


func focus_last_skills_option_button() -> void:
	var button_to_focus: SkillsOptionsButton = use_button

	if Options.menu_memory == true:
		if GameMenu.last_selected_skills_option_button != null:
			if is_instance_valid(GameMenu.last_selected_skills_option_button):
				button_to_focus = GameMenu.last_selected_skills_option_button

	button_to_focus.grab_button_focus()


func focus_first_skill_button() -> void:
	var skill_buttons: Array[SkillsSkillButton] = get_skill_buttons()
	if skill_buttons.is_empty():
		use_button.grab_button_focus()
		return

	skill_buttons[0].grab_button_focus()


func focus_remembered_skill_or_first() -> void:
	if Options.menu_memory == false:
		focus_first_skill_button()
		return

	var member: PartyMemberData = GameMenu.current_selected_party_member
	if member == null:
		focus_first_skill_button()
		return

	var actor_key: String = _get_actor_memory_key(member)
	if not GameMenu.last_selected_skill_id_by_actor_id.has(actor_key):
		focus_first_skill_button()
		return

	var remembered_skill_key: String = String(GameMenu.last_selected_skill_id_by_actor_id[actor_key])
	var remembered_button: SkillsSkillButton = find_button_by_skill_key(remembered_skill_key)
	if remembered_button == null:
		focus_first_skill_button()
		return

	remembered_button.grab_button_focus()


func _on_skill_button_pressed(skill_button: SkillsSkillButton) -> void:
	if skill_button == null:
		return
	if skill_button.skill == null:
		GameMenu.play_error_sound()
		return

	match GameMenu.menu_state:
		"SKILLS_SELECT_SKILL":
			set_active_skill_button(skill_button)

			var usability: Dictionary = get_field_skill_usability(
				skill_button.skill,
				GameMenu.current_selected_party_member
			)
			var can_proceed: bool = bool(usability.get("can_proceed", false))

			if not can_proceed:
				GameMenu.play_error_sound()
				return

			var first_valid_target_stats_variant = usability.get("first_valid_target_stats", null)
			if not (first_valid_target_stats_variant is TopLevelStats):
				GameMenu.play_error_sound()
				return

			var first_valid_target_stats: TopLevelStats = first_valid_target_stats_variant as TopLevelStats
			GameMenu.menu_state = "SKILLS_USE_PARTY_SELECT"
			first_valid_target_stats.grab_button_focus()
			AudioManager.play_ui_confirm()

		"SKILLS_REORDER":
			handle_reorder_skill_press(skill_button)


func set_active_skill_button(skill_button: SkillsSkillButton) -> void:
	if skill_button == null:
		return
	if skill_button.skill == null:
		return

	for child in get_skill_buttons():
		child.set_selected(child == skill_button)

	GameMenu.selected_skill_button = skill_button
	GameMenu.selected_skill = skill_button.skill

	update_skill_details(skill_button.skill)
	remember_selected_skill(skill_button.skill)

func handle_reorder_skill_press(skill_button: SkillsSkillButton) -> void:
	if skill_button == null:
		return
	if skill_button.skill == null:
		GameMenu.play_error_sound()
		return

	if GameMenu.selected_skill_button == null:
		set_active_skill_button(skill_button)
		AudioManager.play_ui_confirm()
		return
	if not is_instance_valid(GameMenu.selected_skill_button):
		GameMenu.selected_skill_button = null
		GameMenu.selected_skill = null
		set_active_skill_button(skill_button)
		AudioManager.play_ui_confirm()
		return

	if skill_button == GameMenu.selected_skill_button:
		clear_skill_selection_visuals()
		GameMenu.selected_skill_button = null
		GameMenu.selected_skill = null
		skill_button.grab_button_focus()
		return

	var skill_buttons: Array[SkillsSkillButton] = get_skill_buttons()
	var from_index: int = skill_buttons.find(GameMenu.selected_skill_button)
	var to_index: int = skill_buttons.find(skill_button)
	if from_index == -1 or to_index == -1:
		cancel_reorder_selection()
		return

	swap_current_member_skills(from_index, to_index)
	clear_skill_selection_visuals()
	GameMenu.selected_skill_button = null
	GameMenu.selected_skill = null
	propagate_skills()
	update_option_buttons_state(reorder_button)
	GameMenu.menu_state = "SKILLS_REORDER"

	var refreshed_buttons: Array[SkillsSkillButton] = get_skill_buttons()
	if to_index >= 0 and to_index < refreshed_buttons.size():
		refreshed_buttons[to_index].grab_button_focus()
	AudioManager.play_ui_confirm()


func swap_current_member_skills(from_index: int, to_index: int) -> void:
	var member: PartyMemberData = GameMenu.current_selected_party_member
	if member == null:
		return
	if from_index < 0 or from_index >= member.skills.size():
		return
	if to_index < 0 or to_index >= member.skills.size():
		return

	var temp: Skill = member.skills[from_index]
	member.skills[from_index] = member.skills[to_index]
	member.skills[to_index] = temp


func clear_skill_selection_visuals() -> void:
	for child in get_skill_buttons():
		child.set_selected(false)


func remember_selected_skill(skill: Skill) -> void:
	var member: PartyMemberData = GameMenu.current_selected_party_member
	if member == null:
		return
	if skill == null:
		return

	var actor_key: String = _get_actor_memory_key(member)
	var skill_key: String = _get_skill_memory_key(skill)
	if actor_key.is_empty():
		return
	if skill_key.is_empty():
		return

	GameMenu.last_selected_skill_id_by_actor_id[actor_key] = skill_key


func find_button_by_skill_key(skill_key: String) -> SkillsSkillButton:
	if skill_key.is_empty():
		return null

	for child in get_skill_buttons():
		if _get_skill_memory_key(child.skill) == skill_key:
			return child

	return null


func get_skill_buttons() -> Array[SkillsSkillButton]:
	var skill_buttons: Array[SkillsSkillButton] = []

	for child in grid_container.get_children():
		if child is SkillsSkillButton:
			skill_buttons.append(child as SkillsSkillButton)

	return skill_buttons


func clear_skill_buttons() -> void:
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
		
		
func setup_skill_focus_neighbors() -> void:
	GameMenu.setup_horizontal_focus_neighbors(options_button_h_box)

	for child in options_button_h_box.get_children():
		if child is SkillsOptionsButton:
			var option_button: SkillsOptionsButton = child as SkillsOptionsButton
			var self_path: NodePath = option_button.button.get_path()
			option_button.button.focus_neighbor_top = self_path
			option_button.button.focus_neighbor_bottom = self_path

	setup_skill_grid_focus_neighbors()
func setup_skill_grid_focus_neighbors() -> void:
	var skill_buttons: Array[SkillsSkillButton] = get_skill_buttons()
	var count: int = skill_buttons.size()
	if count == 0:
		return

	var cols: int = grid_container.columns
	if cols <= 0:
		cols = 1

	var btns: Array[Button] = []
	btns.resize(count)

	for i in range(count):
		btns[i] = skill_buttons[i].skill_button

	var focusable_count: int = 0
	var only_btn: Button = null
	for btn in btns:
		if _is_focusable_button(btn):
			focusable_count += 1
			only_btn = btn

	if focusable_count == 0:
		return

	if focusable_count == 1:
		var only_path: NodePath = only_btn.get_path()
		only_btn.focus_neighbor_top = only_path
		only_btn.focus_neighbor_bottom = only_path
		only_btn.focus_neighbor_left = only_path
		only_btn.focus_neighbor_right = only_path
		only_btn.focus_previous = only_path
		only_btn.focus_next = only_path
		return

	@warning_ignore("integer_division")
	var rows: int = int((count + cols - 1) / cols)

	for i in range(count):
		var btn: Button = btns[i]
		if not _is_focusable_button(btn):
			continue

		@warning_ignore("integer_division")
		var row: int = i / cols
		var col: int = i % cols

		var row_start: int = row * cols
		var row_len: int = min(cols, count - row_start)

		var left_i: int = _find_in_row(btns, row_start, row_len, i, -1)
		var right_i: int = _find_in_row(btns, row_start, row_len, i, 1)
		var up_i: int = _find_in_col(btns, cols, rows, row, col, -1)
		var down_i: int = _find_in_col(btns, cols, rows, row, col, 1)

		btn.focus_neighbor_left = btns[left_i].get_path()
		btn.focus_neighbor_right = btns[right_i].get_path()
		btn.focus_neighbor_top = btns[up_i].get_path()
		btn.focus_neighbor_bottom = btns[down_i].get_path()

		btn.focus_previous = btn.focus_neighbor_left
		btn.focus_next = btn.focus_neighbor_right

func _is_focusable_button(btn: Button) -> bool:
	if btn == null:
		return false
	if btn.disabled:
		return false
	if not btn.is_visible_in_tree():
		return false
	if btn.focus_mode == Control.FOCUS_NONE:
		return false
	return true


func _find_in_row(btns: Array[Button], row_start: int, row_len: int, from_i: int, delta: int) -> int:
	if row_len <= 1:
		return from_i

	var col: int = from_i - row_start
	for _step in range(row_len):
		col += delta

		if col < 0:
			col = row_len - 1
		elif col >= row_len:
			col = 0

		var idx: int = row_start + col
		if _is_focusable_button(btns[idx]):
			return idx

	return from_i


func _find_in_col(btns: Array[Button], cols: int, rows: int, from_row: int, from_col: int, row_delta: int) -> int:
	var count: int = btns.size()

	for _step in range(rows):
		var row: int = from_row + (row_delta * (_step + 1))

		while row < 0:
			row += rows
		while row >= rows:
			row -= rows

		var row_start: int = row * cols
		if row_start >= count:
			continue

		var row_len: int = min(cols, count - row_start)
		var target_col: int = from_col
		if target_col >= row_len:
			target_col = row_len - 1

		var center_i: int = row_start + target_col
		if _is_focusable_button(btns[center_i]):
			return center_i

		for offset in range(1, row_len):
			var left_col: int = target_col - offset
			if left_col >= 0:
				var left_i: int = row_start + left_col
				if _is_focusable_button(btns[left_i]):
					return left_i

			var right_col: int = target_col + offset
			if right_col < row_len:
				var right_i: int = row_start + right_col
				if _is_focusable_button(btns[right_i]):
					return right_i

	var from_i: int = (from_row * cols) + from_col
	if from_i >= 0:
		if from_i < count:
			if _is_focusable_button(btns[from_i]):
				return from_i

	for i in range(count):
		if _is_focusable_button(btns[i]):
			return i

	return 0


func _get_displayed_skills(member: PartyMemberData) -> Array[Skill]:
	var display_skills: Array[Skill] = []

	if member == null:
		return display_skills

	for skill in member.skills:
		if skill != null:
			display_skills.append(skill)

	if use_sorted_display == true:
		display_skills.sort_custom(Callable(self, "_sort_skills_for_menu"))

	return display_skills


func _sort_skills_for_menu(a: Skill, b: Skill) -> bool:
	var a_rank: int = _skill_sort_rank(a)
	var b_rank: int = _skill_sort_rank(b)

	if a_rank != b_rank:
		return a_rank < b_rank

	var a_scope_rank: int = _skill_scope_rank(a)
	var b_scope_rank: int = _skill_scope_rank(b)
	if a_scope_rank != b_scope_rank:
		return a_scope_rank < b_scope_rank

	if a.sp_cost != b.sp_cost:
		return a.sp_cost < b.sp_cost

	return a.name.nocasecmp_to(b.name) < 0



func _skill_sort_rank(skill: Skill) -> int:
	var category: String = _classify_skill_for_sort(skill)
	var idx: int = Options.skills_sort_order.find(category)
	if idx == -1:
		return Options.skills_sort_order.size()
	return idx


func _classify_skill_for_sort(skill: Skill) -> String:
	if skill == null:
		return "UNSORTED"

	var usability: Dictionary = get_field_skill_usability(skill, GameMenu.current_selected_party_member)
	if bool(usability.get("can_proceed", false)):
		return "FIELD_USABLE"
	if bool(usability.get("is_allowed_in_field", false)) and bool(usability.get("is_beneficial", false)):
		return "FIELD_BENEFICIAL"
	if skill.scope == Skill.UseScope.BATTLE_ONLY:
		return "BATTLE_ONLY"
	return "FIELD_OTHER"




func _skill_scope_rank(skill: Skill) -> int:
	if skill == null:
		return 99

	match skill.scope:
		Skill.UseScope.FIELD_ONLY:
			return 0
		Skill.UseScope.ALL:
			return 1
		Skill.UseScope.BATTLE_ONLY:
			return 2

	return 99

func _category_from_effect(effect: Effect) -> String:
	if effect == null:
		return "UNSORTED"

	var script_res = effect.get_script()
	if script_res == null:
		return "UNSORTED"

	var script_path: String = String(script_res.resource_path)
	var script_file: String = script_path.get_file()

	match script_file:
		"effect_heal_hp.gd", "effect_heal_sp.gd":
			return "HPHEAL"
		"effect_healpoison.gd", "effect_healpoisonfull.gd":
			return "STATUSHEAL"
		"effect_damage_hp.gd":
			return "DAMAGE"
		"effect_applyattackup.gd", "effect_applydefenseup.gd", "effect_applymagicup.gd", "effect_applyhaste.gd":
			return "BUFF"
		"effect_applyattackdown.gd", "effect_applydefensedown.gd", "effect_applymagicdown.gd", "effect_applyslow.gd", "effect_applypoison.gd", "effect_applysleep.gd", "effect_applystun.gd", "effect_applyconfuse.gd":
			return "DEBUFF"

	return "UNSORTED"


func _get_actor_memory_key(member: PartyMemberData) -> String:
	if member == null:
		return ""

	var actor_key: String = String(member.actor_id)
	if actor_key.is_empty():
		actor_key = member.get_display_name()

	return actor_key


func _get_skill_memory_key(skill: Skill) -> String:
	if skill == null:
		return ""

	var skill_key: String = String(skill.skill_id)
	if skill_key.is_empty():
		skill_key = skill.resource_path
	if skill_key.is_empty():
		skill_key = skill.name

	return skill_key


func update_skill_details(skill: Skill = null) -> void:
	update_party_portrait()
	update_description_label(skill)
	update_cost_value_label(skill)


func get_field_skill_usability(skill: Skill, actor: PartyMemberData) -> Dictionary:
	var result: Dictionary = {
		"is_allowed_in_field": false,
		"is_beneficial": false,
		"can_pay_cost": false,
		"has_valid_target": false,
		"can_proceed": false,
		"first_valid_target_stats": null,
	}

	if skill == null:
		return result
	if actor == null:
		return result

	var is_allowed_in_field: bool = skill.scope != Skill.UseScope.BATTLE_ONLY
	result["is_allowed_in_field"] = is_allowed_in_field

	var is_beneficial: bool = skill.intent == Skill.Intent.BENEFICIAL
	result["is_beneficial"] = is_beneficial

	var can_pay_cost: bool = skill.can_pay_cost(actor)
	result["can_pay_cost"] = can_pay_cost

	if is_allowed_in_field and is_beneficial:
		var field_ctx: EffectContext = EffectContext.new()
		field_ctx.mode = EffectContext.Mode.FIELD
		field_ctx.user_actor = actor

		var field_effects: Array[Effect] = skill.get_effects_for_context(field_ctx)
		if not field_effects.is_empty():
			for child in GameMenu.top_level.party_h_box_container.get_children():
				if not (child is TopLevelStats):
					continue

				var stats_box: TopLevelStats = child as TopLevelStats
				if stats_box.party_member == null:
					continue

				if _field_skill_effects_can_target_member(field_effects, stats_box.party_member):
					result["has_valid_target"] = true
					result["first_valid_target_stats"] = stats_box
					break

	var has_valid_target: bool = bool(result.get("has_valid_target", false))
	result["can_proceed"] = is_allowed_in_field and is_beneficial and can_pay_cost and has_valid_target
	return result


func _field_skill_effects_can_target_member(field_effects: Array[Effect], member: PartyMemberData) -> bool:
	if member == null:
		return false

	for effect in field_effects:
		if effect == null:
			continue
		if effect.can_use_on_member(member):
			return true

	return false
