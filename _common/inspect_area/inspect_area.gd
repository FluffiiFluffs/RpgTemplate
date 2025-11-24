class_name InspectArea
extends InteractArea


##If there is an item present. Controlled by DialogueManager
@export var item_here : bool = false
##Where to start text in the dialogue if there is an item to be given
@export var item_here_start : String = ""
##Where to start text in the dialogue if there is no item to be given
@export var item_not_here_start : String = ""
##If the container is already open.
@export var open : bool = false


func _ready()->void:
	super()
	opened()
	pass
	


func opened()->void:
	if open == true:
		for child in get_parent().get_children():
			if child is AnimationPlayer:
				child.play("open")




func _start_dialog() -> void:
	if dialogue != null:
		super()
		if item_here: #Item is present
				DialogueManager._set_resources(speakers.duplicate())
				DialogueManager.show_dialogue_balloon(dialogue, item_here_start)
		else: #Item is gone
				DialogueManager._set_resources(speakers.duplicate())
				DialogueManager.show_dialogue_balloon(dialogue, item_not_here_start)
