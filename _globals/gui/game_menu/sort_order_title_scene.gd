class_name SortOrderTitleScene
extends Control


const SORT_TARGET_ITEM: String = "ITEM"
const SORT_TARGET_SKILL: String = "SKILL"
const SORT_ORDER_ENTRY = preload("uid://dwhea87oe4shd")

@onready var sort_order_v_box: VBoxContainer = %SortOrderVBox
@onready var sort_order_entry: SortOrderButton = %SortOrderEntry

var current_sort_target: String = SORT_TARGET_ITEM
var return_focus_button: Button = null


func _ready()->void:
	#region initialize visibility
	visible = false
	modulate = Color(0.0, 0.0, 0.0, 0.0)
	#endregion initialize visibility


#region SortOrderMenu

func open_item_sort_menu()->void:
	_open_sort_menu_for_target(SORT_TARGET_ITEM, get_parent().opt_item_sort_order_button)


func open_skill_sort_menu()->void:
	_open_sort_menu_for_target(SORT_TARGET_SKILL, get_parent().opt_skill_sort_order_button)


func _open_sort_menu_for_target(target: String, focus_button: Button)->void:
	current_sort_target = target
	return_focus_button = focus_button
	set_deferred("visible", true)
	clear_sort_buttons()
	make_sort_buttons()
	setup_sort_order_focus_neighbors()
	focus_first_sort_button()
	await sort_order_show()
	get_parent().title_scene.menu_state = "OPTIONS_SORT_ORDER"


func close_sort_menu()->void:
	clear_sort_buttons()
	await sort_order_hide()
	get_parent().title_scene.sort_selected_index = -1
	if return_focus_button != null:
		return_focus_button.grab_focus()
	get_parent().title_scene.menu_state = "OPTIONS_MENU_OPEN"
	set_deferred("visible", false)


func sort_order_show()->void:
	get_parent().title_scene.menu_is_animating = true
	modulate = Color(0.0, 0.0, 0.0, 0.0)
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	await tween.finished
	get_parent().title_scene.menu_is_animating = false


func sort_order_hide()->void:
	get_parent().title_scene.menu_is_animating = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.15)
	await tween.finished
	visible = false
	get_parent().title_scene.menu_is_animating = false


func clear_sort_buttons()->void:
	for child in sort_order_v_box.get_children():
		if child is SortOrderButton:
			sort_order_v_box.remove_child(child)
			child.queue_free()


func make_sort_buttons()->void:
	var current_order: Array = _get_current_sort_order()
	var count: int = current_order.size()

	for i in range(count):
		var category: String = String(current_order[i])

		var new_sort_button: SortOrderButton = SORT_ORDER_ENTRY.instantiate()
		sort_order_v_box.add_child(new_sort_button)
		new_sort_button.set_label_text(i + 1)
		new_sort_button.set_button_text(_get_sort_category_display_name(category))


func setup_sort_order_focus_neighbors()->void:
	var slist = sort_order_v_box.get_children()
	var count = slist.size()

	if count == 0:
		return

	if count == 1:
		var only_child: SortOrderButton = slist[0]
		var btn: Button = only_child.sort_button
		var path: NodePath = btn.get_path()
		btn.focus_neighbor_top = path
		btn.focus_neighbor_bottom = path
		btn.focus_neighbor_left = path
		btn.focus_neighbor_right = path
		return

	for i in range(count):
		var entry: SortOrderButton = slist[i]
		var btn: Button = entry.sort_button

		var top_index: int = (i - 1 + count) % count
		var bottom_index: int = (i + 1) % count

		var top_btn: Button = (slist[top_index] as SortOrderButton).sort_button
		var bottom_btn: Button = (slist[bottom_index] as SortOrderButton).sort_button

		btn.focus_neighbor_top = top_btn.get_path()
		btn.focus_neighbor_bottom = bottom_btn.get_path()

		var self_path: NodePath = btn.get_path()
		btn.focus_neighbor_left = self_path
		btn.focus_neighbor_right = self_path


func focus_first_sort_button()->void:
	var slist = sort_order_v_box.get_children()
	if slist.size() == 0:
		return
	var first: SortOrderButton = slist[0]
	first.grab_button_focus()


func sort_order_button_pressed(button: SortOrderButton)->void:
	var slist = sort_order_v_box.get_children()
	var idx: int = slist.find(button)
	if idx == -1:
		return

	if get_parent().title_scene.menu_state == "OPTIONS_SORT_ORDER":
		get_parent().title_scene.sort_selected_index = idx

		for child in slist:
			if child is SortOrderButton:
				(child as SortOrderButton).set_selected(child == button)

		get_parent().title_scene.menu_state = "OPTIONS_SORT_ORDER_SORTING"

	elif get_parent().title_scene.menu_state == "OPTIONS_SORT_ORDER_SORTING":
		if idx == get_parent().title_scene.sort_selected_index:
			cancel_sort_selection()
			return

		_swap_current_sort_order(get_parent().title_scene.sort_selected_index, idx)
		cancel_sort_selection()

		clear_sort_buttons()
		make_sort_buttons()
		setup_sort_order_focus_neighbors()

		var new_list = sort_order_v_box.get_children()
		if idx >= 0 and idx < new_list.size():
			var new_button: SortOrderButton = new_list[idx]
			new_button.grab_button_focus()


func _swap_current_sort_order(a: int, b: int)->void:
	var order: Array = _get_current_sort_order().duplicate()

	if a < 0 or a >= order.size():
		return
	if b < 0 or b >= order.size():
		return

	var tmp = order[a]
	order[a] = order[b]
	order[b] = tmp

	_set_current_sort_order(order)


func _get_current_sort_order() -> Array:
	if current_sort_target == SORT_TARGET_SKILL:
		return Options.skills_sort_order
	return Options.item_sort_order


func _set_current_sort_order(order: Array) -> void:
	if current_sort_target == SORT_TARGET_SKILL:
		Options.skills_sort_order = order
		return
	Options.item_sort_order = order


func cancel_sort_selection()->void:
	get_parent().title_scene.sort_selected_index = -1
	var slist = sort_order_v_box.get_children()
	for child in slist:
		if child is SortOrderButton:
			(child as SortOrderButton).set_selected(false)
	get_parent().title_scene.menu_state = "OPTIONS_SORT_ORDER"


func _get_sort_category_display_name(category: String) -> String:
	if current_sort_target == SORT_TARGET_SKILL:
		match category:
			"RECOVERY":
				return "Recovery"
			"ATTACK":
				return "Attack"
			"EFFECT":
				return "Effect"

	return category

#endregion sort order menu
