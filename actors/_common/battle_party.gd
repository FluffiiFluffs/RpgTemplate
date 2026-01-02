class_name BattleParty
extends Node2D
##battle_party.gd
##Used to control the visuals of a party member during battle

@onready var marker_2d : Marker2D = %Marker2D
@onready var battle_sprite : Sprite2D = %BattleSprite
@onready var animation_player : AnimationPlayer = %AnimationPlayer


#a reference to the battler node
var battler : Battler = null


func _ready()->void:
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
	
