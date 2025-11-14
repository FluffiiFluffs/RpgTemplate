@tool
##npc.gd
class_name NPC
extends Actor

@onready var sprite_2d = %Sprite2D
@onready var animation_player :AnimationPlayer= %AnimationPlayer
@onready var audio_stream_player_2d :AudioStreamPlayer2D= %AudioStreamPlayer2D
@onready var audio_listener_2d :AudioListener2D= %AudioListener2D #should be default listener
#Other areas look to see if this overlaps, monitorable
@onready var collision_shape_2d:CollisionShape2D = %CollisionShape2D #Collision shape for player
@onready var state_machine:StateMachine= %StateMachine #State Machine reference
##Detects the player
@onready var walk : State = %Walk
@onready var wander_area : Area2D = %WanderArea
@onready var wander_shape :CollisionShape2D= %WanderShape
@onready var p_det_timer : Timer = %PDetTimer
@onready var p_det_area = %P_Det_Area


##Data Resource for this NPC. Must be set!
@export var npc_data:CharResource = null
##NPC patrols area.[br] Walk mode will be false if this is on!
@export var npc_will_patrol : bool = false
##NPC will walk around an area (define radius in walk>inspector).[br] OFF if patrol is ON!
@export var npc_will_walk : bool = false

@export_category("Walk AI")
@export var next_state : State
##How far to walk from origin point, multiplied by tile size
@export var walk_range : float = 3
##Walk Center Point if needed. If none, global position of actor is used
@export var walkcenterpoint:WalkCenterPoint=null
##How fast to walk
@export var walk_speed : float = 30.0
##How large the tiles for this project are (default is 16)
@export var tile_size : float = 16
##Minimum time to walk
@export var walk_min : float = 0.75
##Maximum time to walk
@export var walk_max : float = 1.25
##Original position in the scene. Set the scene loads this script
var walk_center : Vector2 = Vector2.ZERO
##How long to walk, random between min and max. New value set each time this state is entered.
var walk_duration : float = 1.0
##For debugging!
@export var free_wander_area : bool = true




var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
##Was the player found?
var player_detected : bool = false

const DIR_4 : Array = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]
const _00_CHAR = preload("uid://prpth3t5akim")

signal player_is_detected
signal player_is_not_detected
signal direction_changed( new_direction )

func _ready()->void:
	if Engine.is_editor_hint():
		return
	setup_npc()
	if_walking()
	pass

##Setup routine for NPC
func setup_npc()->void:
	sprite_2d.texture = npc_data.char_sprite_sheet
	walk_center = global_position
	state_machine.initialize(self)
	p_det_timer.timeout.connect(_check_for_player)

	pass

func if_walking()->void:
	if free_wander_area == true: #for debugging
		wander_area.queue_free()  #for debugging
	elif free_wander_area == false:  #for debugging
		if walkcenterpoint == null:
			var warea = wander_area  #for debugging
			wander_shape.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))  #for debugging
			remove_child(warea)  #for debugging
			warea.global_position = global_position  #for debugging
			add_sibling.call_deferred(warea)  #for debugging
		elif walkcenterpoint != null:
			var warea = wander_area  #for debugging
			wander_shape.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))  #for debugging
			remove_child(warea)  #for debugging
			warea.global_position = walkcenterpoint.global_position  #for debugging
			add_sibling.call_deferred(warea)  #for debugging
	#If a walkcenterpoint is set in the inspector, it becomes the walk_center for walk state
	#NPC will eventually walk to walk_center.global_position after scene load
	if walkcenterpoint:
		walk_center = walkcenterpoint.global_position

	


func _physics_process(_delta)->void:
	if Engine.is_editor_hint():
		return	
	move_and_slide()

func _process(_delta) -> void:
	if Engine.is_editor_hint():
		wander_shape.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))
		return
	pass

func set_direction() -> bool:
	if direction == Vector2.ZERO:
		return false

	var direction_id : int = int( round( ( direction + cardinal_direction * 0.1 ).angle() / TAU * DIR_4.size() ) )
	var new_dir = DIR_4 [ direction_id ]
		
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	direction_changed.emit( new_dir )
	
	return true

##Updates animation
func update_animation(state : String) -> void:
	animation_player.play( state + "_" + set_anim_direction())

func set_anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		#print(str(name) + " going down")
		return "down"
	elif cardinal_direction == Vector2.UP:
		#print(str(name) + " going up")
		return "up"
	elif cardinal_direction == Vector2.LEFT:
		#print(str(name) + " going left")		
		return "left"
	else:
		#print(str(name) + " going right")		
		return "right"

##Allows the center point of walk routine to be set after scene load (cutscene possibly)
func set_walk_center_point(_wcp:WalkCenterPoint)->void:
	walk.walkcenterpoint = _wcp.global_position

func update_direction(_target_position:Vector2)->void:
	direction = global_position.direction_to(_target_position)

func _check_for_player()->void:
	if p_det_area.overlaps_body(CharDataKeeper.controlled_character):
		player_detected = true
		player_is_detected.emit()
	elif !p_det_area.overlaps_body(CharDataKeeper.controlled_character):
		player_detected = false
		player_is_not_detected.emit()
