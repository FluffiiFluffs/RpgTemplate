class_name EnemyIdle extends State


@onready var follow : State = %Follow
@onready var walk :State= %Walk
@onready var patrol :State= %Patrol
@onready var caution = %Caution
@onready var alert = %Alert

##The next state to transition to. Default "walk" state. Can be self
@export var next_state:State = walk

var idle_duration : float = 1.0
var state_timer : Timer

func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()
	setup_timer()
	state_timer.timeout.connect(_on_timer_timeout)



## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	actor.velocity = Vector2.ZERO
	
	##Immediately puts enemy into caution or alert mode depending on alert_type
	if actor.caution_mode == true:
		if actor.alert_type == 0 or actor.alert_type == 1: #scared or cautious
			return caution
		elif actor.alert_type == 2: #aggressive
			return alert
	elif actor.alert_mode == true:
		return alert

	return null


## What happens when the state is entered
func enter() -> void:
	print(str(actor.name) + " entered idle state")
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
		#print(str(actor.name) + " Start Idle State")
	actor.velocity = Vector2.ZERO #Stops any velocity
	actor.update_animation("idle")
	#await get_tree().create_timer(idle_duration,false).timeout ##Causes memory leak if timer is not done and enemy is queue_free()'d!!!!!
	use_timer(randf_range(actor.idle_min, actor.idle_max))
	actor.state_label.text = "I"
	
	##TODO Fix this
	#If the enemy is outside of caution and alert range, wait 5 seconds and then despawn.
	#Allows enemy to despawn outside of the spawn area after other enemies have despawned.
	if actor.has_seen_player and actor.was_spawned and actor.has_chased_player and !actor.see_player:
			state_timer.stop()
			use_timer(5.0)

	



## What happens when the state is exited
func exit() -> void:
	state_timer.stop()
	pass



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

##Sets timer.wait_time, starts timer, and then awaits its finish
func use_timer(_wait_time:float)->void:
	state_timer.wait_time = _wait_time
	state_timer.start()
	#await state_timer.timeout
	
func _on_timer_timeout()->void:
	if actor.has_seen_player and actor.was_spawned and actor.has_chased_player and !actor.see_player:
		actor.enemy_spawner.enemy_killed()
		actor.queue_free()
	if next_state == null:
		next_state = self
	if next_state == self: #if wander and patrol are false...
		state_machine.change_state(self)
	if next_state != self: #If next state to be in isn't idle, change to next state
		state_machine.change_state(next_state) #change to that state
	state_machine.change_state(next_state)
	pass
