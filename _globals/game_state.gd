##game_state.gd
##global script GameState
extends Node2D
##Keeps track of the game state so elements do not interfere with each other.


@export_enum(
	"STARTMENU0",
	"FIELD1",
	"BATTLE2",
	"GAMEMENU3",
	"INTERACTING4",
	"CUTSCENE5",
	"PAUSEMENU6",
	"TRANSITION7",
	"LOADING8",
	"GAMEOVER9",
	"SHOP10",
	"DIALOGUE11"
)
var gamestate: int = 1
