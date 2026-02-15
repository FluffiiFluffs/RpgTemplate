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
@onready var party : Node2D = %Party
