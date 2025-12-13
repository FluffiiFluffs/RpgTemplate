##title_menu.gd
extends CanvasLayer


@onready var new_game_button : TitleButton = %NewGameButton
@onready var load_game_button : TitleButton = %LoadGameButton
@onready var options_button : TitleButton = %OptionsButton
@onready var exit_button : TitleButton = %ExitButton

var last_button_focused : TitleButton = null

func _ready()->void:
	setup_title_menu_button_neighbors()
	setup_title_menu_button_pressees()
	last_button_focused = new_game_button
	new_game_button.grab_button_focus()


	
func setup_title_menu_button_neighbors()->void:
	new_game_button.button.focus_neighbor_top = new_game_button.button.get_path()
	new_game_button.button.focus_neighbor_bottom = options_button.button.get_path()
	new_game_button.button.focus_neighbor_right = load_game_button.button.get_path()
	new_game_button.button.focus_neighbor_left = new_game_button.button.get_path()
	new_game_button.button.focus_previous = new_game_button.button.get_path()
	new_game_button.button.focus_next = load_game_button.button.get_path()
	
	load_game_button.button.focus_neighbor_top = load_game_button.button.get_path()
	load_game_button.button.focus_neighbor_bottom = exit_button.button.get_path()
	load_game_button.button.focus_neighbor_left = new_game_button.button.get_path()
	load_game_button.button.focus_neighbor_right = load_game_button.button.get_path()
	load_game_button.button.focus_previous = new_game_button.button.get_path()
	load_game_button.button.focus_next = options_button.button.get_path()
	
	options_button.button.focus_neighbor_top = new_game_button.button.get_path()
	options_button.button.focus_neighbor_bottom = options_button.button.get_path()
	options_button.button.focus_neighbor_left = options_button.button.get_path()
	options_button.button.focus_neighbor_right = exit_button.button.get_path()
	options_button.button.focus_previous = load_game_button.button.get_path()
	options_button.button.focus_next = exit_button.button.get_path()
	
	exit_button.button.focus_neighbor_top = load_game_button.button.get_path()
	exit_button.button.focus_neighbor_bottom = exit_button.button.get_path()
	exit_button.button.focus_neighbor_left = options_button.button.get_path()
	exit_button.button.focus_neighbor_right = exit_button.button.get_path()
	exit_button.button.focus_previous = options_button.button.get_path()
	exit_button.button.focus_next = exit_button.button.get_path()
	pass
	
func setup_title_menu_button_pressees():
	new_game_button.button.pressed.connect(on_new_game_button_pressed)
	load_game_button.button.pressed.connect(on_load_game_button_pressed)
	options_button.button.pressed.connect(on_options_button_pressed)
	exit_button.button.pressed.connect(on_exit_button_pressed)
	pass


func on_new_game_button_pressed()->void:
	#start a new game
	var main = get_tree().get_first_node_in_group("main")
	if main == null:
		return
	main.start_new_game()
	pass
	
func on_load_game_button_pressed()->void:
	#open load game menu
	pass

func on_options_button_pressed()->void:
	#open options menu
	pass
func on_exit_button_pressed()->void:
	#show exit game confirmation
	pass
