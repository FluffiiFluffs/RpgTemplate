class_name EnemyAlert extends State


@onready var walk :State= %Walk
@onready var alert : State = %Alert
@onready var idle = %Idle

##The next state to transition to. Default "walk" state. Can be self
@export var next_state:State = walk

var pursue_time : float = 2.5 ##How long to continue pursueing the player after they have gone out of caution_range
var state_timer : Timer

func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()
	setup_timer()

## What happens when the state is entered
func enter() -> void:
	print(str(actor.name) + " entered alert state")
	actor.state_label.text = "A"
	if actor.has_chased_player == false:
		actor.has_chased_player = true


	pass
##Checks if the state is being used by an enemy
func if_enemy()->void:
	pass


## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	if actor.alert_mode == true:
		if CharDataKeeper.controlled_character:
			actor.direction = actor.global_position.direction_to(CharDataKeeper.controlled_character.global_position)
			actor.velocity = actor.alert_move_speed * actor.direction
			actor.update_direction_name()
			actor.update_animation("walk")
	#if actor.alert_mode == false and actor.caution_mode == false:
	elif actor.alert_mode == false:
		_out_of_alert_range()
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

func init():
	pass

##Creates timer, adds timer as a child node (so it can be queue_free'd!)
func setup_timer()->void:
	state_timer = Timer.new()
	state_timer.one_shot = true
	state_timer.wait_time = 1.0
	state_timer.process_mode = Node.PROCESS_MODE_INHERIT
	add_child(state_timer)
	state_timer.timeout.connect(_on_timer_timeout)


##Sets timer.wait_time, starts timer, and then awaits its finish
func use_timer(_wait_time:float)->void:
	state_timer.wait_time = _wait_time
	state_timer.start()
	#await state_timer.timeout ##This doesn't work for some reason
	
func _on_timer_timeout()->void:
		state_machine.change_state(idle)
	#if actor.see_player == false:
		#print(str(actor.name) + " alert state changing to idle")

func _out_of_alert_range()->void:
	#if state_timer.is_stopped():
		#actor.velocity = Vector2.ZERO
		#use_timer(pursue_time)
		#print(str(actor.name) + " out of alert range, pursue timer on")
	state_machine.change_state(idle)
