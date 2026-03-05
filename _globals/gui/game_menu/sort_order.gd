class_name SortOrderUI extends Control


@onready var sort_order_v_box: VBoxContainer = %SortOrderVBox
@onready var sort_order_entry: SortOrderButton = %SortOrderEntry


func _ready()->void:
	#region initialize visibility
	visible = false
	modulate = Color(0.0, 0.0, 0.0, 0.0)
	#endregion initialize visibility


#region SortOrderMenu

func open_sort_menu()->void:
	GameMenu.sort_order.set_deferred("visible", true)
	clear_sort_buttons()
	make_sort_buttons()
	setup_sort_order_focus_neighbors()
	focus_first_sort_button()
	await sort_order_show()
	#animation_player.play("opt_sort_order_show")
	GameMenu.menu_state = "OPTIONS_SORT_ORDER"
	pass
	
func close_sort_menu()->void:
	clear_sort_buttons() ##get the buttons out of memory
	#animation_player.play("opt_sort_order_hide")
	await sort_order_hide()
	GameMenu.sort_selected_index = -1
	GameMenu.options.opt_sort_order_button.grab_focus()
	GameMenu.menu_state = "OPTIONS_OPEN"
	#await animation_player.animation_finished
	
	GameMenu.sort_order.set_deferred("visible", false)
	pass

func sort_order_show()->void:
	GameMenu.menu_is_animating = true
	modulate = Color(0.0, 0.0, 0.0, 0.0)
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	await tween.finished
	GameMenu.menu_is_animating = false
	pass
	
func sort_order_hide()->void:
	GameMenu.menu_is_animating = true
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.15)
	await tween.finished
	visible = false
	GameMenu.menu_is_animating = false
	
	pass



func clear_sort_buttons()->void:
	for child in sort_order_v_box.get_children():
		if child is SortOrderButton:
			sort_order_v_box.remove_child(child)
			child.queue_free()


func make_sort_buttons()->void:
	var count := Options.item_sort_order.size()
	for i in range(count):
		var category : String = Options.item_sort_order[i]

		var new_sort_button : SortOrderButton = GameMenu.SORT_ORDER_ENTRY.instantiate()
		
		# add to the VBox first so @onready runs
		sort_order_v_box.add_child(new_sort_button)

		# now the onready vars are valid
		new_sort_button.set_label_text(i + 1)      # int is fine here
		new_sort_button.set_button_text(category)

func setup_sort_order_focus_neighbors()->void:
	var slist := sort_order_v_box.get_children()
	var count := slist.size()

	if count == 0:
		return

	if count == 1:
		var only_child : SortOrderButton = slist[0]
		var btn : Button = only_child.sort_button
		var path : NodePath = btn.get_path()
		btn.focus_neighbor_top = path
		btn.focus_neighbor_bottom = path
		btn.focus_neighbor_left = path
		btn.focus_neighbor_right = path
		return

	for i in range(count):
		var entry : SortOrderButton = slist[i]
		var btn : Button = entry.sort_button

		var top_index : int = (i - 1 + count) % count
		var bottom_index : int = (i + 1) % count

		var top_btn : Button = (slist[top_index] as SortOrderButton).sort_button
		var bottom_btn : Button = (slist[bottom_index] as SortOrderButton).sort_button

		btn.focus_neighbor_top = top_btn.get_path()
		btn.focus_neighbor_bottom = bottom_btn.get_path()

		var self_path : NodePath = btn.get_path()
		btn.focus_neighbor_left = self_path
		btn.focus_neighbor_right = self_path



func focus_first_sort_button()->void:
	var slist := sort_order_v_box.get_children()
	if slist.size() == 0:
		return
	var first : SortOrderButton = slist[0]
	first.grab_button_focus()

func sort_order_button_pressed(button: SortOrderButton)->void:
	var slist := sort_order_v_box.get_children()
	var idx : int = slist.find(button)
	if idx == -1:
		return

	if GameMenu.menu_state == "OPTIONS_SORT_ORDER":
		# first selection
		GameMenu.sort_selected_index = idx

		for child in slist:
			if child is SortOrderButton:
				(child as SortOrderButton).set_selected(child == button)

		GameMenu.menu_state = "OPTIONS_SORT_ORDER_SORTING"

	elif GameMenu.menu_state == "OPTIONS_SORT_ORDER_SORTING":
		# second selection (or cancel if same)
		if idx == GameMenu.sort_selected_index:
			cancel_sort_selection()
			return

		_swap_item_sort_order(GameMenu.sort_selected_index, idx)
		cancel_sort_selection()

		# rebuild the list so labels stay in the right order
		clear_sort_buttons()
		make_sort_buttons()
		setup_sort_order_focus_neighbors()

		var new_list := sort_order_v_box.get_children()
		if idx >= 0 and idx < new_list.size():
			var new_button : SortOrderButton = new_list[idx]
			new_button.grab_button_focus()

func _swap_item_sort_order(a : int, b : int)->void:
	var order : Array = Options.item_sort_order.duplicate()

	if a < 0 or a >= order.size():
		return
	if b < 0 or b >= order.size():
		return

	var tmp = order[a]
	order[a] = order[b]
	order[b] = tmp

	Options.item_sort_order = order

func cancel_sort_selection()->void:
	GameMenu.sort_selected_index = -1
	var slist := sort_order_v_box.get_children()
	for child in slist:
		if child is SortOrderButton:
			(child as SortOrderButton).set_selected(false)
	GameMenu.menu_state = "OPTIONS_SORT_ORDER"

func force_close_for_load() -> void:
	clear_sort_buttons()
	GameMenu.sort_selected_index = -1

	modulate = Color(1.0, 1.0, 1.0, 0.0)
	visible = false


#endregion sort order menu
