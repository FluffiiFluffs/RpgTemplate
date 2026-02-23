class_name CutsceneActorMove extends CutsceneAction


enum PathType {STRAIGHT_LINE, NAVIGATION, INSTANT}

## Type of movement to use
@export var path_type : PathType = PathType.STRAIGHT_LINE
## ID of the actor to be moved
@export var actor_id : String = ""
## Array holding StringNames that should be the name of each CutsceneMarker to move to (done in order)
@export var move_location_ids : Array[StringName] = []
## Speed of the moves to be made
@export var move_speed : float = 30.0
