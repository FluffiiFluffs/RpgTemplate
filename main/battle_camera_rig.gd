class_name BattleCameraRig
extends Node2D
##battle_camera_rig.gd
##Attached to BattleRoot in main.tscn
##Controls the battle camera


@onready var battle_camera : Camera2D = %BattleCamera

var main : Main = null

func _ready()->void:
	main = get_parent().get_parent()

func activate()->void:
	battle_camera.enabled = true
	battle_camera.make_current()

func deactivate()->void:
	battle_camera.enabled = false
