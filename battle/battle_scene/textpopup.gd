class_name TextPopup
extends Control

@onready var rich_text_label : RichTextLabel = %RichTextLabel
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var shown_text : String = ""

##Converts any int, float or string to a String so rich_text_label can use it in show_text()
func set_text(_text : Variant)->void:
	shown_text = str(_text)

##Plays animation and then calls queue_free()
func show_text()->void:
	rich_text_label.text = shown_text
	animation_player.play("popup")
	await animation_player.animation_finished
	queue_free()
