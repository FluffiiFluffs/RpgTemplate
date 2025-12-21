@tool
class_name EnemySpawner
extends Area2D

##Unused. Defunct
@onready var spawn_timer : Timer = %SpawnTimer
##Visual marker for editor
@onready var sprite_2d = %Sprite2D

###How the enemy will be represented on the field.
#@export var enemy_actors:Array[CharResource]
##Possible enemy configurations to pick from when battle happens.
@export var enemy_groups : Array[EnemyGroup] = []
##How hard the enemies will be in battle.
@export var difficulty_modifier : float = 1.0
##Percent chance enemies will spawn from this node
@export_range(1,100,0.5) var enemy_spawn_chance : float = 30.0
##Minimum enemies to spawn in the area
@export_range(1,1000000,1) var min_enemies : int = 1
##Maximum enemies to spawn in the area
@export_range(1, 1000000, 1) var max_enemies : int = 1
##If true, enemies will despawn when a certain distance away from the player (usually off-screen)
@export var despawn_with_distance : bool = true
##How far the player must be to despawn the enemies
@export var despawn_distance : float = 500
##Enemy will only wander inside of the shape it was spawned in (always a single RectangleShape2D)
@export var stays_in_shape : bool = true
##How long to wait before trying to spawn new enemies when below max
@export var count_enemy_wait_time : float = 3.0
##FOR DEBUG![br]Array of collision shapes.[br]! ! ! ! SHAPE CAN ONLY BE A RectangelShape2D ! ! ! !
@export var collision_shapes : Array[CollisionShape2D] = []
##How many enemies remain in the group.
@export var enemies_to_spawn : int = 0
##How many enemies are currently spawned
@export var spawn_count : int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		z_index = 1
		return
	z_index = 0
	sprite_2d.queue_free() #gets rid of the visual marker
	gather_shapes() #appends all shapes to collision_shapes[]
	area_entered.connect(spawn_all) #Spawns enemies when player EnemySpawnTrigger comes in range.
	area_exited.connect(remove_all_enemies) #Removes enemies when player is out of range

func _process(_delta)->void:
	if Engine.is_editor_hint():
		if child_order_changed:
			for child in get_children():
				if get_children().is_empty():
					return
				if child is CollisionShape2D:
					child.debug_color = Color(1.0, 0.0, 0.0, 0.050)
		return	

##Finds all the child shapes of the EnemySpawner node and appends to collision_shapes[]
func gather_shapes()->void:
	if get_children().is_empty():
		printerr(str(name) + " has no collision shapes to spawn enemies!")
		return
	for child in get_children():
		if child is CollisionShape2D:
			child.debug_color = Color(1.0, 0.0, 0.0, 0.050)
			#print(str(child.name) + " global_position " + str(child.global_position))
			collision_shapes.append(child)

##Spawns enemies.[br]Picks random amount up to max_enemies to spawn.[br]Each enemy then has a chance to spawn based upon enemy_spawn_chance.
func spawn_all(_area: Area2D = null) -> void:
	#If no enemy actors, abort!
	if enemy_groups.is_empty():
		push_warning("EnemySpawner has no enemy_groups set!")
		return
	
	#If no collision shapes, abort!	
	if collision_shapes.is_empty():
		push_warning("EnemySpawner has no shapes!")
		return

	
	if spawn_count >= max_enemies:
		print(str(name) + " reached max enemy amount (" + str(max_enemies) + ")")
		return
	else:
		enemies_to_spawn = randi_range(min_enemies, max_enemies)
		print("Attempting to spawn " + str(enemies_to_spawn) + " enemies.")
		for i in range(enemies_to_spawn):
			spawn_enemy()
			
		print("spawn_count " + str(spawn_count))

##Spawns a single enemy, used within spawn_all().
func spawn_enemy()->void:
	if spawn_count >= max_enemies:
		print("max_enemies reached " + str(max_enemies) + "spawn_count: " + (str(spawn_count) ))
		return
		#Rolls random number 1-100
	var random_chance = randf_range(0, 100)
	
	#If random chance is more than the spawn chance, do not spawn enemies.
	if random_chance > enemy_spawn_chance:
		print("Did not spawn enemy. " + str(random_chance) + " > " + str(enemy_spawn_chance))
		return
	else:
		
		#pick a random enemy group
		var eg_index : int = randi_range(0, enemy_groups.size()-1)
		print("eg_index = " + str(eg_index))
		var egroup = enemy_groups[eg_index]
		if enemy_groups.is_empty():
			printerr(str(name) + ": No enemies assigned in enemy_group" + str(eg_index))
		#pick a random enemy from that group to represent the group on the field
		var en_index : int = randi_range(0, egroup.enemies.size()-1)
		#instantiate the field enemy
		var random_actor = egroup.enemies[en_index].instantiate() #egroup will contain packedscenes, so instantiate a new packedscene
		#put the random enemy group into the enemy's enemy_group variable so it can be used to make the enemy formation in battle
		random_actor.enemy_group = egroup
		random_actor.will_walk = true
		random_actor.was_spawned = true
		random_actor.enemy_spawner = self
		random_actor.despawn_with_distance = despawn_with_distance
		random_actor.despawn_distance = despawn_distance
		var rand_shape = collision_shapes[pick_random_shape()]
		random_actor.walk_shape = rand_shape
		random_actor.global_position = _random_point_in_rect(rand_shape)
		if_stays_in_shape(random_actor, rand_shape)
		call_deferred("add_child", random_actor)
		#increase spawn count by 1
		spawn_count += 1
		#print("spawned enemy " + str(spawn_count))
	reset_walk_areas()

