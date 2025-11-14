class_name NPCPatrol extends State
#
@onready var walk : State = %Walk

var idle_duration : float = 1.0


## What happens when the state is entered
func enter() -> void:
	pass
## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	#if actor.direction != Vector2.ZERO:
		#return walk
	#actor.velocity = Vector2.ZERO
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

func init():
	pass
