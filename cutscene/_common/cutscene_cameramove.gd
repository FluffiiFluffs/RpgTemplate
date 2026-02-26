class_name CutsceneCameraMove extends CutsceneAction

enum PathType {STRAIGHT_LINE, NAVIGATION, INSTANT}

## Type of movement to use
@export var path_type : PathType = PathType.STRAIGHT_LINE

## Which camera rig to move. For now this should be "FieldCameraRig" (node name in Main.tscn)
@export var camera_rig_id : StringName = &"FieldCameraRig"

## The transition type of the tween.
@export var transition_type : Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR

## Ease type used by the tween.
@export var easing_method : Tween.EaseType = Tween.EaseType.EASE_IN_OUT

## Marker ids to move to, in order.
@export var move_location_ids : Array[StringName] = []

## Movement speed in pixels per second (same unit concept as CutsceneActorMove.move_speed).
@export var move_speed : float = 30.0

## Camera follow is controlled via CutsceneCameraFollow.
