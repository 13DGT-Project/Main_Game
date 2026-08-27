extends CanvasLayer


@export var minimap_rect:TextureRect



@onready var energy_bar = $Control/Energy
@onready var sanity_bar = $Control/Sanity
@onready var thirst_bar = $Control/Thirst
@onready var time_label = $Control/TimeLabel
@onready var date_label = $Control/DateLabel
@onready var uni = $Control/University
@onready var player_name_label: Label = $PlayerNameLabel

@onready var event_banner: Panel = $EventBanner
@onready var event_label: Label = $EventBanner/EventLabel

const BANNER_CALM   := Color(0.22, 0.26, 0.34, 0.92)
const BANNER_SOON   := Color(0.55, 0.42, 0.12, 0.94)
const BANNER_URGENT := Color(0.60, 0.18, 0.18, 0.95)

var _banner_style: StyleBoxFlat


func _ready() -> void:
	_refresh_university_label()
	_refresh_player_name()
	GameBackend.stats_changed.connect(_refresh_from_backend)
	GameBackend.journal_updated.connect(_refresh_event_banner)
	# Duplicate so recolouring this instance doesn't tint every other scene
	# that shares the same StyleBoxFlat resource.
	_banner_style = event_banner.get_theme_stylebox("panel").duplicate()
	event_banner.add_theme_stylebox_override("panel", _banner_style)
	_refresh_from_backend()
	_refresh_event_banner()
	_setup_minimap_rect()


func _refresh_player_name() -> void:
	if player_name_label:
		player_name_label.text = GameBackend.player_name


func _refresh_university_label() -> void:
	if GameBackend.selected_university == "" or not GameBackend.universities.has(GameBackend.selected_university):
		uni.text = "No university chosen yet"
		return
	var data: Dictionary = GameBackend.universities[GameBackend.selected_university]
	uni.text = "%s — $%d / %d%%" % [GameBackend.selected_university, data.get("money_needed", 0), data.get("grades_needed", 0)]


func _refresh_from_backend() -> void:
	update_energy(GameBackend.energy)
	update_sanity(GameBackend.sanity)
	update_thirst(GameBackend.thirst)
	_refresh_event_banner()


func update_energy(value: float):
	energy_bar.value = value
		
func update_sanity(value: float):
	sanity_bar.value = value

func update_thirst(value: float):
	thirst_bar.value = value

func update_time(time_text:String):
	time_label.text = time_text

func update_date(date_text:String):
	date_label.text = date_text


# --- Event banner --------------------------------------------------------------
# Shows what's coming up (next exam, or the end-of-year deadline) and warms
# from grey to amber to red as it closes in. Lives here in the GUI so it shows
# up anywhere the GUI does — MainMap and every 2D scene alike.

## Ticked periodically as well as on signals, since the day can roll over
## without a stats_changed firing.
func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 30 == 0:
		_refresh_event_banner()


func _refresh_event_banner() -> void:
	if event_label == null or _banner_style == null:
		return

	if GameBackend.game_over:
		_set_banner("The year is over.", BANNER_URGENT)
		return

	# Once results are out the day counter stops meaning anything, so show
	# where you are in the results sequence instead.
	if GameBackend.results_phase == 2:
		_set_banner("Your university offer has arrived — check your phone", BANNER_URGENT)
		return
	if GameBackend.results_phase == 1:
		_set_banner("NCEA RESULTS ARE OUT — check your phone", BANNER_URGENT)
		return

	# Two exams can land on the same day, so name both.
	# Internals and externals are different things in different buildings, so
	# the banner has to say WHICH and WHERE. The old version called both
	# "EXAM" and told you to press T, which opened a list of externals that
	# today's internal was not even on.
	var due_today: Array = GameBackend.exams_due_today()
	if due_today.size() >= 2:
		var parts: Array = []
		for e in due_today:
			parts.append("%s %s" % [str(e.subject).capitalize(), str(e.get("kind", "internal"))])
		_set_banner("%d ASSESSMENTS TODAY: %s  —  press T" % [due_today.size(), ", ".join(parts)], BANNER_URGENT)
		return
	elif due_today.size() == 1:
		var one: Dictionary = due_today[0]
		if str(one.get("kind", "internal")) == "external":
			_set_banner("%s EXTERNAL TODAY — get to the EXAM HALL!" % str(one.subject).to_upper(), BANNER_URGENT)
		else:
			_set_banner("%s INTERNAL TODAY — sit it in class at SCHOOL" % str(one.subject).to_upper(), BANNER_URGENT)
		return

	# Something you agreed to matters more than a countdown.
	var today_commitments: Array = GameBackend.commitments_today()
	if not today_commitments.is_empty():
		_set_banner("TODAY: %s" % str(today_commitments[0].label), BANNER_SOON)
		return

	var days: int = GameBackend.days_until_next_exam()
	if days >= 0:
		var nxt: Dictionary = GameBackend.get_next_exam()
		var colour: Color = BANNER_CALM
		if days <= 1:
			colour = BANNER_URGENT
		elif days <= 3:
			colour = BANNER_SOON
		var when: String = "tomorrow" if days == 1 else "in %d days" % days
		var same_day: Array = GameBackend.exams_on_day(int(nxt.get("day", -1)))
		var label: String = str(nxt.get("subject", "")).capitalize()
		if same_day.size() >= 2:
			label = "%d exams" % same_day.size()
		var suffix: String = "  —  press T for timetable" if days <= 3 else ""
		_set_banner("Next: %s %s %s%s" % [label, str(nxt.get("kind", "internal")), when, suffix], colour)
		return

	var left: int = GameBackend.days_remaining
	var colour2: Color = BANNER_CALM
	if left <= 3:
		colour2 = BANNER_URGENT
	elif left <= 7:
		colour2 = BANNER_SOON
	_set_banner("%d days until the end of the year" % left, colour2)


func _set_banner(text: String, colour: Color) -> void:
	event_label.text = text
	_banner_style.bg_color = colour


## Only MainMap has a MinimapViewport; the 2D scenes don't. Hide the minimap
## panel there instead of erroring out (which used to abort the rest of
## _ready() and leave the HUD half-initialised).
func _setup_minimap_rect() -> void:
	if minimap_rect == null:
		return
	var scene := get_tree().current_scene
	var viewport := scene.get_node_or_null("MinimapViewport") if scene else null
	if viewport is SubViewport:
		minimap_rect.texture = (viewport as SubViewport).get_texture()
		minimap_rect.visible = true
	else:
		minimap_rect.visible = false
