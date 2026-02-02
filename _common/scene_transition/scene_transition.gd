@tool
class_name SceneTransitioner
extends Area2D

enum SIDE {UP,DOWN,LEFT,RIGHT}


@onready var spawn_marker : Sprite2D = %SpawnMarker
@onready var center_marker : Sprite2D = %CenterMarker

##Scene to be loaded when character enters Area
@export_file("*.tscn") var scene_to_load : String = ""
##Name of the SceneTransition node to spawn at within the scene_to_load
@export var target_transition_area : String = "SceneTransition"

##Which direction the player faces when spawning from another scene
@export var spawn_direction : SIDE = SIDE.DOWN
##how far away from the center of this node to spawn the player on either the x or y axis depending on orientation
@export var distance_to_spawn : int = 32
##If the offset is ignored (depending on spawn_direction)
@export var center_player : bool = true



func _ready()->void:
	if Engine.is_editor_hint():
		set_spawn_marker()
		return

	body_entered.connect(on_body_entered)

	if spawn_marker != null and is_instance_valid(spawn_marker):
		spawn_marker.queue_free()
	if center_marker != null and is_instance_valid(center_marker):
		center_marker.queue_free()

	spawn_marker = null
	center_marker = null


func _process(_delta)->void:
	if Engine.is_editor_hint() == false:
		return
	if spawn_marker == null:
		return
	if is_instance_valid(spawn_marker) == false:
		return

	set_spawn_marker()




func on_body_entered(body : Node2D)->void:
	if not is_instance_valid(CharDataKeeper.controlled_character):
		return
	var player = body as FieldPartyMember
	if CharDataKeeper.controlled_character == player:
		if scene_to_load == "":
			return
		
		SceneManager.transition_entry_offset = player.global_position - global_position
		SceneManager.load_field_scene(scene_to_load, target_transition_area)



func set_spawn_marker()->void:
	match spawn_direction:
		SIDE.UP:
			spawn_marker.position = Vector2(0, -distance_to_spawn)
		SIDE.DOWN:
			spawn_marker.position = Vector2(0, distance_to_spawn)
		SIDE.LEFT:
			spawn_marker.position = Vector2(-distance_to_spawn, 0)
		SIDE.RIGHT:
			spawn_marker.position = Vector2(distance_to_spawn, 0)
	pass


func compute_spawn_offset(entry_offset : Vector2) -> Vector2:
	var offset : Vector2 = Vector2.ZERO

	match spawn_direction:
		SIDE.LEFT:
			offset.x = -float(distance_to_spawn)
			if center_player == false:
				offset.y = entry_offset.y

		SIDE.RIGHT:
			offset.x = float(distance_to_spawn)
			if center_player == false:
				offset.y = entry_offset.y

		SIDE.UP:
			offset.y = -float(distance_to_spawn)
			if center_player == false:
				offset.x = entry_offset.x

		SIDE.DOWN:
			offset.y = float(distance_to_spawn)
			if center_player == false:
				offset.x = entry_offset.x

	return offset
