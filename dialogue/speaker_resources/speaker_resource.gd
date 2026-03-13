class_name SpeakerResource
extends Resource
## Defines the name, portraits, and voices to be used within the dialogue system 

enum GENDER {HE, SHE, THEY, IT}

@export_category("Identification")
## ID of the speaker to be matched within the dialogue system
@export var speaker_id : String = ""
## Name displayed during talking within the dialogue system
@export var display_name : String = ""
## What pronoun set to use for this speaker.
## Called in dialogue manager with do pronoun(speaker_id, pronoun_type).
## Pronoun type: subject, object, possissive determiner, possesseive pronoun, reflexive.
@export var pronoun : GENDER = GENDER.HE

@export_category("Voice")
## Voice sound for the speaker
@export var voice : AudioStream
## Should always be equal to or lower than pitch_min
@export var pitch_min : float = 0.0
## Should always equal to or higher than pitch_min
@export var pitch_max : float = 0.0

@export_category("Portrait")
## Portrait texture for angry emotion (close mouth)
@export var angry_close : Texture2D
## Portrait texture for angry emotion (open mouth)
@export var angry_open : Texture2D

## Portrait texture for happy emotion (close mouth)
@export var happy_close : Texture2D
## Portrait texture for happy emotion (open mouth)
@export var happy_open : Texture2D

## Portrait texture for normal emotion (close mouth)
@export var normal_close : Texture2D
## Portrait texture for normal emotion (open mouth)
@export var normal_open : Texture2D

## Portrait texture for sad emotion (open mouth)
@export var sad_close : Texture2D
## Portrait texture for sad emotion (close mouth)
@export var sad_open : Texture2D

## Portrait texture for special emotion (close mouth)
@export var special_close : Texture2D
## Portrait texture for special emotion (open mouth)
@export var special_open : Texture2D

## Portrait texture for surprised emotion (close mouth)
@export var surprise_close: Texture2D
## Portrait texture for surprised emotion (open mouth)
@export var surprise_open : Texture2D

## Portrait texture for tired emotion (close mouth)
@export var tired_close : Texture2D
## Portrait texture for tired emotion (open mouth)
@export var tired_open : Texture2D
