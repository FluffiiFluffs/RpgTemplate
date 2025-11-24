class_name InteractArea
extends Area2D


###Use if there should be speakers present during the interaction
@export var speakers : Array[SpeakerResource] = []
###Dialogue resource to be used
@export var dialogue : Resource
##Debug flag. Needs to be off by default.[br]
##Used for turning this area on and off
@export var area_active : bool = false
###Controlled through DialogueManager calling update_times_interacted() in interact_manager[br]
###Possible use for if player needs to interact with this node several times
@export var times_interacted : int = 0


func _ready()->void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	set_process_unhandled_input(false)

func _on_area_entered(_area: Area2D) -> void:
		area_active = true
		set_process_unhandled_input(true)

func _on_area_exited(_area: Area2D) -> void:
		area_active = false
		set_process_unhandled_input(false)

func _start_dialog()->void:
	set_self_to_global()
	pass

func set_self_to_global()->void:
	Interact.interact_node = self
	
func _unhandled_input(event: InputEvent) -> void:
	if not area_active:
		return

	if event.is_action_pressed("confirm_input"):
		_start_dialog()
