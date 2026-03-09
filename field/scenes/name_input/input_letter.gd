@tool
class_name InputLetter
extends PanelContainer

@onready var label: Label = %Label

@export var letter : String = ""

@export var is_current_letter : bool = false

func _process(_delta: float) -> void:
	if letter == "":
		label.text = "-"
	else:
		label.text = letter
	if is_current_letter:
		label.text = "∙"

func set_letter_to_blank()->void:
	letter = ""
