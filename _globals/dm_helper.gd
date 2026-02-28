## global script "DM", dm_helper.gd
extends Node
## Contains additional functionalty data and functions for dialogue manager plugin

const SND_TXTBER = preload("uid://dr3xptfehm82e")

## An array of all speakers within the game. Propagated upon game load
var all_speakers : Array[SpeakerResource] = []

## The default voice to be used if no voice file is set for a speaker resource
var default_voice : AudioStream = SND_TXTBER


## The current speaker
var current_speaker : SpeakerResource = null
var current_speaker_portrait_open : Texture2D = null
var current_speaker_portrait_close : Texture2D = null





## This is probably going to be defunct soon
func set_portrait(speaker:String, expression: String)->void:
	DialogueManager._set_portrait(speaker, expression)


func find_speaker_by_id(id : String)->SpeakerResource:
	for speaker in all_speakers:
		if id == speaker.speaker_id:
			return speaker
	return null
	
func get_speaker_mood_open():
	pass
	
func get_speaker_mood_closed():
	pass

func get_speaker_voice():
	pass
	
func get_speaker_voice_pitch_min():
	pass
	
func get_speaker_voice_pitch_max():
	pass
	
func get_pronoun_by_id():
	pass
	
func get_pronoun_type():
	pass
	
