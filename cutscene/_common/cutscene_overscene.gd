class_name CutsceneOverscene
extends CutsceneAction
## CutsceneManager starts the overscene action.
## SceneManager instantiates the overscene under main.over_scene.
## While the overscene is active, field_root is set to PROCESS_MODE_DISABLED.
	## This suspends the field scene branch and prevents normal field gameplay from advancing.
	## Field input, movement, interaction, and cutscene progression remain suspended.
## The overscene runs independently outside the suspended field branch.
## When the overscene emits overscene_completed:
	## CutsceneManager tells SceneManager to free the overscene.
	## field_root process_mode is restored.
	## The original field cutscene continues executing.



## Scenes using this object should emit signal overscene_completed when done



## String path to the scene to be instantiated.
## The instantiated scene root must emit overscene_completed when it is done.
@export_file("*.tscn") var scene_path : String = ""
