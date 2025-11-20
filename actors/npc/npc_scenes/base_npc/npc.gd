@tool
##npc.gd
class_name NPC
extends Actor

@onready var sprite_2d = %Sprite2D
@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var audio_stream_player_2d : AudioStreamPlayer2D = %AudioStreamPlayer2D
@onready var audio_listener_2d : AudioListener2D = %AudioListener2D #should be default listener
#Other areas look to see if this overlaps, monitorable
@onready var body_collision_shape_2d : CollisionShape2D = %BodyCollisionShape2D #Collision shape for player
@onready var state_machine: StateMachine = %StateMachine #State Machine reference
@onready var walk : State = %Walk
@onready var walk_area_2d : Area2D = %WalkArea2D
@onready var walk_shape_2d : CollisionShape2D = %WalkShape2D
##Autostart, on timeout checks to see if player is within p_det_area. wait_time = 0.2s
@onready var p_det_timer : Timer = %PDetTimer
##Detects the player
@onready var p_det_area : Area2D = %P_Det_Area
##If player is detected, then this timer determines how long before the NPC's collision shape is turned off.[br]This allows the player to walk through the NPC so they don't get stuck.
@onready var coll_timer : Timer = %CollTimer



@export_category("NPC Data Resource")
##Data Resource for this NPC. Must be set!
@export var npc_data:CharResource = null
@export_category("NPC Toggles")
##NPC will walk around an area (radius determined by walk_range * tile_size).[br] Turning on npc_will_patrol will disable this!
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
##If walk speed is altered, this is what walk speed will be set back to. Default = move_speed
@export var default_move_speed : float = move_speed

##Determines default idle parameters, but usually overwritten by using other states.
@export_category("Idle State AI")
##Minimum normal idle time
@export var idle_min : float = 1.5
##Maximum normal idle time
@export var idle_max : float = 3.5

##If npc_will_walk is true, this section will be used to determine the walk parameters.
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


@export_category("Patrol State AI")
##MUST BE SET IF npc_will_patrol = true![br] Make a normal Node2D in the scene and add PatrolLocation as children.[br] MUST HAVE AT LEAST 2 PatrolLocations for patrol state to work!
@export var patrol_parent : Node2D = null

@export_category("Follow AI")
##The actor this node will attempt to follow in the follow state
@export var actor_to_follow : Actor = null
##If set to true, NPC will attempt to follow actor_to_follow
@export var is_following : bool = false
##Set in follow state script, equal to actor_to_follow.move_speed 
@export var follow_speed : float = 50.0



##Vector2 direction the NPC is facing.
var direction : Vector2 = Vector2.ZERO
##Name of the direction the NPC is facing.
var direction_name : String = "down"
##Was the player found?
var player_detected : bool = false



const DIR_4 : Array = [ Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP ]
const _00_CHAR = preload("uid://prpth3t5akim")

signal player_is_detected ##Signal for if the player is detected
signal player_is_not_detected ##Signal for if the player was not detected
signal pcolldettrue ##Signal to turn off collisions after a certain time.
signal pcolldetfalse ##Signal to turn collisions back on once player exits detection area.
#signal direction_changed( new_direction )




func _ready()->void:
	if Engine.is_editor_hint():
		return
	setup_npc()
	if_walking()
	pass

##Setup routine for NPC
func setup_npc()->void:
	sprite_2d.texture = npc_data.char_sprite_sheet #gets texture from resource
	walk_center = global_position #Sets walk center to NPC global position
	state_machine.initialize(self) #Initializes state_machine script to be the this node
	p_det_timer.timeout.connect(_check_for_player) #Connects timeout signal to _check_for_player()
	collision_toggle()
	coll_timer.wait_time = coll_off_wait_time
	coll_timer.timeout.connect(collisions_disabled)
	pcolldettrue.connect(ptimercolloff)
	pcolldetfalse.connect(ptimercollon)
	
	
	pass
##Determines if walk_area shows up in debug. Sets up walk_area size. Places walk_area at NPC's position but does not move with NPC.[br]
##If a WalkCenterPoint is defined, makes it the walk_center instead of NPC origin position.
func if_walking()->void:
	if free_walk_area == true: #for debugging
		walk_area_2d.queue_free()  #for debugging
	elif free_walk_area == false:  #for debugging
		if walkcenterpoint == null:
			var warea = walk_area_2d  #for debugging
			walk_shape_2d.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))  #for debugging
			remove_child(warea)  #for debugging
			warea.global_position = global_position  #for debugging
			add_sibling.call_deferred(warea)  #for debugging
		elif walkcenterpoint != null:
			var warea = walk_area_2d  #for debugging
			walk_shape_2d.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))  #for debugging
			remove_child(warea)  #for debugging
			warea.global_position = walkcenterpoint.global_position  #for debugging
			add_sibling.call_deferred(warea)  #for debugging
	#If a walkcenterpoint is set in the inspector, it becomes the walk_center for walk state
	#NPC will eventually walk to walk_center.global_position after scene load
	if walkcenterpoint:
		walk_center = walkcenterpoint.global_position
		

		
		pass

func _physics_process(_delta)->void:
	if Engine.is_editor_hint():
		return	
	move_and_slide()

func _process(_delta) -> void:
	if Engine.is_editor_hint():
		if will_walk == true:
			walk_area_2d.visible = true
			walk_shape_2d.shape.size = (Vector2(walk_range*tile_size*2,walk_range*tile_size*2 ))
		elif will_walk == false:
			walk_area_2d.visible = false
		return
	pass

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
	if p_det_area.overlaps_body(CharDataKeeper.controlled_character):
		player_detected = true
		#print("PLAYER DETECTED!")
		player_is_detected.emit()
		if coll_off_with_timer == true:
			pcolldettrue.emit()
	elif !p_det_area.overlaps_body(CharDataKeeper.controlled_character):
		player_detected = false
		#print("PLAYER NOT DETECTED!")
		player_is_not_detected.emit()
		if coll_off_with_timer == true:
			pcolldetfalse.emit()

##Starts coll_timer. coll_timer timeout triggrs collsions_disabled()
func ptimercolloff()->void:
	if coll_timer.is_stopped():
		coll_timer.start()
	pass

##Turns collision shape back on once player exits p_det_area. stops coll_timer.
func ptimercollon()->void:
	if coll_timer.time_left > 0:
		if player_is_not_detected:
			coll_timer.stop()
	body_collision_shape_2d.set_deferred("disabled", false)
	pass

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

func _unhandled_input(_event):
	#if Input.is_action_just_pressed("test1"):
		#if node_to_follow != null:
			#print(str(name) + " is following " + str(node_to_follow.name))
		#else:
			#print(str(name) + "node_to_follow not ready")
	pass

#for player control, may not need
#func set_direction() -> bool:
	#if direction == Vector2.ZERO:
		#return false
#
	#var direction_id : int = int( round( ( direction + cardinal_direction * 0.1 ).angle() / TAU * DIR_4.size() ) )
	#var new_dir = DIR_4 [ direction_id ]
		#
	#if new_dir == cardinal_direction:
		#return false
		#
	#cardinal_direction = new_dir
	#direction_changed.emit( new_dir )
	#
	#return true


#may be superceded by update_direction_name
#func set_anim_direction() -> String:
	#if direction == Vector2.DOWN:
		##print(str(name) + " going down")
		#return "down"
	#elif direction == Vector2.UP:
		##print(str(name) + " going up")
		#return "up"
	#elif direction == Vector2.LEFT:
		##print(str(name) + " going left")		
		#return "left"
	#else:
		##print(str(name) + " going right")		
		#return "right"
##
