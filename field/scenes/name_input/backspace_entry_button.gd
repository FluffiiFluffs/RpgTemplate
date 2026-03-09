@tool
class_name BackspaceEntryButton
extends LetterEntryButton

func _ready()->void:
	text = letter
	pressed.connect(on_button_pressed)
	if Engine.is_editor_hint():
		return
	if blank:
		modulate = Color(0.0, 0.0, 0.0, 0.0)

func on_button_pressed()->void:
	# Sends letter to main script to be input into the name display
	input_scene.backspace()
	pass
