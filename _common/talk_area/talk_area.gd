class_name TalkArea
extends InteractArea


##Where dialogue starts from
@export var start_position : String = "start"

func _ready()->void:
	super()

func _start_dialog() -> void:
	if dialogue != null:
		super()
		DialogueManager._set_resources(speakers.duplicate())
		DialogueManager.show_dialogue_balloon(dialogue, start_position)
