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
	for child in get_tree().current_scene.get_children():
		if child is Enemy:
			child.queue_free()
		elif child is EnemySpawner:
			child._remove_all_enemies()
