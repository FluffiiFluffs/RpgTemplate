##npc_walk.gd[br]
##This state allows the NPC to walk a predetermined distance from their origin point[br]
class_name NPCWalk extends State
#
@export var move_speed : float = 115.00
@onready var idle : State = %Idle


#@export_category("Walk AI")
@export var next_state : State

##This is kept now kept in the NPC script so it can be adjusted top level
###How far to walk from origin point, multiplied by tile size
#@export var walk_range : float = 3
###Walk Center Point if needed. If none, global position of actor is used
#@export var walkcenterpoint:WalkCenterPoint=null
###How fast to walk
#@export var walk_speed : float = 30.0
###How large the tiles for this project are (default is 16)
#@export var tile_size : float = 16
###Minimum time to walk
#@export var walk_min : float = 1.0
###Maximum time to walk
#@export var walk_max : float = 2.5

##If true, end of state is triggered.
var walk_done : bool = false 
var state_timer : Timer


func _process(_delta)->void:
	pass
func init():
	pass
	
func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()
	setup_timer()
	#actor.walk_center = actor.global_position....normally


## What happens when the state is entered
func enter() -> void:
	#NPC will eventually walk towards the center point after being set.
	#Possible use is for after-cutscene
	if actor.walkcenterpoint:
		actor.walk_center = actor.walkcenterpoint.global_position
	walk_done = false
	start_walk()
	#print(str(actor.name) + " Start Walk State")
	pass
	
## What happens when the state is exited
func exit() -> void:
	state_timer.stop()
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
		walk_done = true
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
		#await get_tree().create_timer(actor.walk_duration, false).timeout ##Creates memory leak if queuefreed while active!
		use_timer(actor.walk_duration)
		if next_state == null: #ensures next state is something
			next_state = idle
		walk_done = true
	
	pass




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
	
