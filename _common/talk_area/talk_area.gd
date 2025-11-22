#class_name TalkArea
#extends Area2D
#
###SpeakerResources to be used within the dialogue resource.
#@export var speakers : Array[SpeakerResource] = []
###The dialogue resource to be used. Must be set.
#@export var dialogue : Resource
###What DialogueManager title to start from within the dialogue resource
#@export var talking_start_position : String = "start"
#@export var can_talk : bool = false
#
#func _ready()->void:
	#area_entered.connect(_on_area_entered)
	#area_exited.connect(_on_area_exited)
	#pass
	#
#
#func _on_area_entered(_area:Area2D)->void:
	#can_talk = true
	#pass
	#
	#
#func _on_area_exited(_area:Area2D)->void:
	#can_talk = false
	#pass
#
#
#func _unhandled_input(event):
	#if event.is_action_pressed("confirm_input"):
		#_start_dialog()
#
#func _start_dialog():
	#if dialogue != null:
		#print("Dialogue titles: ", dialogue.titles.keys())
		##put speakers resource into dialoguemanager array for use in dialog balloons
		#DialogueManager._set_resources(speakers.duplicate())
		#await get_tree().process_frame
		#await get_tree().process_frame
		#await get_tree().process_frame
		#await get_tree().process_frame
		#await get_tree().process_frame
		#DialogueManager.show_dialogue_balloon(dialogue, talking_start_position)

class_name TalkArea
extends Area2D

@export var speakers : Array[SpeakerResource] = []
@export var dialogue : Resource
@export var talking_start_position : String = "start"
@export var can_talk : bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	set_process_unhandled_input(false)


func _on_area_entered(area: Area2D) -> void:
	# Change this check to match your player or player talk area
		can_talk = true
		set_process_unhandled_input(true)


func _on_area_exited(area: Area2D) -> void:
		can_talk = false
		set_process_unhandled_input(false)


func _unhandled_input(event: InputEvent) -> void:
	if not can_talk:
		return

	if event.is_action_pressed("confirm_input"):
		_start_dialog()


func _start_dialog() -> void:
	if dialogue != null:
		# Debug prints so you can see what is happening
		#print("TalkArea: ", name, 
			  #" start_position: ", talking_start_position, 
			  #" dialogue: ", dialogue)

		DialogueManager._set_resources(speakers.duplicate())
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		DialogueManager.show_dialogue_balloon(dialogue, talking_start_position)
