class_name StateFlagTest extends Node2D


const WHITE = Color(1.0, 1.0, 1.0, 1.0)
const RED = Color(1.0, 0.0, 0.0, 1.0)
@onready var state_flag: StateFlag = %StateFlag


@onready var area_2d: Area2D = %Area2D
@onready var flag_indicator: Sprite2D = %FlagIndicator
@onready var step_plate: Sprite2D = %StepPlate


func _ready()->void:
	area_2d.body_entered.connect(on_body_entered)
	if state_flag.flag:
		flag_indicator.modulate = RED
	else:
		flag_indicator.modulate = WHITE

func on_body_entered( body : FieldPartyMember)->void:
	if body == CharDataKeeper.controlled_character:
		if state_flag.flag == false:
			flag_indicator.modulate = RED
			state_flag.flag = true
