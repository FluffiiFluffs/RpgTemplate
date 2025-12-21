@tool
class_name Enemy
extends Actor
##Enemy.gd
##Attached to Enemy scene on the root node.

@onready var field_sprite = %FieldSprite
@onready var battle_sprite = %BattleSprite
@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var audio_stream_player_2d : AudioStreamPlayer2D = %AudioStreamPlayer2D
#Other areas look to see if this overlaps, monitorable
@onready var body_collision_shape_2d : CollisionShape2D = %BodyCollisionShape2D #Collision shape for player
@onready var state_machine: StateMachine = %StateMachine #State Machine reference
@onready var walk : State = %Walk
@onready var walk_area_2d : Area2D = %WalkArea2D
@onready var walk_shape_2d : CollisionShape2D = %WalkShape2D
##Autostart, on timeout checks to see if player is within p_det_area. wait_time = 0.2s
@onready var detect_timer : Timer = %DetectTimer
##Detects the player
@onready var caution_area_2d : Area2D = %CautionArea2D
@onready var alert_area_2d : Area2D = %AlertArea2D
@onready var see_area_2d : Area2D = %SeeArea2D
@onready var see_shape : CollisionShape2D = %SeeShape2D
@onready var caution_shape : CollisionShape2D = %CautionShape2D
@onready var alert_shape : CollisionShape2D = %AlertShape2D
@onready var state_label : Label = %StateLabel


##If player is detected, then this timer determines how long before the NPC's collision shape is turned off.[br]This allows the player to walk through the NPC so they don't get stuck.
@onready var coll_timer : Timer = %CollTimer

@export_category("Enemy Data Resource")
##Data Resource for this NPC. Must be set!
@export var enemy_data:EnemyData = null

@export_category("Enemy Options")
##NPC will walk around an area (radius determined by walk_range * tile_size).[br] Turning on will_patrol will disable this!
@export var will_walk : bool = false
##NPC patrols area.[br] Locations to walk to will be determined by PatrolLocation nodes.
@export var will_patrol : bool = false
##Enables collisions for this NPC. Default true.
@export var collisions_on : bool = true
##If true, collisions will disable after coll_off_wait_time elapses
@export var coll_off_with_timer : bool = false
##If coll_off_with_timer true, how long until collision disables when player is detected. Default 4.0s
@export var coll_off_wait_time : float = 4.0
##How fast to walk. Default 30.0
@export var move_speed : float = 30.0
##If walk speed is altered, this is what walk speed will be set back to default = move_speed
@export var default_move_speed : float = move_speed

@export_category("Battle Options")
@export var loot_table : Array[LootDrop]
@export var steal_table : Array[LootDrop]
@export var money : int = 0
@export var experience : int = 0
@export var difficulty : float = 1.0

@export_category("Alert Options")
##How an enemy will react to the player's presence.[br]Scared: Enemy will run when in alert range[br]Cautious: Enemy will chase when in alert range[br]Aggressive: Enemy will chase when in caution range
@export_enum("SCARED", "CAUTIOUS", "AGGRESSIVE") var alert_type : int = 1
##How far the enemy sees the player (but does not go into a mode, used for despawn if spawned).
@export var see_range : float = 300.0
##Radius to trigger caution state. Set by setup_detection_ranges on load
@export var caution_range : float = 250.0
##Radius to trigger alert state. Set by setup_detection_ranges on load
@export var alert_range : float = 100.0
##How quickly the enemy moves while in alert status
@export var alert_move_speed : float = 120.0

@export_category("Spawned by Spawner Options")
##For Debugging.[br]Bool for if this enemy was spawned by an EnemySpawner node
@export var was_spawned : bool = false
##For Debugging.[br]Reference to the enemy_spawner.[br]Set by the spawner when enemy is instantiated
@export var enemy_spawner : EnemySpawner = null
##If true, this enemy will despawn when the player is a certain distance from the enemy.[br]Usually set by the EnemySpawner parent node
@export var despawn_with_distance : bool = false
##How far the player must be to despawn the enemy if despawn_with_distance = true.[br]Usually set by the EnemySpawner parent node
@export var despawn_distance : float = 500
@export var enemy_group : EnemyGroup = null

##Determines default idle parameters, but usually overwritten by using other states.
@export_category("Idle State AI")
##Minimum normal idle time
@export var idle_min : float = 1.5
##Maximum normal idle time
@export var idle_max : float = 3.5 

