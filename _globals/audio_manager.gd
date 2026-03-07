##Global AudioManager
extends Node

@onready var field_music_player_1: AudioStreamPlayer = %FieldMusicPlayer1
@onready var field_music_player_2: AudioStreamPlayer = %FieldMusicPlayer2
@onready var battle_music_player_1: AudioStreamPlayer = %BattleMusicPlayer1
@onready var battle_music_player_2: AudioStreamPlayer = %BattleMusicPlayer2
@onready var sfx_player_1: AudioStreamPlayer = %SFXPlayer1
@onready var sfx_player_2: AudioStreamPlayer = %SFXPlayer2
@onready var sfx_player_3: AudioStreamPlayer = %SFXPlayer3
@onready var sfx_player_4: AudioStreamPlayer = %SFXPlayer4
@onready var sfx_player_6: AudioStreamPlayer = %SFXPlayer6
@onready var sfx_player_7: AudioStreamPlayer = %SFXPlayer7
@onready var sfx_player_8: AudioStreamPlayer = %SFXPlayer8
@onready var voices_player: AudioStreamPlayer = %VoicesPlayer
@onready var ambience_player: AudioStreamPlayer = %AmbiencePlayer
@onready var ui_player_1: AudioStreamPlayer = %UIPlayer1
@onready var ui_player_2: AudioStreamPlayer = %UIPlayer2



#region UI Sounds
const CONFIRM_02 = preload("uid://bjqqoqva5xklq")
const CANCEL_02 = preload("uid://c2kl7on0hjb2")
const ERROR_02 = preload("uid://du2mienip45l8")
const MENUBLIP_02 = preload("uid://c702gfb7w8bpf")
#endregion UI Sounds


#region Battle Sounds
const BATTLETIME_02 = preload("uid://bvlikhv7n0mcd")
#endregion Battle Sounds

#region Misc Sounds
const LEVELUP_02 = preload("uid://cmevudv4hrv7e")
#endregion



#res://_assets/music/field_music/
func play_field_music_by_filename(_filename : String)->void:
	#if music player 1 or 2 is playing music (one should be silent)
		#fade out the music player out that is playing music
		#load the requested file by UID into the unused music player
			#fade in the music
		#unload the audio file by the music player that was playing music first
	pass


#res://_assets/music/battle_music/
func play_battle_music_by_filename(_filename : String)->void:
	
	#if field music is playing, fade out and pause it (don't stop)
	pause_field_music()
	#load from UID the file to be played

func unload_battle_music()->void:
	#fade out battle music
	#unload files from all battle music players (should be called at the end of battle)
	pass
	
func pause_field_music()->void:
	#whichever field music player is playing, fade it out and pause it
	pass

func resume_field_music()->void:
	#whichever field music player has a song loaded (paused), fade in and resume the music
	pass

#maybe need to cache this instead, voices are fast
func play_voice_by_filename(_filename : String)->void:
	#play voice through voicesplayer or should be handled by another audiostreamplayer (probably the one in the bubble since dialogue manager will already have the file loaded)
	pass

func play_ambience_by_filename(_filename : String)->void:
	pass

func play_sfx_by_filename(_filename : String)->void:
	#loop through all music players
	#the first one that is not being used, play the SFX file
	pass
	
func play_ui_confirm()->void:
	if ui_player_1.playing:
		ui_player_2.stream = CONFIRM_02
		ui_player_2.play()
		return
	ui_player_1.stream = CONFIRM_02
	ui_player_1.play()

func play_ui_cancel()->void:
	if ui_player_1.playing:
		ui_player_2.stream = CANCEL_02
		ui_player_2.play()
		return
	ui_player_1.stream = CANCEL_02
	ui_player_1.play()

func play_ui_error()->void:
	if ui_player_1.playing:
		ui_player_2.stream = ERROR_02
		ui_player_2.play()
		return
	ui_player_1.stream = ERROR_02
	ui_player_1.play()

func play_ui_blip()->void:
	if ui_player_1.playing:
		ui_player_2.stream = MENUBLIP_02
		ui_player_2.play()
		return
	ui_player_1.stream = MENUBLIP_02
	ui_player_1.play()
