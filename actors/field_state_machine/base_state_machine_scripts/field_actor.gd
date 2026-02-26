class_name FieldActor
extends CharacterBody2D

@export var field_actor_id : StringName = &""


## Cutscene hooks.
## These exist so the shared CutsceneState can suppress per actor input and movement sources
## without depending on actor subtypes.
func on_cutscene_entered() -> void:
	pass


func on_cutscene_exited() -> void:
	pass
	
	
## Used by CutsceneManager and other systems to force a 4 directional facing.
## Default is a no op so subclasses can opt in.
func force_face_direction(_new_facing : Vector2) -> void:
	pass
