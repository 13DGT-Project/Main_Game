extends Node

var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	var music = load("res://Backend/Resource/Scores/Decision Point - Year 13 - Intro v2.mp3")
	music_player.stream = music
	music_player.play()

func stop_music():
	if music_player:
		music_player.stop()

func play_music():
	if music_player and not music_player.playing:
		music_player.play()

func pause_music():
	music_player.stream_paused = true

func resume_music():
	music_player.stream_paused = false
