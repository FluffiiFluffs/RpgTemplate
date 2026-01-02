class_name BattleTurnUI
extends Control
##battle_turn_ui.gd
##Controls the visuals of whose battle turn it is

@onready var battle_turn_v_box : VBoxContainer = %BattleTurnVBox

##Reference to battle_scene
var battle_scene : BattleScene = null

const TURN_ORDER_BOX = preload("uid://dn1a3xdymyc2j")


func _ready()->void:
	battle_scene = get_parent().get_parent()

##clears turn order UI box
##Instantiates new turn_order_box (in order) from battle_scene.turn_order[]
func update_turn_order_ui()->void:
	#clears the turn order UI box so it can be freshly updated
	for child in battle_turn_v_box.get_children():
		child.queue_free()
	var index = -1
	for bat in battle_scene.turn_order:
		index += 1
		if index < 7:
			var new_turn_order_box : TurnOrderBox = TURN_ORDER_BOX.instantiate()
			battle_turn_v_box.add_child(new_turn_order_box)
			if bat.battler_icon != null:
				new_turn_order_box.texture_rect.texture = bat.battler_icon
			if index == 0:
				new_turn_order_box.is_active = true
