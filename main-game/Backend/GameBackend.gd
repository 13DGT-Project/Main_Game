extends Node



var selected_university: String = ""

# GameBackend.universities[GameBackend.selected_university]

var universities = {
	"Auckland": {
		"money_needed": 350,
		"grades_needed": 80,
		"location": "Auckland"
	},

	"Canterbury": {
		"money_needed": 365,
		"grades_needed": 75,
		"location": "Christchurch"
	},

	"Waikato": {
		"money_needed": 270,
		"grades_needed": 70,
		"location": "Hamilton"
	}
}


# --- Player stats -----------------------------------------------------------
# Single source of truth for the bars in gui.gd (Energy/Sanity/Thirst all
# start at 100 in gui.tscn, so "higher = better" for all three here too).
var money: float = 0.0

const ALL_SUBJECTS: Array = ["english", "maths", "physics", "chemistry", "biology"]
const MAJORS: Dictionary = {
	"Science": ["physics", "chemistry", "biology"],
	"Engineering": ["maths", "physics", "chemistry"],
	"Health Science": ["biology", "chemistry", "english"],
	"Arts & Commerce": ["english", "maths", "biology"],
}
var selected_major: String = ""
var active_subjects: Array = ["english", "maths", "physics"]  # default until a major is chosen
var subject_grades: Dictionary = {"english": 50.0, "maths": 50.0, "physics": 50.0}

var energy: float = 100.0   # was previously local to main_character.gd (sprint stamina) —
							 # moved here so it survives scene changes (school/work/main map)
var sanity: float = 100.0   # drains with stress (bad exams, long shifts, plain time passing),
							 # restored by chatting/resting. Hitting 0 ends the game (burnout).
var thirst: float = 100.0   # drains over time/activity, refilled by drinking
var temptation: float = 0.0 # rises from time-wasting activities, makes studying less effective —
							 # shown in the Journal (press J), not on the main HUD bars.

# The single source of truth for "how many days have passed" (used for the
# days_remaining countdown and gating like the dairy's hours). Kept live even
# outside MainMap via _queue_hours(). Not calendar-accurate on its own —
# see the snapshot below for that.
var game_hour: float = 8.0   # 0-24, running estimate
var game_day: int = 1        # counts up from 1, only used to detect day-crossings

# Hours accumulated while in a scene without its own Sky3D (school/work/home).
# Re-applied via += on top of the restored snapshot below when MainMap loads,
# so TimeOfDay's own hour/day/month rollover logic handles the wraparound
# correctly instead of me reimplementing its calendar math.
var pending_hours: float = 0.0

# A continuously-updated snapshot of MainMap's real Sky3D clock (see
# game_manager.gd's _update_clock). MainMap's TimeOfDay node gets destroyed
# and recreated — with its saved DEFAULT start time! — every time you leave
# and re-enter MainMap, so this is what lets it restore where you actually
# were instead of resetting.
var saved_current_time: float = 8.0
var saved_day: int = 1
var saved_month: int = 1
var saved_year: int = 1
var has_time_snapshot: bool = false

# Where to place the player back in MainMap after returning from a scene
# entered through a door (see scene_door.gd). Set right before the scene
# change, consumed once by game_manager.gd on MainMap's next _ready().
var return_position: Vector3 = Vector3.ZERO
var has_return_position: bool = false

# --- Portable water bottle (picked up at home, refilled at any tap/fountain) -
var water_bottle_full: bool = true

# --- Simple banking, accessed through the phone's Bank app ------------------
var savings_balance: float = 0.0
const SAVINGS_DAILY_RATE: float = 0.004  # ~0.4%/day, compounds once per in-game day

var term_deposit_amount: float = 0.0
var term_deposit_days_left: int = 0
const TERM_DEPOSIT_DAYS: int = 10
const TERM_DEPOSIT_RATE: float = 0.06  # total return paid out at maturity

# --- Run length / ending state ----------------------------------------------
const TOTAL_DAYS: int = 4          # length of the school year before the deadline
var days_remaining: int = TOTAL_DAYS
var game_over: bool = false
var ending_result: String = ""      # "" | "good" | "bad_deadline" | "bad_sanity"