##If EnemySpawner's stays_in_shape == true, enemies will be confined to the collision shape they spawned in and not wander out. Otherwise, they will just roam wherever.
func if_stays_in_shape(_enemy:Enemy, _rand_shape:CollisionShape2D)->void:
	if stays_in_shape:
		_enemy.free_walk_area = true
		_enemy.walk_extents_x = _rand_shape.shape.size.x
		_enemy.walk_extents_y = _rand_shape.shape.size.y
		_enemy.walk_center = _rand_shape.global_position

func reset_walk_areas()->void:
	for child in get_children():
		if child is WalkArea:
			var wa : WalkArea = child
			if wa.was_spawned == false:
				continue
			if wa.original_parent == null or is_instance_valid(wa.original_parent) == false:
				continue
			wa.global_position = wa.original_parent.global_position


##Returns a random shape from collision_shapes array. collision_shapes[] is generated by gather_shapes()
func pick_random_shape() -> int: 
	var shapes_amount : int = collision_shapes.size()
	if shapes_amount == 0:
		return -1
	return randi_range(0, shapes_amount -1)

##Finds a random point within the selected shape and returns its Vector2 Value.
func _random_point_in_rect(shape_node:CollisionShape2D)-> Vector2:
	if shape_node.shape is not RectangleShape2D:
		printerr(str(name) + ": SHAPE IS NOT A RECTANGLE! (Spawn location will be weird)")
		return global_position
	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		push_warning(str(name) + " has non rectangle shape in collision_shapes")
		return global_position

	var extents: Vector2 = rect_shape.extents
	var local_pos := Vector2(
		randf_range(-extents.x, extents.x),
		randf_range(-extents.y, extents.y)
	)

	return shape_node.to_global(local_pos-global_position)
	

###Replaces an enemy.[br]Maximum amount will only be up to the originally determined enemies_to_spawn that was generated during spawn_all() (not max_enemies).
#func replace_enemy()->void:
	#if spawn_count == enemies_to_spawn:
		#print(str(name) + " cannot spawn more enemies. Max enemies for this round present " + str(spawn_count))
		#return
	#elif spawn_count > enemies_to_spawn:
		#print("Too many enemies! Removing enemy!")
		#remove_random_enemy()
		#print("spawn_count = " + str(spawn_count) + " enemies_to_spawn = " + str(enemies_to_spawn))
		#return
	#elif spawn_count < enemies_to_spawn:
		#var random_actor: CharResource = enemy_actors[randi_range(0, enemy_actors.size()-1)]
		#var enemy = CharDataKeeper.ENEMY.instantiate() as Enemy
		#var walkarea = enemy.walk_area_2d
		#enemy.enemy_data = random_actor
		#enemy.name = random_actor.char_name
		#enemy.was_spawned = true
		#enemy.will_walk = true
		#enemy.enemy_spawner = self
		#var rand_shape = collision_shapes[pick_random_shape()]
		#enemy.global_position = _random_point_in_rect(rand_shape)
		#call_deferred("add_child", enemy)
		#walkarea.global_position = enemy.global_position
		#spawn_count += 1
		#print("spawned enemy " + str(spawn_count))


##Removes all children enemies from the EnemySpawner if they cannot see the player.
func remove_all_enemies(_area:Area2D = null)->void:
	for child in get_children():
		if child is Enemy:
			if !child.see_player: #has_seen_player not necessary here
				child.queue_free() 
				spawn_count -= 1
				print("Removed enemy, enemy_count: " + str(spawn_count))
	if get_children().is_empty(): #if no children...
		spawn_count = 0 #for safety



##Removes children enemies no matter what
func _remove_all_enemies(_area:Area2D = null)->void:
	for child in get_children():
		if child is Enemy:
			child.queue_free() 
			spawn_count -= 1
			print("Removed enemy, enemy_count: " + str(spawn_count))


###If true, enemies will be replaced after defeat. (on-screen)
#@export var replace_enemies : bool = false
###If true, enemies will be replaced when area is off-screen.
#@export var replace_off_screen : bool = false
###

##TODO (unimplemented)
##Picks a random BattleGroup for the enemy actor (field) to represent
func random_group()->void:
	var _rand_group : int = randi_range(0, enemy_groups.size()-1)
	#assign group to enemy_actor group variable

func remove_random_enemy()->void:
	for child in get_children():
		if child is Enemy:
			#if enemies_to_spawn > max_enemies:
			child.queue_free()
			spawn_count -= 1
			break
##Subtracts enemy from enemy_amount
func enemy_killed():
	spawn_count -= clampi(1,0,max_enemies)

#func _unhandled_input(_event):
	#if Input.is_action_just_pressed("test3"):
		#print(str(name) + " spawn_all()")
		#spawn_all()
#
	#if Input.is_action_just_pressed("test5"):
		#print(str(name) + "remove_all_enemies()")
		#remove_all_enemies()
		#
###This should be called from the enemy actually, so defunct!
#func enemy_was_killed(_enemy : Enemy)->void:
	#_enemy.queue_free()	
	#spawn_count -= 1