##If will_walk is true, this section will be used to determine the walk parameters.
@export_category("Walk State AI")
##How far to walk from walk_center, multiplied by tile size.
@export var walk_range : float = 3
##Walk Center Point if needed. If none, global position of actor is used.
@export var walkcenterpoint:WalkCenterPoint=null
##Tile size for this project. Default 16x16
@export var tile_size : float = 16
##Minimum time to walk (seconds).
@export var walk_min : float = 0.75
##Maximum time to walk (seconds).
@export var walk_max : float = 1.25
##Original position in the scene. Set when the scene loads this script. Default is actor position.[br] Can be altered using a WalkCenterPoint node and setting that in the inspector.
var walk_center : Vector2 = Vector2.ZERO
##How long to walk, random between min and max. New value set each time this state is entered.
var walk_duration : float = 1.0
##For debugging! True will queue_free() the pink square showing where this NPC will wander.
@export var free_walk_area : bool = true
##For debugging! Defines shape.x the enemy will walk in
@export var walk_extents_x : float = 0.0
##For debugging! Defines shape.y the enemy will walk in.
@export var walk_extents_y : float = 0.0
##For debugging! Stores the collision shape this node spawned from.
@export var walk_shape : CollisionShape2D = null

@export_category("Patrol State AI")
##MUST BE SET IF will_patrol = true![br] Make a normal Node2D in the scene and add PatrolLocation as children.[br] MUST HAVE AT LEAST 2 PatrolLocations for patrol state to work!
@export var patrol_parent : Node2D = null

@export_category("Follow AI")
##The actor this node will attempt to follow in the follow state
@export var actor_to_follow : Actor = null
##If set to true, Enemy will attempt to follow actor_to_follow
@export var is_following : bool = false


@export_category("Alert DEBUG")
##If the enemy can see the player
@export var see_player : bool = false
##If the enemy has seen the player. Used for despawning.
@export var has_seen_player: bool = false
##If the enemy has chased the player
@export var has_chased_player : bool = false
##If the enemy is chasing the player
@export var chasing_player : bool = false
##If enemy is in caution mode
@export var caution_mode : bool = false
##If enemy is in alert mode
@export var alert_mode : bool = false
##If the enemy is in battle or on the field
@export var battle_mode : bool = false
@export var is_defeated : bool = false #maybe useful for playing an animation on the field once an enemy is dead

##Vector2 direction the NPC is facing.
var direction : Vector2 = Vector2.ZERO
##Name of the direction the NPC is facing.
var direction_name : String = "down"
##Was the player found?
#var player_detected : bool = false #Don't need, alert state bools cover this

const DIR_4 : Array = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]

signal cautioning
signal alerting
#signal direction_changed( new_direction )

func _ready()->void:
	see_shape.shape.radius = see_range
	caution_shape.shape.radius = caution_range
	alert_shape.shape.radius = alert_range
	
	if Engine.is_editor_hint():
		return
	setup_enemy()
	if_walking()
	tree_exited.connect(wareafree)
	if !Options.show_states:
		state_label.visible = false

##Setup routine for NPC
func setup_enemy()->void:
	if enemy_data == null:
		printerr("enemy_data is not set! Removing enemy ")
		queue_free()
		return

	#move_speed = enemy_data.move_speed
	walk_area_2d.original_parent = self
	walk_area_2d.was_spawned = was_spawned
	walk_center = global_position #Sets walk center to NPC global position
	state_machine.initialize(self) #Initializes state_machine script to be the this node
	detect_timer.timeout.connect(_check_for_player) #Connects timeout signal to _check_for_player()
	#setup_detection_ranges()
	collision_toggle()
	coll_timer.wait_time = coll_off_wait_time
	coll_timer.timeout.connect(collisions_disabled)
	if battle_mode == true:
		field_sprite.visible = false
		battle_sprite.visible = true
	else:
		field_sprite.visible = true
		battle_sprite.visible = false

func _process(_delta) -> void:
	if Engine.is_editor_hint():
		if walk_area_2d:
			if will_walk == true:
				walk_area_2d.visible = true
				walk_shape_2d.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))
			elif will_walk == false:
				walk_area_2d.visible = false
				
		see_shape.shape.radius = see_range
		caution_shape.shape.radius = caution_range
		alert_shape.shape.radius = alert_range
		return
	pass

