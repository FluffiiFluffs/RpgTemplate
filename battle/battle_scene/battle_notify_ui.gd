class_name BattleNotifyUI
extends Control
##battle_notify_ui.gd
##Controls showing and displaying message during battle
@onready var notify_label : Label = %NotifyLabel

signal notify_begin
signal notify_end

var notify_time : float = 1.0
var notify_queue : Array = []
var notifying : bool = false

func _ready()->void:
	hide()
	notify_end.connect(notify_ended)

func notify_show()->void:
	visible = true
	
func notify_hide()->void:
	visible = false

func notify_ended()->void:
	display_notification()
	
func queue_notification(_message: String)->void:
	add_notification_to_queue(_message)

func add_notification_to_queue(_message:String)->void:
	notify_queue.append({message = _message	})
	if notifying == true:
		return
	display_notification()
	
func display_notification()->void:
	if notify_queue.is_empty():
		notifying = false
		notify_hide()
		return
	var _note = notify_queue.pop_front()
	if _note == null:
		return
	notify_label.text = _note.message
	notify_time = float(_note.message.length() / 35.0) + 1.0
	print(str(_note.message.length()))
	print(str(_note.message.length() / 35.0))
	notify_show()
	await get_tree().create_timer(notify_time).timeout
	notify_hide()
	notifying = false
	notify_end.emit()
