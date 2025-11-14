##This node is the field sprite
##It only handles movement, graphical display, and interaction detection
##It is NOT used in battle
##Instantiated in every scene
##Reference to this node is held within global script CharControl
class_name NPC
extends Actor

@onready var sprite_2d = %Sprite2D
@onready var animation_player :AnimationPlayer= %AnimationPlayer
@onready var audio_stream_player_2d :AudioStreamPlayer2D= %AudioStreamPlayer2D
@onready var audio_listener_2d :AudioListener2D= %AudioListener2D #should be default listener
#Other areas look to see if this overlaps, monitorable
@onready var collision_shape_2d:CollisionShape2D = %CollisionShape2D #Collision shape for player
#@onready var state_machine:StateMachine= %StateMachine #State Machine reference

@export var npc_data:CharResource = null
var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

const DIR_4 : Array = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]
const _00_CHAR = preload("uid://prpth3t5akim")

signal direction_changed( new_direction )

func _ready()->void:
	setup_npc()
	#state_machine.initialize(self)
	pass

func setup_npc()->void:
	sprite_2d.texture = npc_data.char_sprite_sheet
	pass


func _physics_process(_delta)->void:
	move_and_slide()

func _process(_delta) -> void:
	#direction = Vector2( Input.get_axis("move_left",
	#"move_right"), Input.get_axis("move_up","move_down")).normalized()
	pass
	
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

func set_anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	elif cardinal_direction == Vector2.LEFT:
		return "left"
	else:
		return "right"