# --- Journal -----------------------------------------------------------------
# Array of {day: int, text: String}. UI reads this directly; use log_event()
# to add to it so the day number and signal are always consistent.
var journal: Array = []

signal stats_changed
signal journal_updated
signal game_ended(result: String)


func get_overall_grade() -> float:
	var values: Array = subject_grades.values()
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for v in values:
		total += v
	return total / values.size()


## "English: 62   Chemistry: 58   Biology: 71" — whatever's currently active.
func get_subject_grades_text() -> String:
	var parts: Array = []
	for subject in active_subjects:
		parts.append("%s: %.0f" % [subject.capitalize(), subject_grades.get(subject, 0.0)])
	return "   ".join(parts)


## Sets the player's 3 subjects for the year based on their chosen major.
## Called once from the major-select screen, right after choosing a university.
func set_major(major: String) -> void:
	if not MAJORS.has(major):
		push_warning("GameBackend: unknown major '%s'" % major)
		return
	selected_major = major
	active_subjects = MAJORS[major].duplicate()
	subject_grades = {}
	for subject in active_subjects:
		subject_grades[subject] = 50.0
	stats_changed.emit()


func get_elapsed_days() -> int:
	return TOTAL_DAYS - days_remaining


func log_event(text: String) -> void:
	journal.append({"day": get_elapsed_days(), "text": text})
	journal_updated.emit()


## Advances the authoritative game clock. Every function that makes time pass
## (studying, working, sleeping, etc.) goes through this — it wraps at 24
## hours into the next day, and ticks the day countdown/banking for every day
## crossed (even if several days pass in one call).
func _queue_hours(hours: float) -> void:
	pending_hours += hours
	game_hour += hours
	while game_hour >= 24.0:
		game_hour -= 24.0
		game_day += 1
		advance_day()


## Called continuously by game_manager.gd's _update_clock() while actually in
## MainMap, so GameBackend always has a fresh, accurate snapshot of where the
## player really is the moment they walk through a door.
func sync_from_clock(current_time: float, day: int, month: int, year: int) -> void:
	saved_current_time = current_time
	saved_day = day
	saved_month = month
	saved_year = year
	has_time_snapshot = true
	game_hour = current_time


func change_energy(amount: float) -> void:
	energy = clamp(energy + amount, 0.0, 100.0)
	stats_changed.emit()


func change_sanity(amount: float) -> void:
	sanity = clamp(sanity + amount, 0.0, 100.0)
	stats_changed.emit()
	if sanity <= 0.0 and not game_over:
		_end_game("bad_sanity")


func change_thirst(amount: float) -> void:
	thirst = clamp(thirst + amount, 0.0, 100.0)
	stats_changed.emit()


func add_money(amount: float) -> void:
	money += amount
	stats_changed.emit()


## Queues in-game hours to be applied to the MainMap's Sky3D clock next time
## it loads (school/work scenes don't carry their own Sky3D), and applies the
## passive stat drain for those hours immediately either way.
func advance_time(hours: float) -> void:
	_queue_hours(hours)
	apply_passive_decay(hours)


## Background drain that happens just from time passing, regardless of what
## the player is doing — thirst drops steadily, and sanity drops a bit faster
## if you're already running on empty (exhausted or parched). Call this for
## any block of hours that isn't already covered by a study/work/social call.
func apply_passive_decay(hours: float) -> void:
	if game_over or hours <= 0.0:
		return
	change_thirst(-hours * 4.0)
	var sanity_drain_rate: float = 1.5
	if energy < 25.0:
		sanity_drain_rate += 1.0
	if thirst < 25.0:
		sanity_drain_rate += 1.0
	change_sanity(-hours * sanity_drain_rate)


## Called once per in-game day (connect to Sky3D's day_changed in MainMap).
## Ticks the deadline down and checks whether the year is over.
func advance_day() -> void:
	if game_over:
		return
	days_remaining -= 1
	_apply_daily_banking()
	if days_remaining <= 0:
		_check_deadline_ending()


