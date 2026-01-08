class_name BattleEnemy
extends Control
##script attached to battle enemy's scene
##only really controls visuals of the the enemy.
@onready var marker_2d : Marker2D = %Marker2D
@onready var battle_sprite : Sprite2D = %BattleSprite
@onready var button : Button = %Button

@onready var animation_player : AnimationPlayer = %AnimationPlayer

#a reference to the battler node
var battler : Battler = null

var battle_scene : BattleScene = null

func _ready()->void:
	button.pressed.connect(button_selected)
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

##plays focused animation higher intensity for battlesprite (+0.5)
func focused()->void:
	animation_player.play("focused")
	
##Plays unfocused animation normal intensity for battlesprite (0.0)
func unfocused()->void:
	animation_player.play("unfocused")

##passes battler through as the one selected by the user while targeting
func button_selected()->void:
	battle_scene.command_controller.on_enemy_pressed(battler)
	pass
	
func activate_button()->void:
	button.disabled = false

func deactivate_button()->void:
	button.disabled = true
