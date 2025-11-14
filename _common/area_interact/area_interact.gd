class_name AreaInteract
extends Area2D

signal interacted

var area_is_entered

func _ready()->void:
	area_entered.connect(_area_entered)
	area_exited.connect(_area_exited)	
func _area_entered(_area)->void:
	area_is_entered = true

func _area_exited(_area)->void:
	area_is_entered = false
	
func _unhandled_input(event:InputEvent)->void:
	if area_is_entered == true:
		#if event.is_action_pressed("confirm_input") and not event.is_echo():
		if event.is_action_pressed("confirm_input"):
			interacted.emit()
			print(str(name) + " interacted with")
