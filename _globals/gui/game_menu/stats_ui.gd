class_name StatsUI extends Control



#region stats menu variables
##Overall container for the screen. self-modulates by class color
@onready var stats_panel_container = %StatsPanelContainer
##Character name
@onready var stats_name_label = %StatsNameLabel
##Name of class
@onready var stats_class_label = %StatsClassLabel
@onready var stats_portrait_container : PanelContainer = %StatsPortraitContainer
##Shows portrait of character
@onready var stats_portrait : TextureRect = %StatsPortrait
##Level of character
@onready var stats_level_value : Label = %StatsLevelValue
##Amount of exp needed for next level
@onready var stats_next_lvl_value : Label = %StatsNextLvLValue
##Name of main hand equipment
@onready var stats_main_hand_text : Label = %StatsMainHandText
##Name of off-hand equipment
@onready var stats_off_hand_text : Label = %StatsOffHandText
##Name of head equipment
@onready var stats_head_text : Label = %StatsHeadText
##Name of chest equipment
@onready var stats_chest_text : Label = %StatsChestText
##Name of arms equipemnt
@onready var stats_arms_text = %StatsArmsText
##Name of legs equipment
@onready var stats_legs_text : Label = %StatsLegsText
##name of accy1 equipment
@onready var stats_accy_1_text : Label = %StatsAccy1Text
##Name of acc2 equipment
@onready var stats_accy_2_text : Label = %StatsAccy2Text
##Current HP value
@onready var stats_curr_hp_value : Label = %StatsCurrHPValue
##Max HP value
@onready var stats_max_hp_value : Label = %StatsMaxHPValue
##Current MP value
@onready var stats_curr_sp_value : Label = %StatsCurrSPValue
##Max MP value
@onready var stats_max_sp_value : Label = %StatsMaxSPValue
##ATK value
@onready var stats_atk_value : Label = %StatsATKValue
##DEF Value
@onready var stats_def_value : Label = %StatsDEFValue
##STR value
@onready var stats_str_value : Label = %StatsSTRValue
##STM value
@onready var stats_stm_value : Label = %StatsSTMValue
##SPD value
@onready var stats_spd_value : Label = %StatsSPDValue
##MAG value
@onready var stats_mag_value : Label = %StatsMAGValue
#endregion stats menu variables



func _ready()->void:
	#region initialize positions and visiblility
	visible = true
	stats_panel_container.position = Vector2(0, -224)
	stats_panel_container.visible = false
	#endregion initialize positions and visiblility
pass


#region stats menu
func enter_stats_selection()->void:
	if !GameMenu.top_level.party_h_box_container.get_children().is_empty():
		GameMenu.top_level.stats_button.is_active = true
		GameMenu.last_top_button_focused = GameMenu.top_level.stats_button
		#Focus last/first top level stats button
		GameMenu.top_level.focus_last_top_level_stats()
		GameMenu.menu_state = "STATS_SELECTION"


func setup_stats_menu(_toplevelstats : TopLevelStats)->void:
	if _toplevelstats.party_member == null:
		return
	var _member = _toplevelstats.party_member
	stats_panel_container.self_modulate = _member.class_color
	stats_portrait.texture = _member.stats_sprite
	stats_name_label.text = _member.get_display_name()
	stats_class_label.text = _member.get_actor_class_name()
	stats_level_value.text = str(_member.level)
	
	CharDataKeeper.refresh_next_level_exp_for_member(_member)

	var level_cap : int = 99
	if CharDataKeeper != null:
		level_cap = CharDataKeeper.get_max_level()

	if _member.level >= level_cap:
		stats_next_lvl_value.text = "MAX"
	else:
		var remaining : int = _member.next_level_exp - _member.current_exp
		if remaining < 0:
			remaining = 0
		stats_next_lvl_value.text = str(remaining)
	
	
	if _member.mainhand == null:
		stats_main_hand_text.text = "EMPTY"
	else:
		stats_main_hand_text.text = _member.mainhand.name
		
	if _member.offhand == null:
		stats_off_hand_text.text = "EMPTY"
	else:
		if _member.two_handing == true:
			stats_off_hand_text.text = _member.mainhand.name
		else:
			stats_off_hand_text.text = _member.offhand.name
		
	if _member.headslot == null:
		stats_head_text.text = "EMPTY"
	else:
		stats_head_text.text = _member.headslot.name
		
	if _member.chestslot == null:
		stats_chest_text.text = "EMPTY"
	else:
		stats_chest_text.text = _member.chestslot.name
		
	if _member.armslot == null:
		stats_arms_text.text = "EMPTY"
	else:
		stats_arms_text.text = _member.armslot.name
		
	if _member.legslot == null:
		stats_legs_text.text = "EMPTY"
	else:
		stats_legs_text.text = _member.legslot.name
	
	if _member.accy01 == null:
		stats_accy_1_text.text = "EMPTY"
	else:
		stats_accy_1_text.text = _member.accy01.name
		
	if _member.accy02 == null:
		stats_accy_2_text.text = "EMPTY"
	else:
		stats_accy_2_text.text = _member.accy02.name
	
	stats_curr_hp_value.text = str(_member.current_hp)
	stats_curr_sp_value.text = str(_member.current_sp)
	stats_max_hp_value.text = str(_member.get_max_hp())
	stats_max_sp_value.text = str(_member.get_max_sp())
	stats_atk_value.text = str(_member.get_atk_value())
	stats_def_value.text = str(_member.get_def_value())
	stats_str_value.text = str(_member.get_strength())
	stats_stm_value.text = str(_member.get_stamina())
	stats_spd_value.text = str(_member.get_agility())
	stats_mag_value.text = str(_member.get_magic())


func open_stats_menu()->void:
	#animation_player.play("stats_menu_show")
	stats_menu_show()
	GameMenu.menu_state = "STATS_OPEN"

	pass
func stats_menu_show()->void:
	GameMenu.menu_is_animating = true
	await GameMenu.top_level.top_level_bottom_only()
	stats_panel_container.position = Vector2(0, 0)
	stats_panel_container.visible = true
	var tween = create_tween()
	tween.tween_property(stats_panel_container,"position", Vector2(0,215),0.15)
	await tween.finished
	GameMenu.menu_is_animating = false
	
	pass
	
func stats_menu_hide()->void:
	GameMenu.menu_is_animating = true
	stats_panel_container.position = Vector2(0, 215)
	stats_panel_container.visible = true
	var tween = create_tween()
	tween.tween_property(stats_panel_container,"position", Vector2(0,0),0.15)
	await tween.finished
	await GameMenu.top_level.top_level_bottom_only_return()
	GameMenu.menu_is_animating = false
	
	
	pass
	


func close_stats_menu()->void:
	#animation_player.play("stats_menu_hide")
	stats_menu_hide()
	GameMenu.menu_state = "STATS_SELECTION"
	GameMenu.top_level.focus_last_top_level_stats()
	pass

#endregion stats menu
