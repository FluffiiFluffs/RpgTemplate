@tool
class_name EnemyPatrol extends State
#
@onready var idle = %Idle
@onready var caution = %Caution
@onready var alert = %Alert

var patrol_locations: Array[PatrolLocation]
var current_location_index: int = 0
var target: PatrolLocation
var direction: Vector2
var idle_duration : float

const COLORS = [ Color(1,0,0), Color(1,1,0), Color(0,1,0), Color(0,1,1), Color(0,0,1), Color(1,0,1) ]

func _ready() -> void:
	await get_tree().process_frame
	actor = get_parent().get_parent()
	state_machine = get_parent()
	gather_patrol_locations()
	if Engine.is_editor_hint():
		child_entered_tree.connect( gather_patrol_locations )
		child_order_changed.connect( gather_patrol_locations )
		return
	if patrol_locations.size() == 0:
		return
	target = patrol_locations[0]

## What happens when the state is entered
func enter() -> void:
	actor.state_label.text = "P"
	if patrol_locations.size() < 2:
		printerr("NPC" + str(actor.name) + " DOES NOT HAVE ANY PATROL LOCATIONS AS CHILDREN!")
		printerr("NPC " + str(actor.name) + " SET TO WANDER MODE")
		actor.npc_will_patrol = false
		actor.npc_will_walk = true
		state_machine.change_state(idle)
	if target:
		if target.target_position.distance_to(actor.global_position) < 1:
			current_location_index = (current_location_index + 1) % patrol_locations.size()
			target = patrol_locations[current_location_index]
		walk_phase()  # begin by walking toward the first target
	pass

## What happens when the state is exited
func exit() -> void:
	if target == null:
		idle_duration = 1.0
	elif target != null:
		idle_duration = target.wait_time
	# velocity cleanup so you do not carry motion into the next state
	actor.velocity = Vector2.ZERO	
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	##Immediately puts enemy into caution or alert mode depending on alert_type
	if actor.caution_mode == true:
		if actor.alert_type == 0 or actor.alert_type == 1: #scared or cautious
			return caution
		elif actor.alert_type == 2: #aggressive
			return alert
	elif actor.alert_mode == true:
		return alert

	if !patrol_locations.is_empty():
		
		# if a player interrupt is active, stop here
		if actor.player_detected:
			return idle

		# continuous steering straight to the current target
		var to_target: Vector2 = target.target_position - actor.global_position
		var dist: float = to_target.length()

		# arrive exactly at the corner if we would pass it this frame
		var step: float = actor.move_speed * _delta
		if dist <= step:
			return idle

		# otherwise keep moving straight toward the target
		direction = to_target / dist
		actor.direction = direction
		actor.velocity = actor.move_speed * direction
		actor.update_direction(target.target_position)
		actor.update_direction_name()
		actor.update_animation("walk")
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

func init():
	pass
	
func gather_patrol_locations(_n: Node = null) -> void:
	patrol_locations = []
	if actor.patrol_parent != null:
		for c in actor.patrol_parent.get_children():
			if c is PatrolLocation:
				patrol_locations.append(c)
				
	if Engine.is_editor_hint():
		if patrol_locations.size() > 0:
			for i in patrol_locations.size():
				var _p = patrol_locations[ i ] as PatrolLocation
				
				if not _p.transform_changed.is_connected( gather_patrol_locations ):
					_p.transform_changed.connect( gather_patrol_locations )
				
				_p.update_label( str(i) )
				_p.modulate = _get_color_by_index( i )
				
				var _next : PatrolLocation
				if i < patrol_locations.size() - 1:
					_next = patrol_locations[ i + 1 ]
				else:
					_next = patrol_locations[ 0 ]
				_p.update_line( _next.position )
				
				
func walk_phase() -> void:
	actor.direction = actor.global_position.direction_to(target.target_position)
	actor.velocity = actor.move_speed * actor.direction
	actor.update_direction(target.target_position)
	actor.update_direction_name()
	actor.update_animation("walk")


func _get_color_by_index( i : int ) -> Color:
	var color_count : int = COLORS.size()
	while i > color_count - 1:
		i -= color_count
	return COLORS[ i ]
