class_name EnemyCaution extends State

@onready var idle = %Idle
@onready var alert = %Alert


##The next state to transition to. Default "walk" state. Can be self
@export var next_state:State = null


func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()

## What happens when the state is entered
func enter() -> void:
	actor.state_label.text = "C"
	if actor.alert_mode == true or actor.caution_mode == true and !actor.has_chased_player:
		print(str(actor.name) + " entered caution state")
	elif actor.alert_mode == true or actor.caution_mode == true and actor.has_chased_player:
		print(str(actor.name) + " entered caution state, but has chased player. Chasing player")
	pass

## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	actor.velocity = Vector2.ZERO
	if CharDataKeeper.controlled_character:
		if actor.alert_mode == true or actor.caution_mode == true and actor.has_chased_player:
			actor.direction = actor.global_position.direction_to(CharDataKeeper.controlled_character.global_position)
			actor.velocity = actor.alert_move_speed * actor.direction
			actor.update_direction_name()
			actor.update_animation("walk")
		if actor.caution_mode == true:
			var _player : PartyMember = CharDataKeeper.controlled_character
			actor.direction = actor.global_position.direction_to(_player.global_position)
			actor.update_direction_name()
			actor.update_animation("idle")
		elif actor.caution_mode == false:
			return idle
		if actor.alert_mode == true:
			return alert
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:

	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

func init():
	pass
