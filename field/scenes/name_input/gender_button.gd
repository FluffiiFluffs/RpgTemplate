@tool
class_name GenderButton
extends PanelContainer


@export_range(0, 3, 1.0) var gender : int = 0


@onready var button: Button = %Button


var is_active : bool = false


func _ready()->void:
	button.focus_entered.connect(on_button_focused)
	button.focus_exited.connect(on_button_unfocused)

	if button.has_focus():
		on_button_focused()
	else:
		on_button_unfocused()


func _process(_delta: float) -> void:
	match gender:
		0:
			button.text = "⬤" # he
		1:
			button.text = "○" # she
		2:
			button.text = "◍" # them
		3:
			button.text = "◉" # it


func on_button_focused()->void:
	if is_active:
		self_modulate = Color(0.945, 0.424, 0.0, 1.0)
	else:
		self_modulate = Color(0.945, 0.704, 0.0, 1.0)


func on_button_unfocused()->void:
	if is_active:
		self_modulate = Color(0.945, 0.424, 0.0, 1.0)
	else:
		self_modulate = Color(1.0, 1.0, 1.0, 1.0)
