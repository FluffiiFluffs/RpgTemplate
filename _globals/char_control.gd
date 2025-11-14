##Global Script char_control
##This script (which is attached a global scene) controls the player character
##This is so different characters can be swapped out as the "main" if needed
##Holds reference to PlayerCharacter (currently controlled character node)
extends Node2D

@export var controlled_character_data:CharResource
@export var controlled_character:PlayerCharacter

var direction : Vector2 = Vector2.ZERO
var cardinal_direction : Vector2 = Vector2.DOWN
const DIR_4 : Array = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]



#test



func _process(_delta)->void:
	direction = Vector2( Input.get_axis("move_left",
		"move_right"), Input.get_axis("move_up","move_down")).normalized()






func set_direction() -> bool:
	if direction == Vector2.ZERO:
		return false

	var direction_id : int = int( round( ( direction + cardinal_direction * 0.1 ).angle() / TAU * DIR_4.size() ) )
	var new_dir = DIR_4 [ direction_id ]
		
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	#direction_changed.emit( new_dir )
	#sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	
	return true