func _apply_daily_banking() -> void:
	if savings_balance > 0.0:
		savings_balance *= (1.0 + SAVINGS_DAILY_RATE)
	if term_deposit_amount > 0.0:
		term_deposit_days_left -= 1
		if term_deposit_days_left <= 0:
			var payout: float = term_deposit_amount * (1.0 + TERM_DEPOSIT_RATE)
			money += payout
			log_event("Term deposit matured — received $%.2f" % payout)
			term_deposit_amount = 0.0
			stats_changed.emit()


func _check_deadline_ending() -> void:
	if game_over:
		return
	var uni: Dictionary = universities.get(selected_university, {})
	var money_ok: bool = money >= uni.get("money_needed", 0)
	var grades_ok: bool = get_overall_grade() >= uni.get("grades_needed", 0)
	if money_ok and grades_ok:
		_end_game("good")
	else:
		_end_game("bad_deadline")


func _end_game(result: String) -> void:
	if game_over:
		return
	game_over = true
	ending_result = result
	log_event("--- The year is over. ---" if result != "bad_sanity" else "--- Burnout. ---")
	game_ended.emit(result)


## Resets everything for a fresh playthrough (called from the ending screen's
## "Main Menu" button, or wherever you want to let the player restart).
func reset_run() -> void:
	selected_university = ""
	selected_major = ""
	active_subjects = ["english", "maths", "physics"]
	money = 0.0
	subject_grades = {"english": 50.0, "maths": 50.0, "physics": 50.0}
	energy = 100.0
	sanity = 100.0
	thirst = 100.0
	temptation = 0.0
	game_hour = 8.0
	game_day = 1
	pending_hours = 0.0
	saved_current_time = 8.0
	saved_day = 1
	saved_month = 1
	saved_year = 1
	has_time_snapshot = false
	water_bottle_full = true
	savings_balance = 0.0
	term_deposit_amount = 0.0
	term_deposit_days_left = 0
	days_remaining = TOTAL_DAYS
	game_over = false
	ending_result = ""
	journal.clear()
	stats_changed.emit()
	journal_updated.emit()


## Called by the school scene when a subject test finishes. Grade gain scales
## with accuracy and is reduced by built-up temptation — procrastinating
## earlier blunts today's study session.
func complete_study_session(subject: String, correct: int, total: int, hours: float,
		energy_cost: float = 6.0, max_grade_gain: float = 8.0) -> void:
	if not subject_grades.has(subject):
		push_warning("GameBackend: unknown subject '%s'" % subject)
		return

	var accuracy: float = 0.0 if total <= 0 else float(correct) / float(total)
	var grade_gain: float = max_grade_gain * accuracy
	grade_gain *= 1.0 - (temptation / 200.0)

	_queue_hours(hours)
	subject_grades[subject] = clamp(subject_grades[subject] + grade_gain, 0.0, 100.0)
	change_energy(-energy_cost)
	change_sanity(-(5.0 - accuracy * 5.0))  # doing badly is stressful, doing well is a small relief
	change_thirst(-hours * 3.0)
	temptation = clamp(temptation - 3.0, 0.0, 100.0)  # focused work chips away at temptation

	log_event("Studied %s — %d/%d correct (grade now %.0f)" % [subject.capitalize(), correct, total, subject_grades[subject]])
	stats_changed.emit()


## Called by the work scene when a shift ends. `performance` is 0..1 (accuracy
## across the shift's tasks). Physical work costs more energy/thirst than
## studying; a smooth shift is a genuine break from schoolwork stress.
func complete_work_shift(hours: float, performance: float, base_pay_per_hour: float = 25.0) -> void:
	performance = clamp(performance, 0.0, 1.0)
	var pay: float = base_pay_per_hour * hours * (0.6 + 0.4 * performance)

	_queue_hours(hours)
	money += pay
	change_energy(-hours * 12.0)
	change_thirst(-hours * 8.0)
	change_sanity(-(hours * 2.0) + (performance * hours * 3.0))
	temptation = clamp(temptation - hours * 1.5, 0.0, 100.0)

	log_event("Worked a %.1fh shift — %.0f%% accuracy, earned $%.2f" % [hours, performance * 100.0, pay])
	stats_changed.emit()


