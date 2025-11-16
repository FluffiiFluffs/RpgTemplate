##npc_walk.gd[br]
##This state allows the Enemy to walk a predetermined distance from their origin point[br]
class_name EnemyWalk extends State
#
@export var move_speed : float = 115.00
@onready var idle : State = %Idle
@onready var chase : State = %Chase

@export var next_state : State

##If true, end of state is triggered.
var walk_done : bool = false 

func _process(_delta)->void:
	pass
func init():
	pass
	
func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()

## What happens when the state is entered
func enter() -> void:
	#Enemy will eventually walk towards the center point after being set.
	#Possible use is for after-cutscene
	if actor.walkcenterpoint:
		actor.walk_center = actor.walkcenterpoint.global_position
	walk_done = false
	start_walk()
	#print(str(actor.name) + " Start Walk State")
	pass
	
## What happens when the state is exited
func exit() -> void:
	pass
	
	
## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	if walk_done == true: #move to next state
		return next_state
	if actor.player_detected == true: #if player is detected, force idle state
		state_machine.change_state(idle)
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

##Begins walk routine
func start_walk()->void:
	if actor.player_detected == true: #if the player is found, enter idle state immediately
		state_machine.change_state(chase) #Chase the player!
	elif actor.player_detected == false: ##if player is NOT found...
		actor.walk_duration = randf_range(actor.walk_min, actor.walk_max) #walk duration random
		var _dir : Vector2 = actor.DIR_4[randi_range(0,3)] #pick a random direction
		#print(str(_dir))
		#if outside the walking range, finds the best way to get back to the center
		if abs(actor.global_position.distance_to(actor.walk_center)) > actor.walk_range * actor.tile_size:
			print(str(actor.name) + " OUT OF CENTER RANGE!")
			var dir_to_area : Vector2 = actor.global_position.direction_to(actor.walk_center)
			var best_direction : Array[float] = []
			for d in actor.DIR_4:
				best_direction.append (d.dot(dir_to_area))
			_dir = actor.DIR_4[best_direction.find(best_direction.max())]
		actor.direction = _dir
		actor.velocity = actor.walk_speed * _dir #begins moving towards target position
		actor.direction = actor.global_position.direction_to(actor.global_position + _dir)
		actor.update_direction_name()
		actor.update_animation("walk")
		await get_tree().create_timer(actor.walk_duration, false).timeout
		if next_state == null: #ensures next state is something
			next_state = idle
		walk_done = true

	pass
