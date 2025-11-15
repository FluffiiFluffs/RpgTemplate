class_name NPCFollow extends State
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
#func enter() -> void:
	#if not actor.is_following_player:
		#printerr(actor.name + " entered follow state but is_following_player is false, going back to idle")
		#state_machine.change_state(idle)
		#return
	#if actor.is_following_player:
		#var scene_root := get_tree().current_scene
		#for child in scene_root.get_children():
			#if child is PlayerPath:
				#actor.path_to_follow = child
				#actor._curve = child.curve
#
	## Set node_to_follow if needed
	#if actor.node_to_follow == null:
		#if actor.path_to_follow.playernode:
			#actor.node_to_follow = actor.path_to_follow.playernode
			#print("  node_to_follow set to: ", actor.node_to_follow.name)
		#else:
			#printerr("No controlled_character in CharDataKeeper, cannot set node_to_follow, going idle")
			#state_machine.change_state(idle)
			#return
	#else:
		##print("  node_to_follow already set to: ", actor.node_to_follow.name)
		#pass

## What happens when the state is exited
func exit() -> void:
	pass

## What happens during _process(): update while state is running
func process (_delta : float) -> State:
	if actor.fcurve != null:
		if actor.fcurve.point_count <2:
			return idle
		if actor.global_position.distance_to(actor.follow_point_global) < 1:
			return	idle
		if actor.is_following_player:
			if actor.fcurve.point_count - 1 < actor.place_in_line:
				return idle
			actor.follow_point_local = actor.fcurve.get_point_position(actor.fcurve.point_count - actor.place_in_line)
			actor.follow_point_global = actor.path_to_follow.to_global(actor.follow_point_local)
			if actor.global_position.distance_to(actor.follow_point_global) < 16:
				return idle
			elif actor.global_position.distance_to(actor.follow_point_global) > 16:
				actor.direction = actor.global_position.direction_to(actor.follow_point_global)
				if actor.global_position.distance_to(actor.follow_point_global) < 16:
					actor.follow_speed = actor.node_to_follow.move_speed * 0.75
				elif actor.global_position.distance_to(actor.follow_point_global) < 32:
					actor.follow_speed = actor.node_to_follow.move_speed
				elif actor.global_position.distance_to(actor.follow_point_global) > 32:
					actor.follow_speed = actor.node_to_follow.move_speed * 2.0
				actor.velocity = actor.follow_speed * actor.direction
				actor.update_direction_name()
				actor.update_animation("walk")
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
	
