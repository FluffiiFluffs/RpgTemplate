@tool
class_name BattleStats
extends Control
##battle_stats.gd
##Window showing hp/mp of current party member

@onready var command_container : PanelContainer = %CommandContainer

#toggles command container visibility
@export var show_commands : bool = false : set = set_show_commands

#Party member to be represented by the window
var member : PartyMemberData = null


func _ready() -> void:
	_apply_show_commands()

	if Engine.is_editor_hint():
		return

	set_class_color()


func set_class_color()->void:
	pass



#region Command Container
func set_show_commands(value: bool) -> void:
	show_commands = value
	_apply_show_commands()

func _apply_show_commands() -> void:
	var container := _get_command_container()
	if container == null:
		return
	container.visible = show_commands


func _get_command_container() -> PanelContainer:
	# Setter can run before @onready has executed (especially in the editor).
	# Prefer the cached reference if it exists, otherwise resolve it on demand.
	if command_container != null:
		return command_container

	if not is_inside_tree():
		return null

	var n := get_node_or_null(^"CommandContainer")
	if n == null:
		return null

	command_container = n as PanelContainer
	return command_container
#endregion Command Container
