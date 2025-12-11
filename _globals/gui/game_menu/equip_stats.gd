@tool
class_name EquipStats
extends HBoxContainer
##Helper game_menu_ui/equip scene

@onready var equip_stats_title : Label = %EquipStatsTitle
@onready var equip_stats_base : Label = %EquipStatsBase
@onready var equip_plus_minus : Label = %EquipPlusMinus
@onready var equip_stats_mod_value : Label = %EquipStatsModValue

@export var stats_title : String = ""

func _ready()->void:
	equip_stats_title.text = stats_title
	equip_plus_minus.visible = false
	equip_stats_mod_value.visible = false
	if Engine.is_editor_hint():
		equip_plus_minus.visible = true
		equip_stats_mod_value.visible = true
		return
	
##Makes the labels a different color depending on if the modded stats are positive or negative
func set_label_colors()->void:
	if equip_plus_minus.text == "+":
		equip_stats_base.self_modulate = GameMenu.ENABLED_COLOR
		equip_plus_minus.self_modulate = GameMenu.ENABLED_COLOR
		equip_stats_mod_value.self_modulate = GameMenu.ENABLED_COLOR
	else:
		equip_stats_base.self_modulate = GameMenu.DISABLED_COLOR
		equip_plus_minus.self_modulate = GameMenu.DISABLED_COLOR
		equip_stats_mod_value.self_modulate = GameMenu.DISABLED_COLOR

##Resets the label colors to white (after equipment has been selected)
func reset_label_colors()->void:
	equip_stats_base.self_modulate = GameMenu.WHITE_COLOR
	equip_plus_minus.self_modulate = GameMenu.WHITE_COLOR
	equip_stats_mod_value.self_modulate = GameMenu.WHITE_COLOR

##Updates stats_base to a new value
func update_stats_base(value : int)->void:
	equip_stats_base.text = str(value)

func show_difference()->void:
	equip_plus_minus.visible = true
	equip_stats_mod_value.visible = true

func hide_difference()->void:
	equip_plus_minus.visible = false
	equip_stats_mod_value.visible = false

##Sets equip_plus_minus to be +/- depending on true/false
func update_plus_minus(updown : bool)->void:
	if updown == true:
		equip_plus_minus.text = "+"
	else:
		equip_plus_minus.text = "-"

##Updates mod value label to a new value
func update_mod_value(value : int)->void:
	equip_stats_mod_value.text = str(value)
