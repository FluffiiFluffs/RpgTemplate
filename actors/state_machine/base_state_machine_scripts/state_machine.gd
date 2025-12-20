class_name StateMachine extends Node2D


var states: Array [ State ]
var prev_state : State
var current_state : State
var next_state : State

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	
	
	
func _process(delta) -> void:
	change_state( current_state.process(delta))
	
func _physics_process(delta) -> void:
	change_state( current_state.physics(delta))
	
func _unhandled_input(event) -> void:
	change_state ( current_state.handle_input(event))
		
	

## Sets up state machine
func initialize(_actor:Actor) -> void:
	states = []
	#finds nodes with script type of State and appends them to an array
	for child in get_children():
		if child is State:
			states.append(child)
	if states.size() == 0:
		return
	#states[0].state_machine = self
	#states[0].actor = _actor
	#sets player initial state to 0 (idle)
	for state in states:
		state.init()
	process_mode = Node.PROCESS_MODE_INHERIT
	change_state(states[0])




##Notifies current state if it needs to change
func change_state(new_state : State) -> void:
	if new_state == current_state or new_state == null:
		return
	
	next_state = new_state
	
	# Exits current state when changing states
	if current_state:
		current_state.exit()
	prev_state = current_state
	current_state = new_state
	current_state.enter()

##Uses a string to force a state. The state must exist.
func force_state_by_name(state_name: String) -> void:
	var target = state_name.strip_edges().to_lower()

	var available: Array[String] = []

	for child in get_children():
		var _state = child as State
		if _state == null:
			continue

		available.append(String(child.name))

		if String(child.name).to_lower() == target:
			change_state(_state)
			return

	push_error("%s: State not found (%s). Available: %s" % [name, state_name, ", ".join(available)])
