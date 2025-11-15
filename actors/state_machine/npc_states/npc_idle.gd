class_name NPCIdle extends State

@onready var walk :State= %Walk
@onready var patrol :State= %Patrol
##The next state to transition to. Default "walk" state. Can be self
@export var next_state:State = walk


var idle_duration : float = 1.0

## What happens when the state is entered
func enter() -> void:
	if_npc()
	if_enemy()
	start_idle()
	
##Checks if the state is being used by an NPC.	
func if_npc()->void:
	if actor is NPC: #if the actor using this script is an NPC...
		if actor.player_detected == false: #if no player
			if actor.npc_will_patrol == true: #if patrol is on
				idle_duration = patrol.idle_duration #idle for the duration determined in patrol
				next_state = patrol #after idle done, patrol (move to next location)
			elif actor.npc_will_patrol == false: #if patrol is off
				if actor.npc_will_walk == true: #if wander is on
					idle_duration = randf_range(actor.idle_min,actor.idle_max) #random idle duration
					next_state = walk #walk around after idle done
				elif actor.npc_will_walk == false: #if patrol and walk are false...normal idle
					idle_duration = randf_range(actor.idle_min,actor.idle_max) #random idle duration
					next_state = self #keep idling. Forever.


##Checks if the state is being used by an enemy
func if_enemy()->void:
	pass


## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	#if actor.direction != Vector2.ZERO:
		#return walk
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
	print(str(actor.name) + " Start Idle State")
	if actor is NPC:
		if actor.player_detected == true:
			if CharDataKeeper.controlled_character != null:
				actor.update_direction(CharDataKeeper.controlled_character.global_position)
				actor.update_direction_name()
				idle_duration = 2.0
	idle_duration = randf_range(actor.idle_min,actor.idle_max) #Randomizes idle duration
	actor.velocity = Vector2.ZERO #Stops any velocity
	#actor.update_animation() #from previous iteration
	actor.update_animation("idle")
	#idle timer, does not process while paused
	await get_tree().create_timer(idle_duration,false).timeout 
	#await get_tree().process_frame #may not need....
	if next_state == null:
		next_state = self
	if next_state == self: #if wander and patrol are false...
		start_idle() #keep idling
		return
	if next_state != self: #if wander or patrol are true...
		state_machine.change_state(next_state) #change to that state
