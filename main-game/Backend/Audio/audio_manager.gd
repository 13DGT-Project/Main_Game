##    res://Backend/Audio/SFX/ui/
##        click.mp3            button presses, phone taps
##        back.mp3             going back a screen
##        error.mp3            invalid action ("not enough money")
##        open.mp3             opening phone / journal / map
##        close.mp3            closing them
##        notify.mp3           new text message arriving (short, quiet)
##
##    res://Backend/Audio/SFX/player/
##        footstep_01.mp3 .. footstep_04.mp3    walking (picked at random)
##        run_01.mp3 .. run_04.mp3              sprinting
##        drink.mp3                             water bottle
##
##    res://Backend/Audio/SFX/game/
##        correct.mp3          right answer
##        wrong.mp3            wrong answer
##        scan_beep.mp3        checkout scanner
##        stock_place.mp3      placing an item on a shelf
##        oven_ding.mp3        bakery timer
##        chop.mp3             deli chopping
##        cash.mp3             getting paid
##        exam_start.mp3       sitting down to an exam
##        exam_pass.mp3
##        exam_fail.mp3
##        level_up.mp3         grade milestone
##
##    res://Backend/Audio/AMBIENCE/
##        wind.mp3             outdoors (MainMap)
##        school.mp3           school interior
##        supermarket.mp3      work interior
##        home.mp3             home interior
extends Node

const SFX_DIR := "res://Backend/Audio/SFX/"
const AMBIENCE_DIR := "res://Backend/Audio/AMBIENCE/"
const SFX := {
	"click": "ui/click.mp3",
	"back": "ui/back.mp3",
	"error": "ui/error.mp3",
	"open": "ui/open.mp3",
	"close": "ui/close.mp3",
	"notify": "ui/notify.mp3",

	"drink": "player/drink.mp3",

	"correct": "game/correct.mp3",
	"wrong": "game/wrong.mp3",
	"scan_beep": "game/scan_beep.mp3",
	"stock_place": "game/stock_place.mp3",
	"oven_ding": "game/oven_ding.mp3",
	"chop": "game/chop.mp3",
	"cash": "game/cash.mp3",
	"exam_start": "game/exam_start.mp3",
	"exam_pass": "game/exam_pass.mp3",
	"exam_fail": "game/exam_fail.mp3",
	"level_up": "game/level_up.mp3",
}

## Footsteps are picked at random from these so walking doesn't sound the same.
const FOOTSTEPS := ["player/footstep_01.mp3", "player/footstep_02.mp3",
					"player/footstep_03.mp3", "player/footstep_04.mp3"]
const RUNSTEPS := ["player/run_01.mp3", "player/run_02.mp3",
				   "player/run_03.mp3", "player/run_04.mp3"]

const AMBIENCE := {
	"outdoors": "wind.mp3",
	"school": "school.mp3",
	"work": "supermarket.mp3",
	"home": "home.mp3",
}

## How many sounds can overlap before the oldest is reused.
const POOL_SIZE := 12

# =============================================================================
# AUDIO BUSES
# =============================================================================
#   Master
#    ├── Music      music_manager.gd
#    ├── SFX        gameplay — footsteps, scanner, cash, exams
#    ├── Ambience   the looping room tone for each scene
#    └── UI         button clicks, phone taps, notification pings
#
#The Master slider still scales all of them each of the others adjusts only its own category.

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_AMBIENCE := "Ambience"
const BUS_UI := "UI"

## Every bus a settings screen can offer a slider for, in display order.
const MIXER_BUSES := [BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_AMBIENCE, BUS_UI]

## Which sounds belong on the UI bus rather than SFX.
const UI_SOUNDS := ["click", "back", "error", "open", "close", "notify"]

## Volumes persist between runs.
const SETTINGS_PATH := "user://audio_settings.cfg"

@export var sfx_volume_db: float = 0.0
@export var ambience_volume_db: float = -12.0

var _pool: Array[AudioStreamPlayer] = []
var _ui_pool: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _next_ui_player: int = 0
var _ambience_player: AudioStreamPlayer
var _current_ambience: String = ""

