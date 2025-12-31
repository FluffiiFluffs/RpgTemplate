class_name PartyFollow
extends State
#party_follow.gd

@onready var idle : State = %Idle
@export var next_state:State = idle
##How far to stop following
var stopfollowdist : int = 32


func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()

## What happens when the state is entered
func enter() -> void:
	actor.state_label.text = "F"
	actor = get_parent().get_parent()
	state_machine = get_parent()

## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	if actor == null:
		return idle
	if actor.actor_to_follow == null:
		printerr(str(actor.name) + " IN FOLLOW STATE BUT NO ACTOR TO FOLLOW!")
		return idle
	if actor.global_position.distance_to(actor.actor_to_follow.global_position) < stopfollowdist-6:
		return idle
	if actor.global_position.distance_to(actor.actor_to_follow.global_position) > stopfollowdist+6:
		actor.direction = actor.global_position.direction_to(actor.actor_to_follow.global_position)
		actor.move_speed = actor.actor_to_follow.move_speed #allows follower to run with who they are following
		actor.velocity = actor.move_speed * actor.direction
		actor.set_direction()
		actor.update_animation("walk")
		pass
	return null

##
## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

func init():
	pass
