class_name PartyWalk
extends State
#party_walk.gd

@onready var idle : State = %Idle

func init():
	pass
	
func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()

## What happens when the state is entered
func enter() -> void:
	actor.state_label.text = "W"
	actor.animation_player.play("walk" + "_" + actor.set_anim_direction())
	actor.update_animation("walk")

## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	if actor.is_controlled:
		if Options.always_run == false:
			if Input.is_action_pressed("cancel_input"):
				actor.move_speed = actor.run_speed
				actor.is_running = true
			else:
				actor.move_speed = actor.original_move_speed
				actor.is_running = false
		elif Options.always_run == true:
			if Input.is_action_pressed("cancel_input"):
				actor.move_speed = actor.original_move_speed
				actor.is_running = false
			else:
				actor.move_speed = actor.run_speed
				actor.is_running = true
	if actor.direction == Vector2.ZERO:
		return idle
		
	actor.velocity = actor.direction * actor.move_speed
	if actor.set_direction():
		actor.animation_player.play("walk" + "_" + actor.set_anim_direction())
	return null	

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
