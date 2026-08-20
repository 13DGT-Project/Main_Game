extends Node



var selected_university: String = ""

# GameBackend.universities[GameBackend.selected_university]

var universities = {
	"Auckland": {
		"money_needed": 35000,
		"grades_needed": 80,
		"location": "Auckland"
	},

	"Canterbury": {
		"money_needed": 36500,
		"grades_needed": 75,
		"location": "Christchurch"
	},

	"Waikato": {
		"money_needed": 27000,
		"grades_needed": 70,
		"location": "Hamilton"
	}
}


# --- Player stats -----------------------------------------------------------
# Single source of truth for the bars in gui.gd (Energy/Sanity/Thirst all
# start at 100 in gui.tscn, so "higher = better" for all three here too).
var money: float = 0.0
var subject_grades: Dictionary = {"english": 50.0, "maths": 50.0, "physics": 50.0}
var energy: float = 100.0   # was previously local to main_character.gd (sprint stamina) —
							 # moved here so it survives scene changes (school/work/main map)
var sanity: float = 100.0   # drains with stress (bad exams, long shifts, plain time passing),
							 # restored by chatting/resting. Hitting 0 ends the game (burnout).
var thirst: float = 100.0   # drains over time/activity, refilled by drinking
var temptation: float = 0.0 # rises from time-wasting activities, makes studying less effective

# Hours accumulated while in a scene without its own Sky3D (school/work).
# game_manager.gd applies this to the MainMap's TimeOfDay on load, then resets it.
var pending_hours: float = 0.0

# --- Run length / ending state ----------------------------------------------
const TOTAL_DAYS: int = 90          # length of the school year before the deadline
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


func get_elapsed_days() -> int:
	return TOTAL_DAYS - days_remaining


func log_event(text: String) -> void:
	journal.append({"day": get_elapsed_days(), "text": text})
	journal_updated.emit()


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
	pending_hours += hours
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
	if days_remaining <= 0:
		_check_deadline_ending()


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
	money = 0.0
	subject_grades = {"english": 50.0, "maths": 50.0, "physics": 50.0}
	energy = 100.0
	sanity = 100.0
	thirst = 100.0
	temptation = 0.0
	pending_hours = 0.0
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

	pending_hours += hours
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

	pending_hours += hours
	money += pay
	change_energy(-hours * 12.0)
	change_thirst(-hours * 8.0)
	change_sanity(-(hours * 2.0) + (performance * hours * 3.0))
	temptation = clamp(temptation - hours * 1.5, 0.0, 100.0)

	log_event("Worked a %.1fh shift — %.0f%% accuracy, earned $%.2f" % [hours, performance * 100.0, pay])
	stats_changed.emit()


## Drinking at a fountain/tap: small time cost, decent thirst refill.
func drink_water(amount: float = 40.0, hours: float = 0.05) -> void:
	pending_hours += hours
	change_thirst(amount)


## Chatting with a friend/classmate/coworker: relieves stress (sanity up),
## costs a little time, and (being a distraction) nudges temptation up —
## a genuine break, not a free one.
func socialize(sanity_relief: float = 12.0, hours: float = 0.3, temptation_gain: float = 5.0) -> void:
	pending_hours += hours
	change_sanity(sanity_relief)
	temptation = clamp(temptation + temptation_gain, 0.0, 100.0)
	stats_changed.emit()
