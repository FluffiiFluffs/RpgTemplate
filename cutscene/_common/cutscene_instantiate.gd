class_name CutsceneInstantiate extends CutsceneAction
## Instantiates a PackedScene during a cutscene.
## Each marker id spawns one instance.

## Actor = field actor, Object = non actor object, VFX = visual effect auto play scene
enum TYPE {ACTOR, OBJECT, VFX}

## Type of scene to be instantiated
@export var type : TYPE = TYPE.ACTOR
## Scene to be instantiated
@export var instantiated_scene : PackedScene = null
## Marker ids to instantiate to, in order.
@export var instantiate_location_ids : Array[StringName] = []
## If an ID field exists (field_actor_id or object_id), what to set that ID to.
@export var target_id : StringName = &""
