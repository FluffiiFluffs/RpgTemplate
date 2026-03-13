@tool
class_name TalkArea
extends InteractArea


##Where dialogue starts from
@export var start_position : String = "start"

func _ready()->void:
	super()
	indicator = INDICATOR.DOTDOTDOT

func _start_dialog() -> void:
	if dialogue == null:
		return

	super()
	DM.show_dialogue(dialogue, start_position)

func _on_area_entered(_area: Area2D) -> void:
	super(_area)
	
	pass
func _on_area_exited(_area: Area2D) -> void:
	super(_area)
	pass
