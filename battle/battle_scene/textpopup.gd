class_name TextPopup
extends Control


@onready var number_label: RichTextLabel = %NumberLabel
@onready var title_label: RichTextLabel = %TitleLabel

@onready var animation_player : AnimationPlayer = %AnimationPlayer

var shown_text : String = ""

func set_number(_text : Variant) -> void:
	shown_text = str(_text)

func set_title(_text : String) -> void:
	title_label.text = _text

func set_color(_color : Color)->void:
	number_label.self_modulate = _color
	title_label.self_modulate = _color

func title_visible()->void:
	if title_label.text == "":
		title_label.visible = false
	else:
		title_label.visible = true

func show_text() -> void:
	number_label.text = shown_text
	animation_player.play("popup")
	await animation_player.animation_finished
	queue_free()

func snap_center_to_canvas_point(canvas_point : Vector2) -> void:
	global_position = (canvas_point - pivot_offset).round()
