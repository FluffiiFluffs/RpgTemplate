## game_state.gd
## Global script GameState
extends Node

signal gamestate_changed(previous: int, current: int)

enum State {
	STARTMENU,
	FIELD,
	BATTLE,
	GAMEMENU,
	INTERACTING,
	CUTSCENE,
	PAUSEMENU,
	TRANSITION,
	LOADING,
	GAMEOVER,
	SHOP,
	DIALOGUE
}

var gamestate: int = State.STARTMENU:
	set(value):
		_set_gamestate(value)

func _set_gamestate(value: int) -> void:
	if gamestate == value:
		return
	var prev = gamestate
	gamestate = value
	gamestate_changed.emit(prev, gamestate)

func is_field() -> bool:
	return gamestate == State.FIELD
