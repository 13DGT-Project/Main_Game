## audio_manager.gd
## Autoload: "Audio"
##
## Central place for every sound effect in the game. Nothing here needs an
## audio file to exist — a missing file logs one warning and is skipped, so
## you can drop files in gradually and the game never breaks.
##
## ============================================================================
##  WHERE TO PUT YOUR SOUND FILES
## ============================================================================
##  Create these folders and drop .ogg / .wav files in with these exact names:
##
##    res://Backend/Audio/SFX/ui/
##        click.ogg            button presses, phone taps
##        back.ogg             going back a screen
##        error.ogg            invalid action ("not enough money")
##        open.ogg             opening phone / journal / map
##        close.ogg            closing them
##        notify.ogg           new text message arriving (short, quiet)
##
##    res://Backend/Audio/SFX/player/
##        footstep_01.ogg .. footstep_04.ogg    walking (picked at random)
##        run_01.ogg .. run_04.ogg              sprinting
##        drink.ogg                             water bottle
##
##    res://Backend/Audio/SFX/game/
##        correct.ogg          right answer
##        wrong.ogg            wrong answer
##        scan_beep.ogg        checkout scanner
##        stock_place.ogg      placing an item on a shelf
##        oven_ding.ogg        bakery timer
##        chop.ogg             deli chopping
##        cash.ogg             getting paid
##        exam_start.ogg       sitting down to an exam
##        exam_pass.ogg
##        exam_fail.ogg
##        level_up.ogg         grade milestone
##
##    res://Backend/Audio/AMBIENCE/
##        wind.ogg             outdoors (MainMap)
##        school.ogg           school interior
##        supermarket.ogg      work interior
##        home.ogg             home interior
##
##  .ogg is recommended for anything longer than a second; .wav is fine for
##  short one-shots. Godot imports both automatically.
## ============================================================================
extends Node

const SFX_DIR := "res://Backend/Audio/SFX/"
const AMBIENCE_DIR := "res://Backend/Audio/AMBIENCE/"

## name -> path (relative to SFX_DIR). Add new sounds by adding a line here.
const SFX := {
	"click": "ui/click.ogg",
	"back": "ui/back.ogg",
	"error": "ui/error.ogg",
	"open": "ui/open.ogg",
	"close": "ui/close.ogg",
	"notify": "ui/notify.ogg",

	"drink": "player/drink.ogg",

	"correct": "game/correct.ogg",
	"wrong": "game/wrong.ogg",
	"scan_beep": "game/scan_beep.ogg",
	"stock_place": "game/stock_place.ogg",
	"oven_ding": "game/oven_ding.ogg",
	"chop": "game/chop.ogg",
	"cash": "game/cash.ogg",
	"exam_start": "game/exam_start.ogg",
	"exam_pass": "game/exam_pass.ogg",
	"exam_fail": "game/exam_fail.ogg",
	"level_up": "game/level_up.ogg",
}

## Footsteps are picked at random from these so walking doesn't sound robotic.
const FOOTSTEPS := ["player/footstep_01.ogg", "player/footstep_02.ogg",
					"player/footstep_03.ogg", "player/footstep_04.ogg"]
const RUNSTEPS := ["player/run_01.ogg", "player/run_02.ogg",
				   "player/run_03.ogg", "player/run_04.ogg"]

const AMBIENCE := {
	"outdoors": "wind.ogg",
	"school": "school.ogg",
	"work": "supermarket.ogg",
	"home": "home.ogg",
}

## How many sounds can overlap before the oldest is reused.
const POOL_SIZE := 12

@export var sfx_volume_db: float = 0.0
@export var ambience_volume_db: float = -12.0

var _pool: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _ambience_player: AudioStreamPlayer
var _current_ambience: String = ""

# Paths we've already warned about, so the console isn't spammed every frame.
var _warned: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = "Master"
	_ambience_player.volume_db = ambience_volume_db
	add_child(_ambience_player)


func _load_or_warn(full_path: String) -> AudioStream:
	if not ResourceLoader.exists(full_path):
		if not _warned.has(full_path):
			_warned[full_path] = true
			print("[Audio] no file yet at %s — skipping (this is fine)" % full_path)
		return null
	return load(full_path)


## Play a named effect from the SFX dictionary above.
## Example:  Audio.play("click")
func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not SFX.has(sound_name):
		push_warning("[Audio] unknown sound '%s'" % sound_name)
		return
	_play_path(SFX_DIR + SFX[sound_name], volume_db, pitch)


## Play a random footstep. `running` picks from the sprint set instead.
func play_footstep(running: bool = false) -> void:
	var list: Array = RUNSTEPS if running else FOOTSTEPS
	if list.is_empty():
		return
	# Slight random pitch so repeated steps don't sound identical.
	_play_path(SFX_DIR + list[randi() % list.size()], -4.0, randf_range(0.92, 1.08))


func _play_path(full_path: String, volume_db: float, pitch: float) -> void:
	var stream := _load_or_warn(full_path)
	if stream == null:
		return
	var p: AudioStreamPlayer = _pool[_next_player]
	_next_player = (_next_player + 1) % _pool.size()
	p.stream = stream
	p.volume_db = sfx_volume_db + volume_db
	p.pitch_scale = pitch
	p.play()


## Loops a background ambience track. Safe to call every scene load — it does
## nothing if that ambience is already playing.
## Example:  Audio.play_ambience("school")
func play_ambience(key: String) -> void:
	if key == _current_ambience and _ambience_player.playing:
		return
	if not AMBIENCE.has(key):
		push_warning("[Audio] unknown ambience '%s'" % key)
		return
	var stream := _load_or_warn(AMBIENCE_DIR + AMBIENCE[key])
	if stream == null:
		_ambience_player.stop()
		_current_ambience = ""
		return
	# Make it loop if the import didn't already.
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambience_player.stream = stream
	_ambience_player.volume_db = ambience_volume_db
	_ambience_player.play()
	_current_ambience = key


func stop_ambience() -> void:
	_ambience_player.stop()
	_current_ambience = ""


## Convenience: wire every Button under `root` to click on press. Call it once
## after building a menu and you get UI sound for free.
func attach_click_sounds(root: Node) -> void:
	for child in root.get_children():
		if child is BaseButton and not (child as BaseButton).pressed.is_connected(_on_any_button):
			(child as BaseButton).pressed.connect(_on_any_button)
		if child.get_child_count() > 0:
			attach_click_sounds(child)


func _on_any_button() -> void:
	play("click")
