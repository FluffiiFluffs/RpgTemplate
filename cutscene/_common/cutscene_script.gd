@tool
class_name CutsceneScript extends Node


# ALL: force CutScene state on every FieldActor in the current FieldScene.
# PLAYER: force CutScene state on the controlled character and any actors referenced by this cutscene's actions.
# NONE: do not force CutScene state and do not switch GameState to CUTSCENE.
enum PENTITIES {ALL, PLAYER, NONE}

@export var cutscene_id : StringName = &""
@export var one_shot : bool = true
@export var has_been_played : bool = false
@export var acts : Array[CutsceneAct] = []
@export var pause_entities : PENTITIES = PENTITIES.ALL

func _process(_delta : float)->void:
	if Engine.is_editor_hint():
		set_cutscene_script_id()
		return
		
		
func set_cutscene_script_id()->void:
	cutscene_id = name
