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

var _gamestate : int = State.STARTMENU

var gamestate : int:
	get:
		return _gamestate
	set(value):
		_set_gamestate(value)

func _set_gamestate(value: int) -> void:
	if _gamestate == value:
		return

	var prev : int = _gamestate
	_gamestate = value
	gamestate_changed.emit(prev, _gamestate)

func is_field() -> bool:
	return _gamestate == State.FIELD
