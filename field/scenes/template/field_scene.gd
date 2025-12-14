class_name FieldScene
extends Node2D

@export var field_id : StringName = &""
@export var enforce_draw_order : bool = true
@export var adopt_placed_actors_on_enter : bool = true

@onready var tile : Node2D = %Tile
@onready var ground1 : TileMapLayer = %Ground1
@onready var ground_2 : TileMapLayer = %Ground2
@onready var ground_3 : TileMapLayer = %Ground3
@onready var ground_4 : TileMapLayer = %Ground4
@onready var ground_5 : TileMapLayer = %Ground5
@onready var decor_bottom : TileMapLayer = %DecorBottom
@onready var decor_top : TileMapLayer = %DecorTop

@onready var navigation : NavigationRegion2D = %Navigation

@onready var markers : Node2D = %Markers
@onready var player_spawn : Node2D = %PlayerSpawn

@onready var interactables : Node2D = %Interactables
@onready var triggers : Node2D = %Triggers
@onready var triggers_audio : Node2D = %Audio
@onready var triggers_cutscene : Node2D = %Cutscene
@onready var triggers_encounter : Node2D = %Encounter
@onready var transition_areas : Node2D = %TransitionAreas

@onready var field_actors : Node2D = %FieldActors
@onready var placed_enemies : Node2D = %PlacedEnemies
@onready var enemy_spawners : Node2D = %EnemySpawners
@onready var placed_npcs : Node2D = %PlacedNPCs

func on_field_enter(spawn_id : StringName) -> void:
	if enforce_draw_order:
		_apply_draw_order_defaults()

	if field_actors != null:
		field_actors.y_sort_enabled = true

	if Engine.is_editor_hint() == false:
		if adopt_placed_actors_on_enter:
			_adopt_placed_actors()

	_restore_field_state()

func on_field_exit() -> void:
	_capture_field_state()


func get_actor_container() -> Node2D:
	return field_actors

func get_spawn_global_position(spawn_id : StringName) -> Vector2:
	if player_spawn == null:
		return global_position

	var want = String(spawn_id)

	for child in player_spawn.get_children():
		if child == null:
			continue
		if child.name != want:
			continue
		if child is Node2D:
			return (child as Node2D).global_position

	for child in player_spawn.get_children():
		if child is Node2D:
			return (child as Node2D).global_position

	return global_position

func _apply_draw_order_defaults() -> void:
	if ground1 != null:
		ground1.z_index = 0
	if decor_bottom != null:
		decor_bottom.z_index = 10
	if field_actors != null:
		field_actors.z_index = 20
	if decor_top != null:
		decor_top.z_index = 100

func _adopt_placed_actors() -> void:
	if field_actors == null:
		return

	_adopt_children(placed_npcs, field_actors)
	_adopt_children(placed_enemies, field_actors)

func _adopt_children(from_node : Node, to_node : Node) -> void:
	if from_node == null:
		return
	if to_node == null:
		return

	var children = from_node.get_children()
	for child in children:
		if child == null:
			continue

		from_node.remove_child(child)
		to_node.add_child(child)

func _restore_field_state() -> void:
	pass


func _capture_field_state() -> Dictionary:
	return {}
