##quest_resource.gd
class_name Quest
extends Resource

##Unique quest ID
@export var quest_id: StringName
##Name of the quest
@export var quest_name : String = ""
##Description of the quest.
@export_multiline var description : String = ""

##Quest steps
@export var steps : Array[QuestStep] = []

## Step -1 means the player does not have the quest yet
## Step 0 means the quest has been given and we are on steps[0]
var current_step: int = -1

##Quest completed or not
var is_completed : bool = false
var repeatable : bool = false

func reset()->void:
	current_step = -1
	is_completed = false
	for step in steps:
		if step:
			step.reset()
			
func has_started()->bool:
	return current_step > -1