##Determines if walk_area shows up in debug. Sets up walk_area size. Places walk_area at NPC's position but does not move with NPC.[br]
##If a WalkCenterPoint is defined, makes it the walk_center instead of NPC origin position.
func if_walking()->void:
	if free_walk_area == true: #for debugging
		walk_area_2d.queue_free()  #for debugging
	elif free_walk_area == false:  #for debugging
		if walkcenterpoint == null:
			walk_shape_2d.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))  #for debugging
			remove_child(walk_area_2d)  #for debugging
			walk_area_2d.global_position = global_position  #for debugging
			add_sibling.call_deferred(walk_area_2d)  #for debugging
		elif walkcenterpoint != null:
			walk_shape_2d.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))  #for debugging
			remove_child(walk_area_2d)  #for debugging
			walk_area_2d.global_position = walkcenterpoint.global_position  #for debugging
			add_sibling.call_deferred(walk_area_2d)  #for debugging
	#If a walkcenterpoint is set in the inspector, it becomes the walk_center for walk state
	#NPC will eventually walk to walk_center.global_position after scene load
	if walkcenterpoint:
		walk_center = walkcenterpoint.global_position
		pass

func _physics_process(_delta)->void:
	if Engine.is_editor_hint():
		return	
	move_and_slide()

##Updates animation. Needs state's (String) name as argument.
##Make sure to update_direction_name() before this is called!
func update_animation(state : String) -> void:
	animation_player.play( state + "_" + direction_name)

##Plays a specific animation. _direction is optional.
func play_animation(_name:String, _direction:String="down"):
	if _direction:
		animation_player.play("_name" + "_" + "_direction")
	else:
		animation_player.play("_name")

##Updates direction name, uses threshold of 0.45
func update_direction_name()->String:	
	var threshold : float = 0.65
	if direction.y < -threshold:
		direction_name = "up"
		return "up"
	elif direction.y > threshold:
		direction_name = "down"
		return "down"
	elif direction.x > threshold:
		direction_name = "right"
		return "right"
	elif direction.x < -threshold:
		direction_name = "left"
		return "left"
	else:
		printerr(str(name) + " NO DIRECTION FOUND")
		return "ERROR"

##Updates direction. Uses target as argument.
func update_direction(_target_position:Vector2)->void:
	direction = global_position.direction_to(_target_position)

##Allows the center point of walk routine to be set after scene load (cutscene possibly)
func set_walk_center_point(_wcp:WalkCenterPoint)->void:
	walk.walkcenterpoint = _wcp.global_position

##Checks to see if the player is wtihin p_det_area. Fires signals and toggles bool.
func _check_for_player()->void:
	if CharDataKeeper.controlled_character != null:
		var sees = see_area_2d.overlaps_body(CharDataKeeper.controlled_character)
		var alerted = alert_area_2d.overlaps_body(CharDataKeeper.controlled_character)
		var cautioned = caution_area_2d.overlaps_body(CharDataKeeper.controlled_character)
		#player is within alert AND caution radius...
		if alerted:
			alert_mode = true
			alerting.emit()
		elif !alerted:
			alert_mode = false

		if cautioned:
			caution_mode = true
			cautioning.emit()
		elif !cautioned:
			caution_mode = false

		#Determines if player is seen at all
		if sees:
			see_player = true #used to determine if the enemy is actively seeing the player
			has_seen_player = true #used to despawn enemy during idle state after the spawner despawns all other nodes
		elif !sees:
			see_player = false

##Turns body collision shape on or off determined by collisions_on toggle in inspector
func collision_toggle()->void:
	if collisions_on == true:
		collisions_enabled()
	else:
		collisions_disabled()

##Turns NPC collisions off
func collisions_disabled()->void:
	#body_collision_shape_2d.disabled = true
	body_collision_shape_2d.set_deferred("disabled", true)
	pass
##Turns NPC collisions on
func collisions_enabled()->void:
	body_collision_shape_2d.set_deferred("disabled", false)
	pass

func wareafree():
	if walk_area_2d:
		walk_area_2d.queue_free()
		
func touched_player()->void:
	
	
	pass


func enemy_killed()->void:
	if was_spawned:
		enemy_spawner.spawn_count -= 1
	queue_free()
	pass
