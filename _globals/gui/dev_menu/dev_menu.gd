extends CanvasLayer
##Global script Dev
##dev_menu.gd
##Developer menu. Does various things to make development easier.


@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var button_1 : Button = %Button1
@onready var button_2 : Button = %Button2
@onready var button_3 : Button = %Button3
@onready var button_4 : Button = %Button4
@onready var button_5 : Button = %Button5
@onready var button_6 : Button = %Button6
@onready var button_7 : Button = %Button7
@onready var button_8 : Button = %Button8
@onready var button_9 : Button = %Button9
@onready var button_10 : Button = %Button10

var dev_menu_open : bool = false


func _ready()->void:
	button_1.pressed.connect(on_button_1_pressed)
	button_2.pressed.connect(on_button_2_pressed)
	button_3.pressed.connect(on_button_3_pressed)
	button_4.pressed.connect(on_button_4_pressed)
	button_5.pressed.connect(on_button_5_pressed)
	button_6.pressed.connect(on_button_6_pressed)
	button_7.pressed.connect(on_button_7_pressed)
	button_8.pressed.connect(on_button_8_pressed)
	button_9.pressed.connect(on_button_9_pressed)
	button_10.pressed.connect(on_button_10_pressed)


func _unhandled_input(_event):
	if Input.is_action_just_pressed("dev_menu"):
		if animation_player.is_playing():
			return
		if !dev_menu_open:
			animation_player.play("dev_menu_open")
			dev_menu_open = true
		else:
			animation_player.play("dev_menu_close")	
			dev_menu_open = false

##load test scene + spawn party (must be set in chardatakeeper)
func on_button_1_pressed()->void:
	if SceneManager.main_scene != null:
		#instantiate scene to main

		var main = SceneManager.main_scene as Main
		
		for child in main.field_scene_container.get_children():
			child.queue_free()
		var test_scene = load("uid://my8hd4okxhcq").instantiate()
		main.field_scene_container.add_child(test_scene)
		main.field_root.visible = true
		var field_scene = null
		for child in main.field_scene_container.get_children():
			if child is FieldScene:
				field_scene = child
		SceneManager.main_scene.current_field_scene = field_scene
		#setup spawn point
		var spawnp = null
		for child in SceneManager.main_scene.current_field_scene.player_spawn.get_children():
			if child is SceneTransitioner:
				if child.target_transition_area == &"":
					spawnp = child
				else:
					continue
		SceneManager.party_spawn_point = spawnp
		SceneManager.spawn_offset = SceneManager.party_spawn_point.compute_spawn_offset(SceneManager.party_spawn_point.global_position)
		GameState._set_gamestate(1)
		SceneManager.make_party_at_spawn_point(spawnp)
		main.field_camera_rig.follow_player()
		for child in CharDataKeeper.party_members:
			child.current_hp = child.get_max_hp()
	pass


func on_button_2_pressed()->void:
	pass

func on_button_3_pressed()->void:
	pass

func on_button_4_pressed() -> void:
	pass

func on_button_5_pressed() -> void:
	pass
func on_button_6_pressed()->void:
	pass
	
func on_button_7_pressed()->void:
	pass

##Give everyone poison
func on_button_8_pressed()->void:
	if CharDataKeeper.party_members == null:
		return
	if CharDataKeeper.party_members.is_empty():
		return

	var ss : StatusSystem = CharDataKeeper.field_status_system
	if ss == null:
		return

	for member in CharDataKeeper.party_members:
		if member == null:
			continue

		if member.status_effects == null:
			member.status_effects = []

		var dummy : Battler = Battler.new()
		dummy.actor_data = member

		var snapshot : Array = member.status_effects.duplicate()
		for s in snapshot:
			if s == null:
				continue
			if s.exclusive_group_id == &"poison" or s is StatusEffectPoison:
				ss.remove_status(dummy, s)

		var new_poison : StatusVeryWeakPoison = StatusVeryWeakPoison.new()
		ss.try_add_status(dummy, new_poison, null)

		var fscene : FieldPartyMember = CharDataKeeper.get_runtime_party_field_scene(member)
		if fscene != null:
			fscene.set_poison_flash(true)

func on_button_9_pressed()->void:
	if SceneManager.main_scene.current_battle_scene != null:
		var _not_ui = SceneManager.main_scene.current_battle_scene.battle_notify_ui
		_not_ui.queue_notification("THIS IS A TEST MESSAGE.")
		_not_ui.queue_notification("THIS IS ANOTHER TEST MESSAGE.")
		_not_ui.queue_notification("THIS TEST MESSSAGE IS THE THIRD TEST MESSAGE")
		pass

func on_button_10_pressed()->void:
	var main = SceneManager.main_scene
	if main == null:
		printerr("DevMenu: SceneManager.main_scene is null")
		return

	var nodes : Array[Node] = []
	_collect_descendants(main, nodes)

	var spawners : Array[EnemySpawner] = []
	var loose_enemies : Array[FieldEnemy] = []

	for n in nodes:
		if n is EnemySpawner:
			spawners.append(n)
		elif n is FieldEnemy:
			var e : FieldEnemy = n
			if e.enemy_spawner != null and is_instance_valid(e.enemy_spawner):
				continue
			loose_enemies.append(e)

	for s in spawners:
		s._remove_all_enemies()

	for e in loose_enemies:
		e.queue_free()

func _collect_descendants(root: Node, out: Array[Node]) -> void:
	if root == null:
		return
	for child in root.get_children():
		out.append(child)
		_collect_descendants(child, out)


func _get_field_from_main(main: Node) -> Node:
	if main == null:
		return null

	# Preferred: Main’s tracked field scene
	if "current_field_scene" in main:
		var tracked = main.current_field_scene
		if tracked != null and is_instance_valid(tracked):
			return tracked

	# Fallback: last child in FieldSceneContainer (covers “scene is visible but Main didn’t assign it yet”)
	if "field_scene_container" in main and main.field_scene_container != null:
		var c: Node = main.field_scene_container
		var count = c.get_child_count()
		if count > 0:
			var candidate = c.get_child(count - 1)
			if candidate != null and is_instance_valid(candidate):
				return candidate

	return null


func _await_node_ready_if_needed(n: Node) -> void:
	if n == null:
		return
	# Prevent “await ready” hangs if it is already ready
	if n.is_node_ready() == false:
		await n.ready
