class_name TalkArea
extends InteractArea


##Where dialogue starts from
@export var start_position : String = "start"

func _ready()->void:
	super()

func _start_dialog() -> void:
	if dialogue == null:
		return

	super()
	DM.show_dialogue(dialogue, start_position)
