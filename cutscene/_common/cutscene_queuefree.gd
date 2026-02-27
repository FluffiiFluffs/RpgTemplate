class_name CutsceneQueueFree extends CutsceneAction
## Used to queue_free() an actor or object during a cutscene
## Maybe should be implemented some other way than ID, possibly by node name


## ID to find to queue_free()
@export var target_id : StringName = &""
