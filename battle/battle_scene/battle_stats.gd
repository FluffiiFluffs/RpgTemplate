@tool
class_name BattleStats
extends Control
##battle_stats.gd
##Window showing hp/mp of current party member
@onready var command_container : PanelContainer= %CommandContainer
@onready var stats_panel_container : PanelContainer = %StatsPanelContainer
@onready var selection_button : Button = %SelectionButton
@onready var command_h_box : HBoxContainer = %CommandHBox
@onready var hp_value : Label = %HPValue
@onready var hp_progress_bar := %HPProgressBar
@onready var mp_value : Label = %MPValue
@onready var mp_progress_bar = %MPProgressBar
@onready var command_flasher : PanelContainer = %CommandFlasher
@onready var command_container_container : PanelContainer = %CommandContainerContainer
@onready var battle_scene_container : PanelContainer = %BattleSceneContainer

#toggles command container visibility
@export var show_commands : bool = false : set = set_show_commands

#Party member to be represented by the window
var member : PartyMemberData = null

func _ready() -> void:
	_apply_show_commands()

	if Engine.is_editor_hint():
		return
	show_commands = false #for runtime
	_apply_show_commands()
	command_flasher.visible = true

#region Setup
##Uses member.class color to set border colors
func set_class_color()->void:
	if member != null:
		stats_panel_container.self_modulate = member.class_color
		command_container.self_modulate = member.class_color

func setup_hpmp()->void:
	hp_value.text = str(member.current_hp)
	mp_value.text = str(member.current_mp)
	hp_progress_bar.max_value = member.get_max_hp()
	mp_progress_bar.max_value = member.get_max_mp()
	hp_progress_bar.value = member.current_hp
	mp_progress_bar.value = member.current_mp
	if_hp_mp_full_or_empty()
	
	
#endregion Setup

#region Update Stats
##Makes HP/MP value a different color if they are full
func if_hp_mp_full_or_empty()->void:
	if member.current_hp == member.get_max_hp():
		hp_value.self_modulate = GameMenu.ENABLED_COLOR
	else:
		hp_value.self_modulate = GameMenu.WHITE_COLOR
	if member.current_mp == member.get_max_mp():
		mp_value.self_modulate = GameMenu.ENABLED_COLOR
	else:
		mp_value.self_modulate = GameMenu.WHITE_COLOR
	if member.current_hp == 0:
		hp_value.self_modulate = GameMenu.MINUS_COLOR
	if member.current_mp == 0:
		mp_value.self_modulate = GameMenu.MINUS_COLOR

##Updates label to new HP value and animates the bar to show it.[br] Damage = -value, Heal = +value
func hp_changed(value : int)->void:
	var old_hp := member.current_hp
	var new_hp := clampi(old_hp + value, 0, member.get_max_hp())
	hp_value.text = str(new_hp)
	var tween := Tween.new()
	tween.tween_property(hp_progress_bar, "value", new_hp, 0.3)
	await tween.finished
	if_hp_mp_full_or_empty()
	
##Updates label to new MP value and animates the bar to show it.[br] Damage = -value, Heal = +value
func mp_changed(value : int)->void:
	var old_mp := member.current_mp
	var new_mp := clampi(old_mp + value, 0, member.get_max_mp())
	mp_value.text = str(new_mp)
	var tween := Tween.new()
	tween.tween_property(mp_progress_bar, "value", new_mp, 0.3)
	await tween.finished
	if_hp_mp_full_or_empty()
	


#endregion Update Stats

#region Graphical Scene

##Gets rid of editor placeholder and instantiates battle scene
func update_battle_scene()->void:
	if member.battle_scene != null and member != null:
		for child in battle_scene_container.get_children():
			child.queue_free()
		await get_tree().process_frame
		var new_battle_scene = member.battle_scene.instantiate()
		battle_scene_container.add_child(new_battle_scene)
	else:
		if member == null:
			printerr("NO PARTY MEMBER DATA!!")
		else:
			if member.battle_scene == null:
				printerr(str(member.char_resource.char_name) + " HAS NO BATTLE SCENE SET!")

#region Selection
##Activates selection_button so it can be selected with normal UI
func activate_button()->void:
	selection_button.disabled = false
##Deactivates selection_button so it cannot be selected with normal UI
func deactivate_button()->void:
	selection_button.disabled = true

#Grabs selection_button focus
func grab_button_focus()->void:
	selection_button.grab_focus()

##Enables all command buttons so they can be selected by the normal UI functions
func activate_all_command_buttons()->void:
	for child in command_h_box.get_children():
		if child is CommandButton:
			child.activate_button()

##Disables all command buttons so they cannot be selected by the normal UI functions
func deactivate_all_command_buttons()->void:
	for child in command_h_box.get_children():
		if child is CommandButton:
			child.deactivate_button()
#endregion Selection


#region Command Container
## for us in editor
func set_show_commands(value: bool) -> void:
	show_commands = value
	_apply_show_commands()
## for use in editor
func _apply_show_commands() -> void:
	var container := _get_command_container()
	if container == null:
		return
	container.visible = show_commands

##For editor use
func _get_command_container() -> PanelContainer:
	# Setter can run before @onready has executed (especially in the editor).
	# Prefer the cached reference if it exists, otherwise resolve it on demand.
	if command_container_container != null:
		return command_container_container

	if not is_inside_tree():
		return null

	var n := get_node_or_null(^"%CommandContainerContainer")
	if n == null:
		return null

	command_container_container = n as PanelContainer
	return command_container_container

##Shows command container (runtime)
func show_command_container_container()->void:
	command_container_container.visible = true

##Hides command container (runtime)
func hide_command_container_container()->void:
	command_container_container.visible = false


#endregion Command Container
