class_name TopLevelStats
extends Control
##Box used to show Name/Level/HP/MP/Buffs of a party member at a quick glance




##Styleboxflat border color property can be accessed to show party member's unique color
@onready var stats_container : PanelContainer = %StatsContainer
##Text property should be set to the appropriate party member's name from CharDataKeeper
@onready var char_name_label : Label = %CharNameLabel
##Text property should be set to the appropriate party member's level
@onready var lv_num_label : Label = %LVNumLabel
##Styleboxflat border color property can be accessed to show party member's unique color
@onready var hp_panel_container : PanelContainer = %HPPanelContainer
##max_value and value should be set to match the party member's current amounts
@onready var hp_progress_bar : ProgressBar = %HPProgressBar
##Styleboxflat border color property can be accessed to show party member's unique color
@onready var mp_panel_container : PanelContainer = %MPPanelContainer
##max_value and value should be set to match the party member's current amounts
@onready var mp_progress_bar : ProgressBar = %MPProgressBar
##Holds buff/debuff icons
@onready var buff_h_box = %BuffHBox

##Reference to party member in CharDataKeeper
var party_member : CharResource = CharDataKeeper.controlled_character_data
var original_style : StyleBoxFlat = null
var unique_style : StyleBoxFlat = null

const FLASH_COLOR1 : Color = Color(1.0, 0.143, 0.735, 1.0)
const FLASH_COLOR2 : Color = Color(1.0, 0.0, 0.0, 1.0)
const OFF_COLOR : Color = Color(0.0, 0.0, 0.0, 0.0)
const DEAD_COLOR : Color = Color()

func _ready() -> void:
	original_style = stats_container.get("theme_override_styles/panel") as StyleBoxFlat
	if original_style == null:
		push_error("StatsContainer has no panel style override")
		return

	unique_style = original_style.duplicate() as StyleBoxFlat
	stats_container.add_theme_stylebox_override("panel", unique_style)

	# now this only affects this instance
	unique_style.border_color = Color(1.0, 0.2, 0.2, 1.0)
	
func border_color_change(_color : Color) ->void:
	unique_style.border_color = _color
