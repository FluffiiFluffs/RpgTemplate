class_name BattleEnemy
extends Control
##script attached to battle enemy's scene
##only really controls visuals of the the enemy.
@onready var marker_2d : Marker2D = %Marker2D
@onready var battle_sprite : Sprite2D = %BattleSprite
@onready var button : Button = %Button
@onready var battle_scene_container: PanelContainer = %BattleSceneContainer

@onready var animation_player : AnimationPlayer = %AnimationPlayer

#a reference to the battler node
var battler : Battler = null

var battle_scene : BattleScene = null

func _ready()->void:
	button.pressed.connect(button_pressed)
	button.focus_entered.connect(focused)
	button.focus_exited.connect(unfocused)
	pass

func play_normal_hit()->void:
	animation_player.play("normal_hit")

func play_critical_hit()->void:
	animation_player.play("critical_hit")
	
func play_normal_attack()->void:
	animation_player.play("normal_attack")

func play_critical_attack()->void:
	animation_player.play("critical_attack")
	
func play_spell_cast()->void:
	animation_player.play("spell_cast")

func play_death()->void:
	animation_player.play("death")
	
##Grabs button focus
func grab_button_focus()->void:
	button.grab_focus()

func focused()->void:
	if battle_scene != null and battle_scene.command_controller != null:
		battle_scene.command_controller.on_battler_focus_changed(battler)
	animation_player.play("focused")


func unfocused()->void:
	if battle_scene != null and battle_scene.command_controller != null:
		if battle_scene.command_controller.is_all_targeting_active():
			return
	animation_player.play("unfocused")


##passes battler through as the one selected by the user while targeting
func button_pressed()->void:
	battle_scene.command_controller.on_enemy_pressed(battler)
	pass
	
func activate_button()->void:
	button.disabled = false

func deactivate_button()->void:
	button.disabled = true
