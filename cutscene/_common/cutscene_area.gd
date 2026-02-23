@tool
class_name CutsceneArea extends Area2D
## Area2D that triggers a cutscene when the controlled character enters it
## This scene is meant to be instantiated within another

const PINK_COLOR := Color(0.786, 0.0, 0.455, 0.1)

@export var one_shot : bool = true
@export var has_played : bool = false
##Which cutscene to trigger within the scene, found by ID
@export var cutscene_id : StringName = &""

func _ready()->void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)


func _process(_delta : float)->void:
	for child in get_children():
		if child is CollisionShape2D:
			if child.shape != null:
				child.debug_color = PINK_COLOR
	if Engine.is_editor_hint():
		return

func on_body_entered(body : FieldPartyMember)->void:
	#Makes sure nothing happens if it's been played
	if one_shot:
		if has_played:
			return

	# Only the controlled character triggers cutscenes.
	if body != CharDataKeeper.controlled_character:
		return

	has_played = true
	CutsceneManager.play_cutscene(cutscene_id)
	print(str(name) + " AREA ENTERED")


func on_body_exited(_body : FieldPartyMember)->void:
	pass
