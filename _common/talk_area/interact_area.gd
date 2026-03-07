class_name InteractArea
extends Area2D

enum INDICATOR{BORED, CRY, DOTDOTDOT, EXCLAMATION, FRUSTRATION, HAPPY, QUESTION, QUOTES, SLASH, STAR}

###Dialogue resource to be used
@export var dialogue : Resource
##Debug flag. Needs to be off by default.[br]
##Used for turning this area on and off
@export var area_active : bool = false
###Controlled through DialogueManager calling update_times_interacted() in interact_manager[br]
###Possible use for if player needs to interact with this node several times
@export var times_interacted : int = 0
## Indicator to be used, can be set to other images
@export var indicator : INDICATOR = INDICATOR.EXCLAMATION
@export var interacting : bool = false

func _ready()->void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	DM.dialogue_session_ended.connect(_on_dialogue_session_ended)
	CutsceneManager.cutscene_end.connect(_on_cutscene_end)
	set_process_unhandled_input(false)

func _on_area_entered(_area: Area2D) -> void:
	area_active = true

	if _can_show_indicator():
		show_indicator_animation()

	if _can_accept_input():
		set_process_unhandled_input(true)
	else:
		set_process_unhandled_input(false)

func _on_area_exited(_area: Area2D) -> void:
	area_active = false
	set_process_unhandled_input(false)
	hide_indicator_animation()

func _start_dialog()->void:
	set_self_to_global()
	pass

func _on_dialogue_session_ended(_resource : Resource)->void:
	_try_restore_indicator_after_interaction()

func _on_cutscene_end(_cutscene_id : StringName)->void:
	_try_restore_indicator_after_interaction()

func _try_restore_indicator_after_interaction() -> void:
	if not interacting:
		return

	if Interact.interact_node != self:
		return

	if DM.has_active_balloon():
		return

	if CutsceneManager._is_playing:
		return

	interacting = false
	Interact.clear_interact_node()

	if _can_show_indicator():
		show_indicator_animation()

	if _can_accept_input():
		set_process_unhandled_input(true)
	else:
		set_process_unhandled_input(false)

func _can_show_indicator() -> bool:
	if not area_active:
		return false
	if interacting:
		return false
	if DM.has_active_balloon():
		return false
	if CutsceneManager._is_playing:
		return false
	return true

func _can_accept_input() -> bool:
	if not area_active:
		return false
	if interacting:
		return false
	if CutsceneManager._is_playing:
		return false
	return true

func set_self_to_global()->void:
	Interact.interact_node = self

func indicator_string()->String:
	match indicator:
		INDICATOR.BORED:
			return "bored"
		INDICATOR.CRY:
			return "cry"
		INDICATOR.DOTDOTDOT:
			return "dotdotdot"
		INDICATOR.EXCLAMATION:
			return "exclamation"
		INDICATOR.FRUSTRATION:
			return "frustration"
		INDICATOR.HAPPY:
			return "happy"
		INDICATOR.QUESTION:
			return "question"
		INDICATOR.QUOTES:
			return "quotes"
		INDICATOR.SLASH:
			return "slash"
		INDICATOR.STAR:
			return "star"
		_:
			return ""

func show_indicator_animation()->void:
	CharDataKeeper.controlled_character.play_show_interact_animated(indicator_string())

func hide_indicator_animation()->void:
	CharDataKeeper.controlled_character.play_hide_interact_animated(indicator_string())

func _unhandled_input(event: InputEvent) -> void:
	if not area_active:
		return
	if interacting:
		return
	if CutsceneManager._is_playing:
		return

	if event.is_action_pressed("confirm_input"):
		if dialogue == null:
			return

		interacting = true
		set_process_unhandled_input(false)
		CharDataKeeper.controlled_character.play_hide_interact_instant(indicator_string())
		_start_dialog()

## TODO interact animation
## Should be shown when player walks up to it
## Should hide when player walks away
## Should hide if the player is interacting with the area
## Should reappear once the player is done interacting
