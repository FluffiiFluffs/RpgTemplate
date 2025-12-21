@tool
class_name BattleStats
extends Control
##battle_stats.gd
##Window showing hp/mp of current party member
@onready var command_container : PanelContainer= %CommandContainer
@onready var stats_panel_container : PanelContainer = %StatsPanelContainer
@onready var selection_button : Button = %SelectionButton
@onready var command_h_box : HBoxContainer = %CommandHBox


@onready var command_container_container : PanelContainer = %CommandContainerContainer

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

##Uses member.class color to set border colors
func set_class_color()->void:
	if member != null:
		stats_panel_container.self_modulate = member.class_color
		command_container.self_modulate = member.class_color

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
