@tool
class_name LetterEntryButton
extends Button

@export var letter : String = ""

## used for making a blank space in the menu
@export var blank : bool = false

var input_scene : NameInput = null

func _ready()->void:
	pressed.connect(on_button_pressed)


func _process(_delta: float) -> void:
	text = letter
	if Engine.is_editor_hint():
		if blank:
			modulate = Color(0.0, 0.0, 0.0, 0.5)
		return
	if blank:
		modulate = Color(0.0, 0.0, 0.0, 0.0)
		
		
func on_button_pressed()->void:
	# Sends letter to main script to be input into the name display
	input_scene.apply_letter(letter)
	pass
