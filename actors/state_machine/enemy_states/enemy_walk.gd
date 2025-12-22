##npc_walk.gd[br]
##This state allows the Enemy to walk a predetermined distance from their origin point[br]
class_name EnemyWalk extends State
#
@onready var idle : State = %Idle
@onready var alert = %Alert
@onready var caution = %Caution

@export var next_state : State

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

## What happens when the state is entered
func enter() -> void:
	actor.state_label.text = "W"
	#print(str(actor.name) + " entered walk state")
	#Enemy will eventually walk towards the center point after being set.
	#Possible use is for after-cutscene
	if actor.walkcenterpoint:
		actor.walk_center = actor.walkcenterpoint.global_position
	walk_done = false
	if !actor.was_spawned:
		normal_walk()
	elif actor.was_spawned:
		spawned_walk()
	#print(str(actor.name) + " Start Walk State")
	pass
	
## What happens when the state is exited
func exit() -> void:
	state_timer.stop()
	pass
	
	
## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	##Immediately puts enemy into caution or alert mode depending on alert_type
	if actor.see_player == true:
		if actor.caution_mode == true and actor.alert_mode == false:
			if actor.alert_type == 0 or actor.alert_type == 1: #scared or cautious
				state_machine.change_state(caution)
			elif actor.alert_type == 2: #aggressive
				state_machine.change_state(alert)
		elif actor.alert_mode == true and actor.caution_mode == false:
			state_machine.change_state(alert)

	
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

##Begins walk routine
func normal_walk()->void:
	actor.walk_duration = randf_range(actor.walk_min, actor.walk_max) #walk duration random
	var _dir : Vector2 = actor.DIR_4[randi_range(0,3)] #pick a random direction
	#print(str(_dir))
	#if outside the walking range, finds the best way to get back to the center
	if abs(actor.global_position.distance_to(actor.walk_center)) > actor.walk_range * actor.tile_size:
		#print(str(actor.name) + " OUT OF CENTER RANGE!")
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
	#await get_tree().create_timer(actor.walk_duration, false).timeout ##Creates memory leak!!
	use_timer(actor.walk_duration)
	if next_state == null: #ensures next state is something
		next_state = idle
	#walk_done = true


func spawned_walk()->void:
	actor.walk_duration = randf_range(actor.walk_min, actor.walk_max) #walk duration random
	var _dir : Vector2 = actor.DIR_4[randi_range(0,3)] #pick a random direction
	var dist_to_center_x = abs(actor.global_position.x - actor.walk_shape.global_position.x)
	var dist_to_center_y = abs(actor.global_position.y - actor.walk_shape.global_position.y)
	#print("dist_to_center_x " + str(dist_to_center_x))
	#print("dist_to_center_y " + str(dist_to_center_y))
	var farthest_y = abs(actor.walk_extents_y / 2)
	#print("farthest_y " + str(farthest_y))
	var farthest_x = abs(actor.walk_extents_x / 2)
	#print("farthest_y " + str(farthest_x))
	#if outside the walking range, finds the best way to get back to the center
	if dist_to_center_x > farthest_x or dist_to_center_y > farthest_y:
		#print(str(actor.name) + " OUT OF CENTER RANGE!")
		var dir_to_area : Vector2 = actor.global_position.direction_to(actor.walk_shape.global_position)
		var best_direction : Array[float] = []
		for d in actor.DIR_4:
			best_direction.append (d.dot(dir_to_area))
		_dir = actor.DIR_4[best_direction.find(best_direction.max())]
	actor.direction = _dir
	actor.velocity = actor.move_speed * _dir #begins moving towards target position
	actor.direction = actor.global_position.direction_to(actor.global_position + _dir)
	actor.update_direction_name()
	actor.update_animation("walk")
	#await get_tree().create_timer(actor.walk_duration, false).timeout # Creates memory leak if not done!
	use_timer(actor.walk_duration)
	if next_state == null: #ensures next state is something
		next_state = idle
	#walk_done = true


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
	#await state_timer.timeout
	
func _on_timer_timeout()->void:
	
	state_machine.change_state(next_state)
	pass
