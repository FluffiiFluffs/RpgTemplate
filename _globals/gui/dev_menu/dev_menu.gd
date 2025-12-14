##dev_menu.gd
##Global script Dev
extends CanvasLayer
@onready var animation_player = %AnimationPlayer

var dev_menu_open : bool = false

@onready var button_1 = %Button1
@onready var button_2 = %Button2
@onready var button_3 = %Button3
@onready var button_4 = %Button4
@onready var button_5 = %Button5
@onready var button_6 = %Button6
@onready var button_7 = %Button7
@onready var button_8 = %Button8
@onready var button_9 = %Button9
@onready var button_10 = %Button10

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

func on_button_1_pressed()->void:
	SceneManager.make_player_in_scene()

func on_button_2_pressed()->void:
	SceneManager._instantiate_player_for_member(CharDataKeeper.all_party_members[1], Vector2.ZERO)
	
func on_button_3_pressed()->void:
	SceneManager.make_party_in_scene()
	
func on_button_4_pressed()->void:
	pass
	
func on_button_5_pressed()->void:
	pass

func on_button_6_pressed()->void:
	pass
	
func on_button_7_pressed()->void:
	pass
	
func on_button_8_pressed()->void:
	pass
	
func on_button_9_pressed()->void:
	pass

func on_button_10_pressed()->void:
	var main = SceneManager.main_scene
	if main == null:
		printerr("DevMenu: SceneManager.main_scene is null")
		return

	var nodes : Array[Node] = []
	_collect_descendants(main, nodes)

	var spawners : Array[EnemySpawner] = []
	var loose_enemies : Array[Enemy] = []

	for n in nodes:
		if n is EnemySpawner:
			spawners.append(n)
		elif n is Enemy:
			var e : Enemy = n
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
