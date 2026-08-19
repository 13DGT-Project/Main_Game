extends Node

@onready var gui = $"../GUI"
@onready var time_of_day = $"../Sky3D/TimeOfDay"




const MONTHS = [
	"",
	"Jan","Feb","Mar","Apr","May","Jun",
	"Jul","Aug","Sep","Oct","Nov","Dec"
]

func _ready():
	time_of_day.minute_changed.connect(_update_clock)
	time_of_day.day_changed.connect(_update_clock)
	time_of_day.hour_changed.connect(_hour_changed)
	

	_update_clock()

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
