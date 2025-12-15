class_name PlayerIdle extends State

@onready var walk :State= %Walk

func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()
	#Stops player from moving when dialogue starts
	DialogueManager.dialogue_started.connect(_started_dialogue)
	
## What happens when the state is entered
func enter() -> void:
	actor.animation_player.play("idle" + "_" + actor.set_anim_direction())
	actor.update_animation("idle")

## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	if actor.direction != Vector2.ZERO:
		return walk
	actor.velocity = Vector2.ZERO
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

func init():
	pass

##Prevents player from moving when dialogue starts
func _started_dialogue(_resource:Resource)->void:
	state_machine.change_state(self)
	actor.direction = Vector2.ZERO
	actor.velocity = Vector2.ZERO

func force_idle()->void:
	state_machine.change_state(self)
	actor.direction = Vector2.ZERO
	actor.velocity = Vector2.ZERO
