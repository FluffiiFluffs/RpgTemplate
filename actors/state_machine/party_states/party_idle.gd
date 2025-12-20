class_name PartyIdle
extends State
#party_idle.gd

@onready var walk : State = %Walk
@onready var follow : State = %Follow


func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()
	#Stops player from moving when dialogue starts
	DialogueManager.dialogue_started.connect(_started_dialogue)
	
## What happens when the state is entered
func enter() -> void:
	actor.state_label.text = "I"
	actor.animation_player.play("idle" + "_" + actor.set_anim_direction())
	actor.update_animation("idle")
	#actor.velocity = Vector2.ZERO

## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	if actor.is_controlled:
		if actor.direction != Vector2.ZERO:
			return walk
		actor.velocity = Vector2.ZERO
	else:
		if actor.is_following:
			actor.velocity = Vector2.ZERO
			if actor.actor_to_follow.velocity != Vector2.ZERO:
				return follow
	
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
