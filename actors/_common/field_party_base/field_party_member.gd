class_name FieldPartyMember
extends FieldActor
##field_party_member.gd
##Attached to a party member's root node in their scene`

@onready var field_sprite : Sprite2D = %FieldSprite
@onready var animation_player :AnimationPlayer= %AnimationPlayer
@onready var audio_stream_player_2d :AudioStreamPlayer2D= %AudioStreamPlayer2D
@onready var audio_listener_2d :AudioListener2D= %AudioListener2D #should be default listener
#Other areas look to see if this overlaps, monitorable
@onready var collision_shape_2d:CollisionShape2D = %CollisionShape2D #Collision shape for player
@onready var state_machine:StateMachine= %StateMachine #State Machine reference
@onready var idle : State = %Idle
@onready var walk : State = %Walk
@onready var enemy_spawn_trigger = %EnemySpawnTrigger
@onready var interact_area_trigger_2d : Area2D = %InteractAreaTrigger2D #area for interaction detection
@onready var state_label : Label = %StateLabel
@onready var poison_marker_2d: Marker2D = %PoisonMarker2D

@export var is_controlled : bool = false
@export var move_speed : float = 115.0
@export var run_speed : float = move_speed * 2.0
@export var original_move_speed : float = 115.0
@export var battle_mode : bool = false
@export var is_running : bool = false

##Set during instantiation.
@export var pm_id : StringName = &""
@export_category("Follow AI")
##The actor this node will attempt to follow in the follow state
@export var actor_to_follow : FieldActor = null
##If set to true, NPC will attempt to follow actor_to_follow
@export var is_following : bool = false
##Set in follow state script, equal to actor_to_follow.move_speed 
@export var follow_speed : float = 50.0


var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var poison_tween : Tween = null
var poison_flash_enabled : bool = false

## 0 = RIGHT, 1 = DOWN, 2 = LEFT, 3 = UP
const DIR_4 : Array = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]

signal direction_changed( new_direction )

func _ready()->void:
	
	state_machine.initialize(self)
	setup_move_speed()
	if !Options.show_states:
		state_label.visible = false
	
func _physics_process(_delta)->void:
	move_and_slide()

func _process(_delta) -> void:
	if !SceneManager.is_loading_field_scene:
		if is_controlled:
			if GameState.gamestate == GameState.State.FIELD:
				direction = Vector2( Input.get_axis("move_left",
				"move_right"), Input.get_axis("move_up","move_down")).normalized()
			if direction != Vector2.ZERO:
				if CharDataKeeper.poison_timer.is_stopped():
					CharDataKeeper.poison_timer.start()

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


func set_anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	elif cardinal_direction == Vector2.LEFT:
		return "left"
	else:
		return "right"

func force_face_direction(new_facing : Vector2) -> void:
	if new_facing == Vector2.ZERO:
		return

	direction = Vector2.ZERO

	if abs(new_facing.x) > abs(new_facing.y):
		if new_facing.x < 0.0:
			cardinal_direction = Vector2.LEFT
		else:
			cardinal_direction = Vector2.RIGHT
	else:
		if new_facing.y < 0.0:
			cardinal_direction = Vector2.UP
		else:
			cardinal_direction = Vector2.DOWN

	direction_changed.emit(cardinal_direction)

	if animation_player != null:
		var anim_name = "idle_" + set_anim_direction()
		if animation_player.has_animation(anim_name):
			animation_player.play(anim_name)


func setup_move_speed()->void:
	if Options.always_run == true:
		move_speed = run_speed
		is_running = true
	elif Options.always_run == false:
		move_speed = original_move_speed
		is_running = false

func set_controlled_on()->void:
	is_controlled = true
	audio_listener_2d.make_current()
	enemy_spawn_trigger.monitorable = true
	interact_area_trigger_2d.monitorable = true
	set_collision_layer_value(2, false)
	set_collision_layer_value(1, true)

func set_controlled_off()->void:
	is_controlled = false
	audio_listener_2d.clear_current()
	enemy_spawn_trigger.monitorable = false
	interact_area_trigger_2d.monitorable = false
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, true)

func set_poison_flash(enabled : bool) -> void:
	if enabled and poison_flash_enabled:
		return
	if (not enabled) and (not poison_flash_enabled):
		return

	if poison_tween != null:
		poison_tween.kill()
		poison_tween = null

	if enabled:
		poison_flash_enabled = true
		poison_tween = create_tween()
		poison_tween.set_loops()
		poison_tween.tween_property(field_sprite, "self_modulate", Color(0.424, 0.0, 0.537, 1.0), 0.5)
		poison_tween.tween_property(field_sprite, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	else:
		poison_flash_enabled = false
		field_sprite.self_modulate = Color(1.0, 1.0, 1.0, 1.0)
