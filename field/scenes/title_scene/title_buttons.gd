
class_name TitleButtons
extends Node2D

@onready var new_game_area_2d: Area2D = %NewGameArea2D
@onready var load_game_area_2d: Area2D = %LoadGameArea2D
@onready var options_area_2d: Area2D = %OptionsArea2D
@onready var exit_game_area_2d: Area2D = %ExitGameArea2D
@onready var choice_text: Label = %ChoiceText
@onready var title_sparkle: GPUParticles2D = %TitleSparkle

var selected_button : String = ""

func _ready()->void:
	new_game_area_2d.body_entered.connect(new_game_body_entered)
	new_game_area_2d.body_exited.connect(new_game_body_exited)
	load_game_area_2d.body_entered.connect(load_game_body_entered)
	load_game_area_2d.body_exited.connect(load_game_body_exited)
	options_area_2d.body_entered.connect(options_body_entered)
	options_area_2d.body_exited.connect(options_body_exited)
	exit_game_area_2d.body_entered.connect(exit_game_body_entered)
	exit_game_area_2d.body_exited.connect(exit_game_body_exited)
	choice_text.text = ""
	

func new_game_body_entered(body : FieldPartyMember)->void:
	if body is FieldPartyMember:
		title_sparkle.restart()
		title_sparkle.visible = true
		title_sparkle.global_position = new_game_area_2d.global_position
		selected_button = "new game"
		choice_text.text = "New Game"

	
func new_game_body_exited(body : FieldPartyMember)->void:
	if body is FieldPartyMember:
		title_sparkle.emitting = false
		title_sparkle.visible = false
		selected_button = ""
		choice_text.text = ""
		
	
func load_game_body_entered(body : FieldPartyMember)->void:
	if body is FieldPartyMember:
		title_sparkle.restart()
		title_sparkle.visible = true
		title_sparkle.global_position = load_game_area_2d.global_position
		selected_button = "load game"
		choice_text.text = "Load Game"
	
func load_game_body_exited(body : FieldPartyMember)->void:
	if body is FieldPartyMember:
		title_sparkle.emitting = false
		title_sparkle.visible = false
		selected_button = ""
		choice_text.text = ""
	
func options_body_entered(body : FieldPartyMember)->void:
	if body is FieldPartyMember:
		title_sparkle.restart()
		title_sparkle.visible = true
		title_sparkle.global_position = options_area_2d.global_position
		selected_button = "options"
		choice_text.text = "Options"
	
func options_body_exited(body : FieldPartyMember)->void:
	if body is FieldPartyMember:
		title_sparkle.emitting = false
		title_sparkle.visible = false
		selected_button = ""
		choice_text.text = ""
	
func exit_game_body_entered(body : FieldPartyMember)->void:
	if body is FieldPartyMember:
		title_sparkle.restart()
		title_sparkle.visible = true
		title_sparkle.global_position = exit_game_area_2d.global_position
		selected_button = "exit game"
		choice_text.text = "Exit Game"
	
func exit_game_body_exited(body : FieldPartyMember)->void:
	if body is FieldPartyMember:
		title_sparkle.emitting = false
		title_sparkle.visible = false
		selected_button = ""
		choice_text.text = ""
