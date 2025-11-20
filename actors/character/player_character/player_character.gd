##This node is the field sprite
##It only handles movement, graphical display, and interaction detection
##It is NOT used in battle
##Instantiated in every scene
##Reference to this node is held within global script CharControl
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
@onready var path_timer : Timer = %PathTimer

@export var move_speed : float = 115.0
@export var run_speed : float = move_speed * 2.0
@export var original_move_speed : float = 115.0

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var follow_me_path:Path2D=null

## 0 = RIGHT, 1 = DOWN, 2 = LEFT, 3 = UP
const DIR_4 : Array = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]
const _00_CHAR = preload("uid://prpth3t5akim")


signal direction_changed( new_direction )

func _ready()->void:
	#prevents null error
	if CharDataKeeper.slot00 == null:
		CharDataKeeper.slot00 = _00_CHAR
		sprite_2d = CharDataKeeper.slot00.char_sprite_sheet
	CharDataKeeper.controlled_character_data = CharDataKeeper.slot00
	#stores reference to this node in CharDataKeeper global so it can be accessed globally if needed
	CharDataKeeper.controlled_character = self
	state_machine.initialize(self)
	#path_timer.timeout.connect(make_path) ##defunct for npc follow code

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


###Defunct. Was for NPC follow code.
#func make_path() -> void:
	#var scene_root := get_tree().current_scene
	#if CharDataKeeper.controlled_character == null:
		#return	
	#for child in scene_root.get_children():
		#if child is PlayerPath: #finds PlayerPath if it exists...if found...
			#var curve = child.curve
			##gets curve point quantity...if over 25, then the oldest point is removed
			##may need to make this smaller for better performance
			#if curve.point_count >= 32:
				#curve.remove_point(0)
			##if player path found, and points are more than 1
			#if child.curve.point_count > 0:
				##stores the last point's position
				#var last_point_local : Vector2 = curve.get_point_position(curve.point_count - 1)
				##converts last_point_local position to global_position
				#var last_point_global : Vector2 = child.to_global(last_point_local)
				##If player is closer than 16 pixels to last point, do nothing
				#if last_point_global.distance_to(CharDataKeeper.controlled_character.global_position) < 16:
					#return
			##creates a new point on the curve if farther than the above number in pixels
			#var new_point_local : Vector2 = child.to_local(CharDataKeeper.controlled_character.global_position)
			#child.curve.add_point(new_point_local) #adds point to the curve in the path node which is now a child of current_scene (not the player)
			#return
	##if no PlayerPath node exists, then this creates a new one and adds the first point
	#var player_path: PlayerPath = PLAYER_PATH.instantiate()
	#player_path.name = "PlayerPath"
	#player_path.playernode = self
	#follow_me_path = player_path
	#scene_root.add_child(player_path)
	##adds first point
	#var first_point_local : Vector2 = player_path.to_local(CharDataKeeper.controlled_character.global_position)
	#player_path.curve.add_point(first_point_local)
