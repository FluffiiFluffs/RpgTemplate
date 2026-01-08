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
	
func queue_notification(_message: String)->void:
	notify_queue.append({message = _message	})
	if notifying:
		return
	display_notification()

##Displays the next notification in the notify_queue[{}]. Starts notify_timer. Timer length dependent on the message length.
func display_notification()->void:
	if notify_queue.is_empty():
		battle_scene.notify_finished.emit()
		return
	var _note = notify_queue.pop_front()
	if _note == null:
		return
	else:
		battle_scene.ui_state = "NOTIFYING"
		notifying = true
		notify_begin.emit()
		notify_label.text = _note.message
		notify_timer.wait_time = float(_note.message.length() / text_coefficient) + 1.0
		#print(str(_note.message.length()))
		#print(str(_note.message.length() / text_coefficient))
		notify_show()
		notify_timer.start()

##Called automatically when the notify_timer has timed out[br]
##Hides notify window and emits notify_end signal.
func notify_timeout()->void:
	notify_hide()
	notifying = false
	notify_end.emit()

		
		
##Shows text (enemy being targeted, item name, skill name, etc)[br]
##Called by various UI elements when focused.[br]
##Stays up indefinitely while the user is making selection, so notify_hide() should be called once the user has made a selection or has cancelled out of the ui state
func show_text(_text : String)->void:
	notify_show()
	notify_label.text = _text
		
