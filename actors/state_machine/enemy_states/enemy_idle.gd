class_name EnemyIdle extends State


@onready var follow : State = %Follow
@onready var walk :State= %Walk
@onready var patrol :State= %Patrol
@onready var chase : State = %Chase
##The next state to transition to. Default "walk" state. Can be self
@export var next_state:State = walk

var idle_duration : float = 1.0
var state_timer : Timer

func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()
	setup_timer()


## What happens when the state is entered
func enter() -> void:
	if actor.player_detected == false: #if no player
		if actor.is_following == true:
			next_state = follow
			actor.will_walk = false
			actor.will_patrol = false
		elif actor.will_patrol == true and !actor.is_following: #if patrol is on
			idle_duration = patrol.idle_duration #idle for the duration determined in patrol
			next_state = patrol #after idle done, patrol (move to next location)
		elif actor.will_patrol == false and !actor.is_following: #if patrol is off
			if actor.will_walk == true and !actor.is_following: #if wander is on
				idle_duration = randf_range(actor.idle_min,actor.idle_max) #random idle duration
				next_state = walk #walk around after idle done
			elif actor.will_walk == false and !actor.is_following: #if patrol and walk are false...normal idle
				idle_duration = randf_range(actor.idle_min,actor.idle_max) #random idle duration
				next_state = self #keep idling. Forever.
	elif actor.player_detected == true:
		state_machine.change_state(chase)
	start_idle()
##Checks if the state is being used by an enemy
func if_enemy()->void:
	pass


## What happens when the state is exited
func exit() -> void:
	state_timer.stop()
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
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

##Begins idle routine
func start_idle()-> void:
	#print(str(actor.name) + " Start Idle State")
	#if actor is NPC:
		#if actor.player_detected == true:
			#if CharDataKeeper.controlled_character != null:
				#actor.update_direction(CharDataKeeper.controlled_character.global_position)
				#actor.update_direction_name()
				#idle_duration = 2.0
	#if !actor.is_following:
		#idle_duration = randf_range(actor.idle_min,actor.idle_max) #Randomizes idle duration
	#else:
		#idle_duration = 0.1
	actor.velocity = Vector2.ZERO #Stops any velocity
	#actor.update_animation() #from previous iteration1
	actor.update_animation("idle")
	#idle timer, does not process while paused
	#await get_tree().create_timer(idle_duration,false).timeout ##Causes memory leak if timer is not done and enemy is queue_free()'d!!!!!
	#await get_tree().process_frame #may not need....
	use_timer(randf_range(actor.idle_min, actor.idle_max))
	if next_state == null:
		next_state = self
	if next_state == self: #if wander and patrol are false...
		start_idle() #keep idling
		return
	if next_state != self: #if wander or patrol are true...
		state_machine.change_state(next_state) #change to that state
		

##Creates timer, adds timer as a child node (so it can be queue_free'd!)
func setup_timer()->void:
	state_timer = Timer.new()
	state_timer.one_shot = true
	state_timer.wait_time = 1.0
	state_timer.process_mode = Node.PROCESS_MODE_INHERIT
	add_child(state_timer)

##Sets timer.wait_time, starts timer, and then awaits its finish
func use_timer(_wait_time:float)->void:
	state_timer.wait_time = _wait_time
	state_timer.start()
	await state_timer.timeout
	