# Paths already warned about, so the console isn't spammed
var _warned: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_pool.append(p)

	# A smaller separate pool for UI, so a burst of menu clicks can't push a
	# gameplay sound out of the main pool mid-playback.
	for i in 6:
		var u := AudioStreamPlayer.new()
		u.bus = BUS_UI
		add_child(u)
		_ui_pool.append(u)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.bus = BUS_AMBIENCE
	_ambience_player.volume_db = ambience_volume_db
	add_child(_ambience_player)

	load_volumes()


func _load_or_warn(full_path: String) -> AudioStream:
	if not ResourceLoader.exists(full_path):
		if not _warned.has(full_path):
			_warned[full_path] = true
			print("[Audio] no file yet at %s — skipping (this is fine)" % full_path)
		return null
	return load(full_path)


## Play a named effect from the SFX dictionary above.
func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not SFX.has(sound_name):
		push_warning("[Audio] unknown sound '%s'" % sound_name)
		return
	_play_path(SFX_DIR + SFX[sound_name], volume_db, pitch, sound_name in UI_SOUNDS)


## Play a random footstep. `running` picks from the sprint set instead.
func play_footstep(running: bool = false) -> void:
	var list: Array = RUNSTEPS if running else FOOTSTEPS
	if list.is_empty():
		return
	# Slight random pitch so repeated steps don't sound identical.
	_play_path(SFX_DIR + list[randi() % list.size()], -4.0, randf_range(0.92, 1.08), false)


func _play_path(full_path: String, volume_db: float, pitch: float, on_ui_bus: bool = false) -> void:
	var stream := _load_or_warn(full_path)
	if stream == null:
		return
	var p: AudioStreamPlayer
	if on_ui_bus:
		p = _ui_pool[_next_ui_player]
		_next_ui_player = (_next_ui_player + 1) % _ui_pool.size()
	else:
		p = _pool[_next_player]
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
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
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


# =============================================================================
# MIXER  —  what a settings screen talks to
# =============================================================================
# Sliders should deal in 0..100, not decibels. Decibels are logarithmic, so a
# slider wired straight to volume_db feels wrong: half way along is nowhere
# near half as loud. These convert for you.
#
#   Audio.set_bus_percent("Music", 60.0)
#   Audio.get_bus_percent("Music")          -> 60.0
#
# Anything at 0 is muted outright rather than set to a very small dB value,
# because linear_to_db(0) is -inf and Godot will happily hand you that.


## Human-readable name for a bus, for slider labels.
func bus_label(bus: String) -> String:
	match bus:
		BUS_MASTER:
			return "Master volume"
		BUS_MUSIC:
			return "Music"
		BUS_SFX:
			return "Sound effects"
		BUS_AMBIENCE:
			return "Ambience"
		BUS_UI:
			return "Menus & UI"
	return bus


## 0..100 for a bus. Returns 0 if the bus is muted or missing.
func get_bus_percent(bus: String) -> float:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		return 100.0
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(idx)) * 100.0, 0.0, 100.0)


## Sets a bus from a 0..100 slider and saves it.
func set_bus_percent(bus: String, percent: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		push_warning("[Audio] no bus called '%s' — check default_bus_layout.tres is set in Project Settings > Audio." % bus)
		return
	percent = clampf(percent, 0.0, 100.0)
	# Mute rather than trying to express silence in decibels: linear_to_db(0)
	# is -inf, which Godot accepts and then behaves oddly with.
	if percent <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(percent / 100.0))
	save_volumes()


func save_volumes() -> void:
	var cfg := ConfigFile.new()
	for bus in MIXER_BUSES:
		cfg.set_value("audio", bus, get_bus_percent(bus))
	cfg.save(SETTINGS_PATH)


## Restores saved volumes at startup. Missing file = first run, leave the
## defaults from the bus layout alone.
func load_volumes() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for bus in MIXER_BUSES:
		var idx: int = AudioServer.get_bus_index(bus)
		if idx < 0:
			continue
		var percent: float = float(cfg.get_value("audio", bus, 100.0))
		if percent <= 0.0:
			AudioServer.set_bus_mute(idx, true)
		else:
			AudioServer.set_bus_mute(idx, false)
			AudioServer.set_bus_volume_db(idx, linear_to_db(percent / 100.0))


## Handy for a "reset audio" button.
func reset_volumes() -> void:
	for bus in MIXER_BUSES:
		set_bus_percent(bus, 100.0)
