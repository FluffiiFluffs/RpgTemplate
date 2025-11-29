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
