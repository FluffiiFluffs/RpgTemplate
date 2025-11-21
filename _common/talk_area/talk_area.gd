class_name TalkArea
extends Area2D

##SpeakerResources to be used within the dialogue resource.
@export var speakers : Array[SpeakerResource] = []
##The dialogue resource to be used. Must be set.
@export var dialogue : Resource
##What DialogueManager title to start from within the dialogue resource
@export var talking_start_position : String = "start"
@export var can_talk : bool = false

func _ready()->void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	pass
	

func _on_area_entered(_area:Area2D)->void:
	can_talk = true
	pass
	
	
func _on_area_exited(_area:Area2D)->void:
	can_talk = false
	pass


func _unhandled_input(event):
	if event.is_action_pressed("confirm_input"):
		_start_dialog()

func _start_dialog():
	if dialogue != null:
		#put speakers resource into dialoguemanager array for use in dialog balloons
		DialogueManager._set_resources(speakers.duplicate())
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		DialogueManager.show_dialogue_balloon(dialogue, "start")
