extends Node

var music_player: AudioStreamPlayer
var current_track: String = ""

# Add your audio files at these paths and everything below just starts working —
# nothing else needs to change. Until then, missing tracks are skipped with a
# warning instead of crashing.
const TRACKS := {
	"menu": "res://Backend/Resource/Scores/Decision Point - Year 13 - Intro v2.mp3",
	"main_game": "res://Backend/Audio/main_game_theme.ogg",   # TODO: your gameplay background music
	"good_ending": "res://Backend/Audio/good_ending.ogg",     # TODO: your good-ending track
	"bad_ending": "res://Backend/Audio/bad_ending.ogg",       # TODO: your bad-ending track
}


func _ready():
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	play_track("menu")


## Switches to a named track (see TRACKS above). Safe to call repeatedly —
## does nothing if that track is already playing, and just warns (rather than
## crashing) if the file hasn't been added yet.
func play_track(track_key: String) -> void:
	if not TRACKS.has(track_key):
		push_warning("MusicManager: unknown track '%s'" % track_key)
		return
	if track_key == current_track and music_player.playing:
		return

	var path: String = TRACKS[track_key]
	if not ResourceLoader.exists(path):
		push_warning("MusicManager: '%s' track not found yet at %s — add the audio file there." % [track_key, path])
		# Stop whatever WAS playing rather than leaving an unrelated track
		# running (e.g. menu music bleeding into gameplay because
		# "main_game" hasn't been added yet).
		music_player.stop()
		current_track = ""
		return

	music_player.stream = load(path)
	music_player.play()
	current_track = track_key


func stop_music():
	if music_player:
		music_player.stop()
	current_track = ""

func play_music():
	if music_player and not music_player.playing:
		music_player.play()

func pause_music():
	music_player.stream_paused = true

func resume_music():
	music_player.stream_paused = false
