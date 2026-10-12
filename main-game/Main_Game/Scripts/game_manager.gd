extends Node

@onready var gui = $"../GUI"
@onready var time_of_day = $"../Sky3D/TimeOfDay"
@onready var player = $"../Player"

const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const MINIMAP_3D_SCRIPT := preload("res://Main_Game/Scripts/minimap_3d.gd")




const MONTHS = [
	"",
	"Jan","Feb","Mar","Apr","May","Jun",
	"Jul","Aug","Sep","Oct","Nov","Dec"
]

func _ready():
	Audio.play_ambience("outdoors")
	time_of_day.minute_changed.connect(_update_clock)
	time_of_day.day_changed.connect(_update_clock)

	# MainMap's TimeOfDay node is destroyed and recreated (with its saved
	# DEFAULT start time!) every time you leave and re-enter MainMap, so we
	# can't just add pending_hours on top of it — that adds onto a reset
	# clock, not onto where the player actually was. Restore the real state
	# from GameBackend's snapshot first, THEN apply the hours that passed
	# while away (via += so TimeOfDay's own hour/day/month rollover logic
	# handles the wraparound correctly).
	# How fast the clock runs. Kept on GameBackend so the 90-day year is
	# tuned in one place rather than in a scene file the editor keeps
	# overwriting.
	time_of_day.minutes_per_day = GameBackend.MINUTES_PER_DAY

	if GameBackend.has_time_snapshot:
		time_of_day.year = GameBackend.saved_year
		time_of_day.month = GameBackend.saved_month
		time_of_day.day = GameBackend.saved_day
		time_of_day.current_time = GameBackend.saved_current_time
	else:
		time_of_day.current_time = GameBackend.DAY_START_HOUR
		GameBackend.game_hour = GameBackend.DAY_START_HOUR

	if GameBackend.pending_hours > 0.0:
		time_of_day.current_time += GameBackend.pending_hours
		GameBackend.pending_hours = 0.0

	if GameBackend.has_return_position:
		player.global_position = GameBackend.return_position
		GameBackend.has_return_position = false

	# Passive drain + day countdown for time passing naturally while walking
	# around MainMap (not already covered by a study/work/social action).
	# Connected AFTER the restore above so that catch-up jump doesn't
	# double-count decay/days that complete_study_session() etc. already
	# applied when it actually happened.
	time_of_day.hour_changed.connect(_on_hour_passed)
	time_of_day.day_changed.connect(_on_day_passed)

	# Only seed the opening texts once, at the very start of a run — not
	# every time you walk back into MainMap.
	if GameBackend.get_elapsed_days() <= 0:
		MessageData.deliver_starting_threads()
	GameBackend.game_ended.connect(_on_game_ended)
	MusicManager.play_track("main_game")
	# current_scene is still running its own _ready() at this point, so it is
	# "busy setting up children" and a direct add_child() is rejected.
	# Deferring puts both of these in on the next idle frame.
	get_tree().current_scene.add_child.call_deferred(JOURNAL_SCENE.instantiate())
	_setup_schematic_minimap()

	_update_clock()


func _on_hour_passed(_hour) -> void:
	GameBackend.apply_passive_decay(1.0)
	# Messages trickle in over the year rather than all being there at once.
	MessageData.maybe_deliver_random()


func _on_day_passed(_day) -> void:
	GameBackend.advance_day()


func _on_game_ended(_result: String) -> void:
	get_tree().change_scene_to_file("res://Main_Game/Scenes/EndingScene.tscn")

const USE_SCHEMATIC_MINIMAP: bool = true


func _setup_schematic_minimap() -> void:
	if not USE_SCHEMATIC_MINIMAP:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	# The scene's own minimap wins. Always.
	if scene.get_node_or_null("MinimapViewport") != null:
		return
	var minimap3d := CanvasLayer.new()
	minimap3d.set_script(MINIMAP_3D_SCRIPT)
	scene.add_child.call_deferred(minimap3d)


func _update_clock(_value = null):

	gui.update_time(time_of_day.game_time.substr(0,5))

	var weekday = get_weekday(
		time_of_day.day,
		time_of_day.month,
		time_of_day.year
	)

	gui.update_date(tr("DATE_FORMAT").format({
		"wd": tr("DAY_SHORT_" + weekday.substr(0, 3).to_upper()),
		"d": time_of_day.day,
		"m": tr("MONTH_SHORT_%d" % time_of_day.month),
	}))

	GameBackend.sync_from_clock(time_of_day.current_time, time_of_day.day, time_of_day.month, time_of_day.year)


func get_weekday(day:int, month:int, year:int)->String:

	var weekdays = [
		"Sunday",
		"Monday",
		"Tuesday",
		"Wednesday",
		"Thursday",
		"Friday",
		"Saturday"
	]

	var t = [0,3,2,5,0,3,5,1,4,6,2,4]

	if month < 3:
		year -= 1

	# Sakamoto's algorithm. The divisions here are MEANT to truncate — they're
	# counting whole leap years — so they're written as explicit integer
	# division to say so, rather than tripping the INTEGER_DIVISION warning.
	@warning_ignore("integer_division")
	var weekday: int = (
		year
		+ int(year / 4)
		- int(year / 100)
		+ int(year / 400)
		+ t[month - 1]
		+ day
	) % 7

	return weekdays[int(weekday)]
