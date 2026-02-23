@tool
class_name CutsceneScript extends Node


@export var cutscene_id : StringName = &""
@export var one_shot : bool = true
@export var has_been_played : bool = false
@export var acts : Array[CutsceneAct] = []


func _process(_delta : float)->void:
	if Engine.is_editor_hint():
		set_cutscene_script_id()
		return
		
		
func set_cutscene_script_id()->void:
	cutscene_id = name
