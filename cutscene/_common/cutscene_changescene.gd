class_name CutsceneChangeScene extends CutsceneAction

## Scene to load.
## This uses SceneManager.load_field_scene(), matching SceneTransitioner behavior.
@export_file("*.tscn") var scene_to_load : String = ""

## Name of the SceneTransitioner node inside the destination scene's TransitionAreas.
## SceneManager will spawn the party at that transitioner.
@export var target_transition_area : String = "SceneTransition"
