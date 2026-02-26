class_name CutsceneState
extends State


func enter() -> void:
	actor.velocity = Vector2.ZERO
	actor.on_cutscene_entered()


func exit() -> void:
	actor.velocity = Vector2.ZERO
	actor.on_cutscene_exited()


func process(_delta : float) -> State:
	actor.velocity = Vector2.ZERO
	return null


func physics(_delta : float) -> State:
	actor.velocity = Vector2.ZERO
	return null


func handle_input(_event : InputEvent) -> State:
	return null


func init() -> void:
	pass
