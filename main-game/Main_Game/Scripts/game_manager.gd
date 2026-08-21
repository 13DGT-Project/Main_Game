extends Node

@onready var gui = $"../GUI"
@onready var time_of_day = $"../Sky3D/TimeOfDay"
@onready var player = $"../Player"

const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")




const MONTHS = [
	"",
	"Jan","Feb","Mar","Apr","May","Jun",
	"Jul","Aug","Sep","Oct","Nov","Dec"
]

func _ready():
	time_of_day.minute_changed.connect(_update_clock)
	time_of_day.day_changed.connect(_update_clock)
	time_of_day.hour_changed.connect(_hour_changed)

	# MainMap's TimeOfDay node is destroyed and recreated (with its saved
	# DEFAULT start time!) every time you leave and re-enter MainMap, so we
	# can't just add pending_hours on top of it — that adds onto a reset
	# clock, not onto where the player actually was. Restore the real state
	# from GameBackend's snapshot first, THEN apply the hours that passed
	# while away (via += so TimeOfDay's own hour/day/month rollover logic
	# handles the wraparound correctly).
	if GameBackend.has_time_snapshot:
		time_of_day.year = GameBackend.saved_year
		time_of_day.month = GameBackend.saved_month
		time_of_day.day = GameBackend.saved_day
		time_of_day.current_time = GameBackend.saved_current_time

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

	GameBackend.game_ended.connect(_on_game_ended)
	MusicManager.play_track("main_game")
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())

	_update_clock()


func _on_hour_passed(_hour) -> void:
	GameBackend.apply_passive_decay(1.0)


func _on_day_passed(_day) -> void:
	GameBackend.advance_day()


func _on_game_ended(_result: String) -> void:
	get_tree().change_scene_to_file("res://Main_Game/Scenes/EndingScene.tscn")

func _update_clock(_value = null):

	gui.update_time(time_of_day.game_time.substr(0,5))

	var weekday = get_weekday(
		time_of_day.day,
		time_of_day.month,
		time_of_day.year
	)

	gui.update_date("%s %d %s" % [
		weekday.substr(0,3),
		time_of_day.day,
		MONTHS[time_of_day.month]
	])

	GameBackend.sync_from_clock(time_of_day.current_time, time_of_day.day, time_of_day.month, time_of_day.year)

func _hour_changed(hour):

	var weekday = get_weekday(
		time_of_day.day,
		time_of_day.month,
		time_of_day.year
	)

	match weekday:

		"Monday":
			match hour:
				9:
					print("Math class begins")
				12:
					print("Lunch")
				15:
					print("School finished")

		"Tuesday":
			match hour:
				9:
					print("Science")

		"Friday":
			match hour:
				18:
					print("Part-time job available")

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

	var weekday = (
		year +
		year/4 -
		year/100 +
		year/400 +
		t[month-1] +
		day
	) % 7

	return weekdays[int(weekday)]
