##This node is the field sprite
##It only handles movement, graphical display, and interaction detection
##It is NOT used in battle
##Instantiated in every scene
##Reference to this node is held within global script CharControl
####
class_name PlayerCharacter
extends Actor

@onready var sprite_2d = %Sprite2D
@onready var animation_player :AnimationPlayer= %AnimationPlayer
@onready var audio_stream_player_2d :AudioStreamPlayer2D= %AudioStreamPlayer2D
@onready var audio_listener_2d :AudioListener2D= %AudioListener2D #should be default listener
#Other areas look to see if this overlaps, monitorable
@onready var interact_area_trigger_2d = %InteractAreaTrigger2D #area for interaction detection
@onready var collision_shape_2d:CollisionShape2D = %CollisionShape2D #Collision shape for player
@onready var state_machine:StateMachine= %StateMachine #State Machine reference

@export var move_speed : float = 115.0
@export var run_speed : float = move_speed * 2.0
@export var original_move_speed : float = 115.0

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

## 0 = RIGHT, 1 = DOWN, 2 = LEFT, 3 = UP
const DIR_4 : Array = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]

signal direction_changed( new_direction )

func _ready()->void:
	#region moved to scene_manager.make_player(), it did the same thing anyways
	#prevents null error
	#if CharDataKeeper.slot00 == null:
		#CharDataKeeper.slot00 = _00_CHAR
		#sprite_2d = CharDataKeeper.slot00.char_sprite_sheet
	#CharDataKeeper.controlled_character_data = CharDataKeeper.slot00
	#stores reference to this node in CharDataKeeper global so it can be accessed globally if needed
	#CharDataKeeper.controlled_character = self
	#endregion
	state_machine.initialize(self)

func _physics_process(_delta)->void:
	move_and_slide()

func _process(_delta) -> void:
	pass
	
func _unhandled_input(_event):
	direction = Vector2( Input.get_axis("move_left",
	"move_right"), Input.get_axis("move_up","move_down")).normalized()

##Updates sprite_2d of controlled character for field movement when changed
##Slot00 is always the chararacter the player controls
func update_player_character()->void:
	sprite_2d = CharDataKeeper.slot00.char_sprite_sheet
	

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

func update_animation(state : String) -> void:
	animation_player.play( state + "_" + set_anim_direction())

##Plays a specific animation. _direction is optional.
func play_animation(_name:String, _direction:String="down"):
	if _direction:
		animation_player.play("_name" + "_" + "_direction")
	else:
		animation_player.play("_name")

#
func set_anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	elif cardinal_direction == Vector2.LEFT:
		return "left"
	else:
		return "right"
