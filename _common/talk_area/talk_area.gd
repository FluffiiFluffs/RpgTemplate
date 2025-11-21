class_name TalkArea
extends Area2D

@export var speakers : Array[SpeakerResource] = []
@export var dialog : Resource
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
	#put speakers resource into dialoguemanager array for use in dialog balloons
	DialogueManager._set_resources(speakers.duplicate())
	DialogueManager.show_dialogue_balloon(dialog, "start")
