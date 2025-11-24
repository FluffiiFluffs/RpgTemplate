##interact_manager.gd
##global Interact
extends Node2D
##Holds values and controls InspectArea nodes the player is interacting with

##holds reference to current InspectArea being interacted with by player
@export var interact_node : InteractArea = null

##Clears interact_node
func clear_interact_node()->void:
	interact_node = null

##Increases times_interacted on interact_node[]
##(to be checked with DialogueManager for different text at different values
func increase_times_interacted()->void:
	if interact_node != null:
		interact_node.times_interacted += 1

##Turns off ability to interact the area at all (no messages)
func area_active_on()->void:
	if interact_node != null:
		interact_node.area_active = false

##Turns off ability to interact the area at all (no messages)
func area_active_off()->void:
	if interact_node != null:
		interact_node.area_active = false
		
##Flags interact_node for having an item
func item_here_on()->void:
	if interact_node != null:
		interact_node.item_here = true

##Flags interact_node for not having an item
func item_here_off()->void:
	if interact_node != null:
		interact_node.item_here = false
		
func play_parent_animation(anim_name:String)->void:
	for child in interact_node.get_parent().get_children():
		if child is AnimationPlayer:
			child.play(anim_name)
			break
	
