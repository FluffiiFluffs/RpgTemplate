class_name EnemySpawner
extends Area2D

const ENEMY = preload("uid://dt3hw6ocf2cl7")

@onready var spawn_timer : Timer = %SpawnTimer

##How the enemy will be represented on the field.
@export var enemy_actors:Array[CharResource]
##Possible enemy configurations to pick from when battle happens.
@export var enemy_groups : Array[EnemyGroup] = []
##How hard the enemies will be in battle.
@export var difficulty_modifier : float = 1.0
##Percent chance enemies will spawn from this node
@export_range(1,100,0.5) var enemy_spawn_chance : float = 30.0
##Minimum enemies to spawn in the area
@export_range(1,20,1) var min_enemies : int = 1
##Maximum enemies to spawn in the area
@export_range(1, 20, 1) var max_enemies : int = 1
##If true, enemies will be replaced after defeat. (on-screen)
@export var replace_enemies : bool = false
##If true, enemies will be replaced when area is off-screen.
@export var replace_off_screen : bool = false
##If enemy is confined to the area.
@export var enemy_stays_in_area : bool = false
##How long to wait before trying to spawn new enemies when below max
@export var count_enemy_wait_time : float = 3.0
##FOR DEBUG![br]Array of collision shapes.[br]! ! ! ! SHAPE CAN ONLY BE A RectangelShape2D ! ! ! !
@export var collision_shapes : Array[CollisionShape2D] = []
##How many enemies remain in the group.
@export var enemy_amount : int = 0


func _ready() -> void:
	randomize()
	#just gets rid of the timer if replace_enemies is false
	if replace_enemies == false:
		spawn_timer.queue_free()
	else:
		spawn_timer.timeout.connect(replace_enemy)
		spawn_timer.wait_time = count_enemy_wait_time
	gather_shapes()


func spawn_all() -> void:
	if enemy_actors.is_empty():
		push_warning("EnemySpawner has no enemy_actors set")
		return
	var random_chance = randf_range(0, 100)
	if random_chance <= enemy_spawn_chance:
		enemy_amount = randi_range(min_enemies, max_enemies)
		for i in enemy_amount:
			if enemy_amount == max_enemies:
				print(str(name) + " reached max enemy amount (" + str(max_enemies) + ")")
				return
			if enemy_amount < max_enemies:
				var random_actor = enemy_actors[randi_range(0, enemy_actors.size()-1)]
				var enemy = ENEMY.instantiate()
				enemy.enemy_data = random_actor
				enemy.was_spawned = true
				enemy.enemy_spawner = self
				enemy.will_walk = true
				var rand_shape = collision_shapes[pick_random_shape()]
				enemy.global_position = _random_point_in_rect(rand_shape.shape)
				await get_tree().process_frame
				add_child(enemy)
				enemy_amount += clampi(1,0,max_enemies)
				#random_group() ##TODO

##TODO
func random_group()->void:
	var rand_group : int = randi_range(0, enemy_groups.size()-1)
	#assign group to enemy_actor group variable

##Replaces enemy when timer completes if less than max enemies
func replace_enemy()->void:
	if replace_enemies == true:
		if replace_off_screen == false:
			if enemy_amount == max_enemies:
				print("SpawnTimer cannot spawn more enemies. Max enemies present")
				return
			if enemy_amount < max_enemies:
				var random_chance = randf_range(0,100)
				if random_chance < enemy_spawn_chance:
					var random_actor : CharResource = enemy_actors[randi_range(0, enemy_actors.size()-1)]
					var enemy :Enemy= random_actor.instantiate()
					enemy.enemy_data = random_actor
					enemy.was_spawned = true
					var rand_shape = collision_shapes[pick_random_shape()]
					enemy.walk_extents_x = rand_shape.extents.x
					enemy.walk_extents_y = rand_shape.extents.y
					enemy.global_position = _random_point_in_rect(rand_shape)
					add_child(enemy)
					enemy.enemy_spawner = self
					enemy_amount += clampi(1,0,max_enemies)

##Subtracts enemy from enemy_amount
func enemy_killed():
	enemy_amount -= clampi(1,0,max_enemies)

##Finds all the child shapes of the EnemySpawner node
func gather_shapes()->void:
	if get_children().is_empty():
		printerr(str(name) + " has no collision shapes to spawn enemies!")
		return
	for child in get_children():
		if child is CollisionShape2D:
			collision_shapes.append(child)

##Picks a random shape to spawn the enemy
func pick_random_shape()->int:
	if collision_shapes.size() == 0:
		return -1
	var shapes_amount : int = collision_shapes.size()
	var shape_index : int = randi_range(0, shapes_amount-1)
	return shape_index

###Finds a random point in the randomly selected shape
#func get_random_point_in_area(rect_shape:RectangleShape2D) -> Vector2:
		#if rect_shape is RectangleShape2D:
			#return _random_point_in_rect(rect_shape)
		#else:
			## Fallback: spawn at spawner position
			#return global_position

func _random_point_in_rect(rect_shape: RectangleShape2D) -> Vector2:
	var extents: Vector2 = rect_shape.extents
	var local_pos := Vector2(
		randf_range(-extents.x, extents.x),
		randf_range(-extents.y, extents.y)
	)
	return global_position * local_pos

func _unhandled_input(_event):
	if Input.is_action_just_pressed("test3"):
		spawn_all()
