class_name OLDNPCFollow extends State
#
#@onready var walk :State= %Walk

@onready var idle : State = %Idle
func _ready()->void:
	actor = get_parent().get_parent()
	state_machine = get_parent()
	
	
### What happens when the state is entered
func enter() -> void:
	#protects against null error if no node to follow set when entering state
	if actor.is_following_player == true:
			var player : PlayerCharacter = CharDataKeeper.controlled_character
			actor.path_to_follow = player.follow_me_path
			actor.fcurve = actor.path_to_follow.curve
			actor.node_to_follow = actor.path_to_follow.playernode
			if actor.node_to_follow == null:
				printerr(str(actor.name) + " in follow mode, but node_to_follow == null! Returning to idle!")
				state_machine.change_state(idle)
			else:
				if CharDataKeeper.controlled_character != null:
					actor.node_to_follow = actor.path_to_follow.playernode
	return


## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	#protects against null error, but fcurve should always exist due to the instantiated path scene already having one.
	if actor.fcurve != null:
		if actor.fcurve.point_count <2: #If not enough points, go back to idle
			return idle
		#if actor.global_position.distance_to(actor.follow_point_global) < 0.25: #checks if standing on targeted node
			#return	idle
		if actor.is_following_player: #if set to flllow player...
			 #if the point count is less than place in line return to 
			if actor.fcurve.point_count - 1 < actor.place_in_line:
				return idle
			actor.follow_point_local = actor.fcurve.get_point_position(actor.fcurve.point_count - actor.place_in_line)
			actor.follow_point_global = actor.path_to_follow.to_global(actor.follow_point_local)
			if actor.global_position.distance_to(actor.follow_point_global) < 8:
				return idle
			if actor.global_position.distance_to(actor.follow_point_global) > 8:
				actor.direction = actor.global_position.direction_to(actor.follow_point_global)
				#if actor.global_position.distance_to(actor.follow_point_global) < 10:
					#actor.follow_speed = actor.node_to_follow.move_speed * 0.75
				#elif actor.global_position.distance_to(actor.follow_point_global) < 20:
					#actor.follow_speed = actor.node_to_follow.move_speed
				#elif actor.global_position.distance_to(actor.follow_point_global) > 30:
					#actor.follow_speed = actor.node_to_follow.move_speed * 2.0
				actor.follow_speed = actor.node_to_follow.move_speed
				#moves the npc towards follow point
				actor.velocity = actor.follow_speed * actor.direction
				actor.update_direction_name() #updates direction name
				actor.update_animation("walk") #updates animation
				pass
	return null

## What happens during _physics_process(): update state is running
func physics( _delta: float) -> State:
	return null	
	
## What happens with input events while this state is running
func handle_input( _event: InputEvent) -> State:
	return null

func init():
	pass
	
