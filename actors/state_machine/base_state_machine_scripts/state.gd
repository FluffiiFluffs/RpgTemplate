class_name State extends Node2D

##Stores reference to the player that this PlayerState belongs to
var actor:FieldActor
var state_machine: StateMachine

func _init() -> void:
	pass

func _ready() -> void:
	actor = get_parent().get_parent()
	state_machine = get_parent()
	pass
	
## What happens when the state is entered
func enter() -> void:
	pass
## What happens when the state is exited
func exit() -> void:
	pass
	
	
## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null