## Drinking at a fountain/tap: small time cost, decent thirst refill.
func drink_water(amount: float = 40.0, hours: float = 0.05) -> void:
	_queue_hours(hours)
	change_thirst(amount)


## Sleeping in your own bed: a big energy/sanity restore, but eats a large
## chunk of time (as sleep should). Doesn't refill thirst — you're not
## drinking while you sleep.
func sleep(hours: float = 8.0) -> void:
	_queue_hours(hours)
	energy = 100.0
	change_sanity(20.0)
	change_thirst(-hours * 1.0)
	log_event("Slept for %.0f hours." % hours)
	stats_changed.emit()


## Cooking at home: costs money, restores energy/thirst/sanity by varying
## amounts depending which meal option the player picked.
func cook_meal(cost: float, energy_gain: float, thirst_gain: float, sanity_gain: float, hours: float = 0.4) -> bool:
	if cost > money:
		return false
	money -= cost
	_queue_hours(hours)
	change_energy(energy_gain)
	change_thirst(thirst_gain)
	change_sanity(sanity_gain)
	stats_changed.emit()
	return true


## Watching TV on the couch: same shape as doomscroll(), just a bigger single
## sitting (longer, more relief, more temptation) rather than quick top-ups.
func watch_tv(hours: float = 0.6, sanity_relief: float = 8.0, temptation_gain: float = 10.0) -> void:
	_queue_hours(hours)
	change_sanity(sanity_relief)
	change_thirst(-hours * 2.0)
	temptation = clamp(temptation + temptation_gain, 0.0, 100.0)
	stats_changed.emit()


## Chatting with a friend/classmate/coworker: relieves stress (sanity up),
## costs a little time, and (being a distraction) nudges temptation up —
## a genuine break, not a free one.
func socialize(sanity_relief: float = 12.0, hours: float = 0.3, temptation_gain: float = 5.0) -> void:
	_queue_hours(hours)
	change_sanity(sanity_relief)
	temptation = clamp(temptation + temptation_gain, 0.0, 100.0)
	stats_changed.emit()


# --- Water bottle -------------------------------------------------------------

## Drinks from the bottle if it has water. Returns false (does nothing) if
## it's empty — refill it at a fountain/tap first.
func use_water_bottle(amount: float = 35.0) -> bool:
	if not water_bottle_full:
		return false
	water_bottle_full = false
	change_thirst(amount)
	return true


func refill_water_bottle() -> void:
	water_bottle_full = true
	stats_changed.emit()


# --- Banking (phone Bank app) --------------------------------------------------

func deposit_savings(amount: float) -> bool:
	if amount <= 0.0 or amount > money:
		return false
	money -= amount
	savings_balance += amount
	stats_changed.emit()
	return true


func withdraw_savings(amount: float) -> bool:
	if amount <= 0.0 or amount > savings_balance:
		return false
	savings_balance -= amount
	money += amount
	stats_changed.emit()
	return true


## Locks `amount` away for TERM_DEPOSIT_DAYS in-game days for a better rate
## than plain savings. Only one term deposit can be active at a time.
func start_term_deposit(amount: float) -> bool:
	if amount <= 0.0 or amount > money or term_deposit_amount > 0.0:
		return false
	money -= amount
	term_deposit_amount = amount
	term_deposit_days_left = TERM_DEPOSIT_DAYS
	stats_changed.emit()
	return true


# --- Phone doomscrolling --------------------------------------------------------

## The generic "waste time on your phone" action: a little sanity relief, a
## little time, a temptation cost — same shape as socialize()/drink_water(),
## just worse for you the more you lean on it.
func doomscroll(hours: float = 0.2, sanity_relief: float = 3.0, temptation_gain: float = 8.0) -> void:
	_queue_hours(hours)
	change_sanity(sanity_relief)
	change_thirst(-hours * 2.0)
	temptation = clamp(temptation + temptation_gain, 0.0, 100.0)
	stats_changed.emit()
