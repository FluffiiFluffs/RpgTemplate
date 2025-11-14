class_name PlayerWalk extends State

@export var move_speed : float = 115.00
@onready var idle = %Idle

func init():
	pass

## What happens when the state is entered
func enter() -> void:
	#actor.animation_player.play("walk" + "_" + actor.set_anim_direction())
	actor.update_animation("walk")
	#GlobalPlayerManager.is_moving = true
	pass
## What happens when the state is exited
func exit() -> void:
	pass
	
	
## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	if actor.direction == Vector2.ZERO:
		return idle
		
	actor.velocity = actor.direction * move_speed
	if actor.set_direction():
		#actor.animation_player.play("walk" + "_" + actor.set_anim_direction())
		actor.update_animation("walk")
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	#if _event.is_action_pressed("interact_input"):
		#GlobalPlayerManager.interact_pressed.emit()
	return null
