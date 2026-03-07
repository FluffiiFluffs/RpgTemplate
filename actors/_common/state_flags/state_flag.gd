class_name StateFlag
extends Node
## Persists a boolean flag in SaveManager, keyed by:
##   (FieldScene scene filename basename, attached object node name).
##
## Usage: add this as a child of the node you want to track. After _ready(),
## reading `flag` reflects SaveManager, and setting `flag` updates SaveManager.

signal flag_loaded(value: bool) ## Emitted once after the initial load from SaveManager.

@export var flag: bool = false:
	set(value):
		_set_flag(value)
	get:
		return _flag

var _flag: bool = false

## Key parts used for SaveManager state_flags.
var _field_scene_filename: String = ""
var _attached_object_node_name: String = ""

## Prevents writes to SaveManager before the initial load completes.
var _has_loaded_from_save: bool = false


func _ready() -> void:
	_field_scene_filename = _resolve_field_scene_filename()
	_attached_object_node_name = _resolve_attached_object_name()

	# SaveManager validates empty inputs, so this is safe even if the key is incomplete.
	_flag = SaveManager.has_state_flag(_field_scene_filename, _attached_object_node_name)

	_has_loaded_from_save = true
	flag_loaded.emit(_flag)


func _set_flag(value: bool) -> void:
	if _flag == value:
		return

	_flag = value

	# Do not write back until after the initial load has established the baseline.
	if not _has_loaded_from_save:
		return

	if _flag:
		SaveManager.set_state_flag(_field_scene_filename, _attached_object_node_name)
	else:
		SaveManager.clear_state_flag(_field_scene_filename, _attached_object_node_name)


func _resolve_attached_object_name() -> String:
	# This node is expected to be a child of the object being flagged.
	var parent_node: Node = get_parent()
	if parent_node == null:
		return ""
	return parent_node.name


func _resolve_field_scene_filename() -> String:
	# Walk up the tree to find the containing FieldScene.
	var current_node: Node = self
	while current_node != null:
		if current_node is FieldScene:
			var field_scene: FieldScene = current_node as FieldScene
			var _scene_file_path: String = field_scene.scene_file_path
			return _scene_file_path.get_file().get_basename()
		current_node = current_node.get_parent()

	return ""
