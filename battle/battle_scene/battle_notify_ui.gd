class_name BattleNotifyUI
extends Control
##battle_notify_ui.gd
##Controls showing and displaying message during battle


@onready var notify_label : Label = %NotifyLabel
##Timer used for how long a notification should be shown. This is a node within the tree so it can easily be pasued during gameplay (and queue_free'd as well)
@onready var notify_timer : Timer = %NotifyTimer

signal notify_begin
signal notify_end
#signal notify_final_end #superceded by notify_finished signal in battle_scene.gd


var battle_scene : BattleScene = null
var text_coefficient : float = 35.0 #The divisor of a message's text length. A higher value shortens the amount of time text is shown. 
var notify_queue : Array = []
var notifying : bool = false
var _ending_notification : bool = false


func _ready()->void:
	hide()
	notify_end.connect(notify_ended)
	notify_timer.timeout.connect(notify_timeout)
	

func notify_show()->void:
	visible = true
	
func notify_hide()->void:
	visible = false

func notify_ended()->void:
	display_notification()
	## Queues a notification message.
## Optional on_show_actions run after the message becomes visible (deferred to next frame).
func queue_notification(_message: String, on_show_actions : Array[Callable] = [])->void:
	var actions_copy : Array[Callable] = []
	if on_show_actions != null and on_show_actions.size() > 0:
		actions_copy = on_show_actions.duplicate()

	notify_queue.append({
		message = _message,
		on_show_actions = actions_copy
	})
	if notifying:
		return
	display_notification()


## Schedules an action to occur while the current notification is being shown.
## Used by effects that apply damage after the action message has already started.
func queue_on_show_action_for_current(action : Callable) -> void:
	if action == null:
		return
	call_deferred("_run_deferred_callable", action)


func queue_on_show_actions_for_current(actions : Array[Callable]) -> void:
	if actions == null:
		return
	for a in actions:
		if a is Callable:
			queue_on_show_action_for_current(a)


func _run_deferred_callable(action : Callable) -> void:
	if action == null:
		return
	if action.is_valid():
		action.call()


##Displays the next notification in the notify_queue[{}]. Starts notify_timer. Timer length dependent on the message length.
func display_notification()->void:
	if notify_queue.is_empty():
		notify_hide()
		if battle_scene != null:
			battle_scene.notify_finished.emit()
		return

	var _note = notify_queue.pop_front()
	if _note == null:
		return

	battle_scene.ui_state = "NOTIFYING"
	notifying = true
	notify_begin.emit()

	var msg : String = ""
	if _note.has("message"):
		msg = str(_note["message"])

	notify_label.text = msg
	notify_timer.wait_time = float(msg.length() / text_coefficient) + 1.0
	notify_show()
	notify_timer.start()

	if _note.has("on_show_actions"):
		var actions = _note["on_show_actions"]
		if actions is Array:
			for a in actions:
				if a is Callable:
					queue_on_show_action_for_current(a)


##Called automatically when the notify_timer has timed out[br]
##Hides notify window and emits notify_end signal.
func notify_timeout()->void:
	_end_current_notification()


##Shows text (enemy being targeted, item name, skill name, etc)[br]
##Called by various UI elements when focused.[br]
##Stays up indefinitely while the user is making selection, so notify_hide() should be called once the user has made a selection or has cancelled out of the ui state
func show_text(_text : String)->void:
	notify_show()
	notify_label.text = _text

##TODO Skips the message displayed on the screen.
func skip_notify()->void:
	if notifying:
		_end_current_notification()
		return

	if not notify_queue.is_empty():
		display_notification()
		return

	notify_hide()




func _end_current_notification()->void:
	if _ending_notification:
		return
	if not notifying:
		return

	_ending_notification = true

	if notify_timer != null and not notify_timer.is_stopped():
		notify_timer.stop()

	notify_hide()
	notifying = false
	notify_end.emit()

	_ending_notification = false
