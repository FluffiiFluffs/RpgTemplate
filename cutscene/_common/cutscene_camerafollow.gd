class_name CutsceneCameraFollow extends CutsceneAction

enum PathType {STRAIGHT_LINE, NAVIGATION, INSTANT}

@export var camera_rig_id : StringName = &"FieldCameraRig"

@export var follow_controlled_character : bool = false
@export var actor_id : StringName = &""

@export var do_transition_to_target : bool = true
@export var path_type : PathType = PathType.STRAIGHT_LINE
@export var transition_type : Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR
@export var easing_method : Tween.EaseType = Tween.EaseType.EASE_IN_OUT
@export var move_speed : float = 200.0

@export var snap_on_follow_start : bool = false

@export var override_follow_settings : bool = false
@export var follow_speed : float = 0.0
@export var snap : bool = false

@export var persist_follow_settings : bool = false
