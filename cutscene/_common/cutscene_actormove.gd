class_name CutsceneActorMove extends CutsceneAction


enum PathType {STRAIGHT_LINE, NAVIGATION, INSTANT}

## Type of movement to use
@export var path_type : PathType = PathType.STRAIGHT_LINE

## When true, move the currently controlled character (ignores actor_id).
@export var move_controlled_character : bool = false

## ID of the actor to be moved (ignored when move_controlled_character is true)
@export var actor_id : String = ""

## Array holding StringNames that should be the name of each CutsceneMarker to move to (done in order)
@export var move_location_ids : Array[StringName] = []

## Speed of the moves to be made
@export var move_speed : float = 30.0
