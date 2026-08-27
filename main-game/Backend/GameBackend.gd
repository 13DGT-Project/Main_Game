extends Node


## What the player called themselves at the start. NPCs use this, and it
## shows in the top-left of the HUD.
var player_name: String = "Alex"

var selected_university: String = ""

# GameBackend.universities[GameBackend.selected_university]

var universities = {
	"Auckland": {
		"money_needed": 8200,
		"grades_needed": 72,
		"location": "Auckland",
		"full_name": "the University of Auckland",
		"admissions": "University of Auckland — Admissions",
	},

	"Canterbury": {
		"money_needed": 7400,
		"grades_needed": 66,
		"location": "Christchurch",
		"full_name": "the University of Canterbury",
		"admissions": "University of Canterbury — Admissions",
	},

	"Waikato": {
		"money_needed": 6900,
		"grades_needed": 60,
		"location": "Hamilton",
		"full_name": "the University of Waikato",
		"admissions": "University of Waikato — Admissions",
	}
}


## The proper name of the university, for letters and offers.
## ("Auckland" is fine on the HUD; "the University of Auckland" is what an
## actual admissions email would say.)
func university_full_name() -> String:
	return str(universities.get(selected_university, {}).get("full_name", selected_university))


## Who the offer actually comes FROM. In real life offers are made by each
## university's own admissions office — Universities NZ (Te Pōkai Tara) is
## just the sector body and never sends you anything.
func admissions_sender() -> String:
	return str(universities.get(selected_university, {}).get("admissions", "Admissions"))


# =============================================================================
# BALANCE — everything tuned for a 90-day year lives here, in one block.
# =============================================================================
## Length of the school year before the deadline.
##
## NOTE: the run-length knobs below are `var`, not `const`, purely so the dev
## panel can retune them at runtime (see apply_test_mode). They're read exactly
## the same way everywhere else — GameBackend.TOTAL_DAYS still works — and if
## you delete the dev panel they behave like constants again because nothing
## else ever writes to them. The DEFAULT_* copies underneath are what
## restore_normal_mode() puts back.
var TOTAL_DAYS: int = 90
## The hour the game (and every morning) starts at. 7am, not 8pm, not 4am.
const DAY_START_HOUR: float = 7.0
## Sleeping always takes you to this hour the following morning.
const WAKE_HOUR: float = 7.0
## Real-world minutes per in-game day on MainMap's Sky3D clock. At 120, one
## real minute of walking is about twelve in-game minutes — enough that
## crossing town costs you part of a morning, but not so much that the 90-day
## year evaporates while you stand still. It was 60, which over 90 days meant
## a full day passing every real minute.
const MINUTES_PER_DAY: float = 120.0
## Base sanity lost per waking hour, before any extra pressure.
##
## Tuned DOWN from 1.1: with the stacked pressure multipliers below, a bad
## week could take you from full to burnt out with no realistic way back, and
## an ending you can't see coming or recover from isn't a challenge, it's just
## an ambush. Rest now genuinely out-paces the drain if you actually rest.
var SANITY_BASE_DRAIN: float = 0.55
## Thirst lost per waking hour.
var THIRST_BASE_DRAIN: float = 1.8
## Finish the year below this much sanity and you defer rather than enrol,
## even if you qualified. Burnout at 0 ends the run early regardless.
const SANITY_DEFER_THRESHOLD: float = 25.0


# =============================================================================
# TEST MODE  —  used only by the dev panel (Backend/Dev/dev_panel.gd)
# =============================================================================
# Delete the dev panel and this block becomes inert: nothing else in the game
# ever calls apply_test_mode(), and dev_no_decay is only ever read, never set.

## Set by the dev panel. When true, passive stat drain is skipped entirely.
var dev_no_decay: bool = false
## True while the shortened test-length year is active.
var test_mode: bool = false

## The shipping values, kept so restore_normal_mode() can put them back.
const DEFAULTS := {
	"TOTAL_DAYS": 90,
	"EXAM_INTERVAL_DAYS": 3,
	"EXTERNALS_WINDOW_DAYS": 14,
	"UE_CREDITS_PER_SUBJECT": 14,
	"UE_SUBJECTS_REQUIRED": 3,
	"UE_LITERACY_REQUIRED": 10,
	"UE_NUMERACY_REQUIRED": 10,
	"LOAN_APPLY_CLOSES_DAY": 78,
	"LOAN_PROCESSING_DAYS": 5,
	"ALLOWANCE_PROCESSING_DAYS": 7,
	"ACCOM_APPLY_CLOSES_DAY": 82,
	"TERM_DEPOSIT_DAYS": 20,
}

## A whole run compressed into TOTAL. Everything that's a day count scales
## with it, because the trap when you shorten a run by hand is that the
## absolute deadlines (loan closes day 78, accommodation day 82) either never
## fire or have already passed on day one.
const TEST_PRESET := {
	"TOTAL_DAYS": 12,
	"EXAM_INTERVAL_DAYS": 1,
	"EXTERNALS_WINDOW_DAYS": 4,
	"UE_CREDITS_PER_SUBJECT": 3,
	"UE_SUBJECTS_REQUIRED": 2,
	"UE_LITERACY_REQUIRED": 10,
	"UE_NUMERACY_REQUIRED": 10,
	"LOAN_APPLY_CLOSES_DAY": 9,
	"LOAN_PROCESSING_DAYS": 1,
	"ALLOWANCE_PROCESSING_DAYS": 1,
	"ACCOM_APPLY_CLOSES_DAY": 10,
	"TERM_DEPOSIT_DAYS": 3,
}


## Switches to the short year and rebuilds the exam timetable around it.
## Days already elapsed are preserved proportionally so you don't jump
## backwards mid-run.
func apply_test_mode() -> void:
	var elapsed_fraction: float = float(get_elapsed_days()) / float(max(1, TOTAL_DAYS))
	for key in TEST_PRESET:
		set(key, TEST_PRESET[key])
	test_mode = true
	days_remaining = TOTAL_DAYS - int(round(elapsed_fraction * float(TOTAL_DAYS)))
	days_remaining = clampi(days_remaining, 1, TOTAL_DAYS)
	generate_exam_schedule()
	log_event("[dev] TEST MODE on — %d-day year." % TOTAL_DAYS)
	stats_changed.emit()


func restore_normal_mode() -> void:
	var elapsed_fraction: float = float(get_elapsed_days()) / float(max(1, TOTAL_DAYS))
	for key in DEFAULTS:
		set(key, DEFAULTS[key])
	test_mode = false
	days_remaining = TOTAL_DAYS - int(round(elapsed_fraction * float(TOTAL_DAYS)))
	days_remaining = clampi(days_remaining, 1, TOTAL_DAYS)
	generate_exam_schedule()
	log_event("[dev] TEST MODE off — back to a %d-day year." % TOTAL_DAYS)
	stats_changed.emit()


# --- Player stats -----------------------------------------------------------
# Single source of truth for the bars in gui.gd (Energy/Sanity/Thirst all
# start at 100 in gui.tscn, so "higher = better" for all three here too).
var money: float = 100.00

const ALL_SUBJECTS: Array = ["english", "maths", "physics", "chemistry", "biology"]
const MAJORS: Dictionary = {
	"Science": ["physics", "chemistry", "biology", "maths", "english"],
	"Engineering": ["maths", "physics", "chemistry", "english", "digital_technologies"],
	"Health Science": ["biology", "chemistry", "english", "statistics", "maths"],
	"Commerce": ["economics", "maths", "statistics", "english", "digital_technologies"],
	"Arts": ["english", "history", "geography", "media_studies", "statistics"],
	"Computer Science": ["digital_technologies", "maths", "physics", "statistics", "english"],
	"Law": ["english", "history", "economics", "media_studies", "statistics"],
	"Architecture": ["maths", "physics", "media_studies", "english", "digital_technologies"],
	"Education": ["english", "history", "biology", "physical_education", "statistics"],
	"Sport & Exercise Science": ["physical_education", "biology", "chemistry", "statistics", "english"],
	"Environmental Science": ["geography", "biology", "chemistry", "statistics", "english"],
	"Communications": ["media_studies", "english", "history", "statistics", "geography"],
}

## Conjoint degrees — two degrees at once. More doors open, but you need a
## higher overall grade to be accepted.
const CONJOINTS: Dictionary = {
	"Science + Commerce": {
		"subjects": ["maths", "statistics", "economics", "physics", "english"],
		"grade_bonus_required": 8.0,
	},
	"Engineering + Commerce": {
		"subjects": ["maths", "physics", "economics", "statistics", "digital_technologies"],
		"grade_bonus_required": 10.0,
	},
	"Health Science + Arts": {
		"subjects": ["biology", "chemistry", "english", "geography", "statistics"],
		"grade_bonus_required": 8.0,
	},
	"Law + Arts": {
		"subjects": ["english", "history", "media_studies", "economics", "statistics"],
		"grade_bonus_required": 9.0,
	},
	"Law + Commerce": {
		"subjects": ["english", "economics", "maths", "statistics", "history"],
		"grade_bonus_required": 11.0,
	},
	"Science + Engineering": {
		"subjects": ["physics", "chemistry", "maths", "digital_technologies", "english"],
		"grade_bonus_required": 12.0,
	},
	"Computer Science + Commerce": {
		"subjects": ["digital_technologies", "maths", "economics", "statistics", "english"],
		"grade_bonus_required": 9.0,
	},
	"Health Science + Sport Science": {
		"subjects": ["biology", "chemistry", "physical_education", "statistics", "english"],
		"grade_bonus_required": 8.0,
	},
}

var selected_conjoint: String = ""
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
var game_hour: float = DAY_START_HOUR   # 0-24, running estimate
var game_day: int = 1                   # counts up from 1, only used to detect day-crossings

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
var saved_current_time: float = DAY_START_HOUR
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
const SAVINGS_DAILY_RATE: float = 0.0012  # compounds once per in-game day

var term_deposit_amount: float = 0.0
var term_deposit_days_left: int = 0
var TERM_DEPOSIT_DAYS: int = 20
const TERM_DEPOSIT_RATE: float = 0.05  # total return paid out at maturity

# --- Run length / ending state ----------------------------------------------
var days_remaining: int = TOTAL_DAYS
var game_over: bool = false
## Results come out before the offer, so the run pauses between the two.
## 0 = year running, 1 = results are out, 2 = offer is out and waiting to be read.
var results_phase: int = 0
var ending_result: String = ""      # "" | "good" | "bad_deadline" | "bad_sanity" | ...


# =============================================================================
# STUDENT LOAN — StudyLink
# =============================================================================
# You do not simply "get a loan" at the end of the year. You apply to
# StudyLink, months in advance, on the laptop at home, and you wait for a
# decision. Forget to, or leave it too late, and a place you technically
# earned can still be out of reach.

## "none" | "submitted" | "approved" | "declined"
var loan_status: String = "none"
## Days left until StudyLink comes back with a decision.
var loan_days_left: int = 0
## Why it was declined, shown on the laptop and in the ending.
var loan_decline_reason: String = ""
## Which parts of the loan were applied for.
var loan_wants_fees: bool = false
var loan_wants_living_costs: bool = false
## Total borrowed so far (living costs paid out weekly + fees at enrolment).
var loan_debt: float = 0.0
## What the player entered on the form. Wrong details get you declined —
## same as the real thing.
var loan_ird_number: String = ""

## Your IRD number. Every New Zealander has one; you'd find it on a payslip,
## in your banking app, or on a letter from IRD. It exists as real data on the
## player so StudyLink can ask for it and you can actually go and find it —
## previously the form demanded a number the game never gave you anywhere.
var ird_number: String = ""


func _ready() -> void:
	_ensure_ird()


func _ensure_ird() -> void:
	if ird_number == "":
		ird_number = str(randi_range(100000000, 999999999))


var LOAN_PROCESSING_DAYS: int = 5
const LOAN_LIVING_COSTS_WEEKLY: float = 300.0
## Applications for the coming academic year close this many days before the
## end of the run. Leave it later than this and you're declined on timing.
var LOAN_APPLY_CLOSES_DAY: int = 78


func loan_applications_open() -> bool:
	return get_elapsed_days() < LOAN_APPLY_CLOSES_DAY


# =============================================================================
# STUDENT ALLOWANCE
# =============================================================================
# The other half of StudyLink, and the half people confuse with the loan.
#
#   LOAN       borrowed, has to be paid back, NOT means-tested — everyone who
#              qualifies as a student gets one.
#   ALLOWANCE  a weekly payment you do NOT pay back, but it IS means-tested on
#              your parents' income until you're 24. Most students who apply
#              are declined or get a reduced rate, and that surprises people
#              every single year.
#
# So: applying for both is always the right move, and being declined for the
# allowance is normal rather than a punishment.

## "none" | "submitted" | "approved" | "declined"
var allowance_status: String = "none"
var allowance_days_left: int = 0
var allowance_decline_reason: String = ""
## Weekly rate actually granted (0 if declined, reduced on partial).
var allowance_weekly: float = 0.0
## Total received across the year. Never repaid.
var allowance_received: float = 0.0

## Your parents' combined income, rolled at the start of the run.
##
## THE PLAYER NEVER SEES THIS NUMBER, and neither does the UI. You're
## seventeen — you don't know what your parents earn, and asking is its own
## awkward conversation. That's not a gap in the design, it IS the design:
## StudyLink asks THEM directly, they fill in their half, and you find out
## the answer at the same time you find out the decision.
var household_income: float = 0.0

## Set true once your parents have completed their section of the form. Until
## then the application sits there doing nothing, which is exactly what
## happens in real life while you nag them about it.
var parents_confirmed_income: bool = false
## Days the application has been stuck waiting on them, so Mum can be chased.
var allowance_waiting_days: int = 0

var ALLOWANCE_PROCESSING_DAYS: int = 7
const ALLOWANCE_FULL_WEEKLY: float = 290.0
## Below this, full rate. Above the upper threshold, nothing. In between, an
## abated (reduced) rate.
const ALLOWANCE_INCOME_FULL: float = 62000.0
const ALLOWANCE_INCOME_CUTOFF: float = 105000.0


func _roll_household_income() -> void:
	if household_income <= 0.0:
		household_income = round(randf_range(46000.0, 118000.0) / 500.0) * 500.0


## What you'd be entitled to weekly, given the household income.
func allowance_entitlement() -> float:
	_roll_household_income()
	if household_income <= ALLOWANCE_INCOME_FULL:
		return ALLOWANCE_FULL_WEEKLY
	if household_income >= ALLOWANCE_INCOME_CUTOFF:
		return 0.0
	# Straight-line abatement between the two thresholds.
	var span: float = ALLOWANCE_INCOME_CUTOFF - ALLOWANCE_INCOME_FULL
	var over: float = household_income - ALLOWANCE_INCOME_FULL
	return round(ALLOWANCE_FULL_WEEKLY * (1.0 - over / span))


func apply_for_student_allowance(ird: String) -> Array:
	if allowance_status == "submitted":
		return [false, "You already have an allowance application being processed."]
	if allowance_status in ["approved", "declined"]:
		return [false, "You have already had a decision on your allowance application."]

	var cleaned: String = ird.strip_edges().replace("-", "").replace(" ", "")
	if cleaned.length() < 8 or not cleaned.is_valid_int():
		return [false, "That IRD number doesn't look right. It should be 8 or 9 digits."]

	allowance_days_left = ALLOWANCE_PROCESSING_DAYS
	allowance_status = "submitted"
	allowance_decline_reason = ""
	allowance_waiting_days = 0
	parents_confirmed_income = false
	# Your half is done. Now it needs theirs — which is a text you have to
	# actually send.
	deliver_message("allowance_parents")
	if not loan_applications_open():
		allowance_decline_reason = "Application received after the cut-off for this academic year."
		log_event("Applied for a Student Allowance — after the cut-off.")
		stats_changed.emit()
		return [true, "Submitted, but applications for this academic year have closed."]

	log_event("Applied to StudyLink for a Student Allowance. Your parents still have to complete their section.")
	stats_changed.emit()
	return [true, "Your half is submitted. The allowance is means-tested on your parents' income, so StudyLink now needs THEM to confirm their details before anything is assessed. Message them."]


## Called by the Mum thread when you actually chase them about it.
func confirm_parents_income() -> void:
	if parents_confirmed_income:
		return
	parents_confirmed_income = true
	allowance_days_left = ALLOWANCE_PROCESSING_DAYS
	log_event("Your parents completed their part of the allowance application.")
	stats_changed.emit()


# --- The decision --------------------------------------------------------------
# A binary approved/declined made the allowance a coin flip you couldn't
# influence and couldn't be surprised by twice. The real thing has a spread of
# outcomes, and most of them are partial. These are the ones worth modelling:
#
#   full          under the threshold — the full weekly rate
#   partial       over it, but abated rather than cut off. The most common
#                 real outcome, and the one people don't expect.
#   stand_down    entitled, but payments don't start for a few weeks. You get
#                 the money eventually; you don't get it NOW, which matters.
#   accom_only    no allowance, but you qualify for the smaller Accommodation
#                 Benefit. A consolation prize that is still real money.
#   declined      over the threshold entirely.
#   incomplete    your parents never sent their part in before the cut-off.
#
## The result of the assessment, one of the ids above.
var allowance_outcome: String = ""
## Weeks before payments start, for a stand-down.
var allowance_stand_down_weeks: int = 0
## Small weekly accommodation supplement, if that's all you qualified for.
var accommodation_benefit_weekly: float = 0.0
const ACCOM_BENEFIT_WEEKLY: float = 85.0
## Set once a mid-year review has run, so it only happens the once.
var allowance_reviewed: bool = false


## Works out which of the outcomes above applies. Income does most of the
## work, but not all of it — a stand-down or an accommodation-only result can
## land on top, which is why two runs with similar parents don't match.
func _decide_allowance_outcome() -> String:
	_roll_household_income()

	if not parents_confirmed_income:
		return "incomplete"

	var entitlement: float = allowance_entitlement()

	if entitlement >= ALLOWANCE_FULL_WEEKLY:
		# Even a clear approval sometimes comes with a stand-down.
		return "stand_down" if randf() < 0.25 else "full"

	if entitlement > 0.0:
		return "stand_down" if randf() < 0.15 else "partial"

	# Over the threshold. Living away from home is what unlocks the smaller
	# accommodation supplement, so where you chose to live actually matters.
	if accommodation_choice in ["halls", "flat"]:
		return "accom_only" if randf() < 0.6 else "declined"
	return "declined"


func _tick_allowance() -> void:
	if allowance_status != "submitted":
		return

	# Stalled until they do their bit. This is the single most common reason a
	# real allowance application goes nowhere.
	if not parents_confirmed_income:
		allowance_waiting_days += 1
		# A nudge after a week, in case the first text got ignored.
		if allowance_waiting_days == 7:
			deliver_message("allowance_parents_nudge")
		# If they never do it, the application dies at the cut-off rather
		# than hanging forever.
		if not loan_applications_open():
			allowance_status = "declined"
			allowance_outcome = "incomplete"
			allowance_decline_reason = "Your parents never completed their section before the cut-off."
			log_event("Student Allowance lapsed — the parental section was never returned.")
			deliver_message("allowance_result")
			stats_changed.emit()
		return

	allowance_days_left -= 1
	if allowance_days_left > 0:
		return

	if allowance_decline_reason != "":
		allowance_status = "declined"
		allowance_outcome = "declined"
		allowance_weekly = 0.0
		log_event("Student Allowance declined: %s" % allowance_decline_reason)
		deliver_message("allowance_result")
		stats_changed.emit()
		return

	allowance_outcome = _decide_allowance_outcome()
	match allowance_outcome:
		"full":
			allowance_status = "approved"
			allowance_weekly = ALLOWANCE_FULL_WEEKLY
			log_event("Student Allowance approved at the full rate, $%.0f a week." % allowance_weekly)
		"partial":
			allowance_status = "approved"
			allowance_weekly = allowance_entitlement()
			log_event("Student Allowance approved at a reduced rate of $%.0f a week." % allowance_weekly)
		"stand_down":
			allowance_status = "approved"
			allowance_weekly = maxf(allowance_entitlement(), ALLOWANCE_FULL_WEEKLY * 0.5)
			allowance_stand_down_weeks = randi_range(2, 5)
			log_event("Student Allowance approved at $%.0f a week, after a %d-week stand-down." % [
				allowance_weekly, allowance_stand_down_weeks])
		"accom_only":
			allowance_status = "declined"
			allowance_weekly = 0.0
			accommodation_benefit_weekly = ACCOM_BENEFIT_WEEKLY
			allowance_decline_reason = "Your parents' combined income is above the Student Allowance threshold. You have been granted the Accommodation Benefit instead, at $%.0f a week." % ACCOM_BENEFIT_WEEKLY
			log_event("Allowance declined, but the Accommodation Benefit was granted at $%.0f a week." % ACCOM_BENEFIT_WEEKLY)
		"incomplete":
			allowance_status = "declined"
			allowance_weekly = 0.0
			allowance_decline_reason = "Your parents never completed their section."
			log_event("Student Allowance declined — incomplete application.")
		_:
			allowance_status = "declined"
			allowance_weekly = 0.0
			allowance_decline_reason = "Your parents' combined income is above the threshold for a Student Allowance."
			log_event("Student Allowance declined — parental income above the threshold.")

	deliver_message("allowance_result")
	stats_changed.emit()


## Mid-year reassessment. StudyLink does this for real, and it is how people
## on a partial rate discover their payments have changed without warning.
func _maybe_review_allowance() -> void:
	if allowance_reviewed or allowance_status != "approved":
		return
	# Only once, and only if there's a decent run left to feel it.
	if days_remaining > TOTAL_DAYS / 3 or days_remaining < 10:
		return
	allowance_reviewed = true

	var roll: float = randf()
	if roll < 0.35:
		# A parent picked up more hours.
		var before: float = allowance_weekly
		allowance_weekly = maxf(0.0, round(allowance_weekly * randf_range(0.4, 0.75)))
		if allowance_weekly <= 0.0:
			allowance_status = "declined"
			allowance_decline_reason = "Reassessed mid-year: your parents' income has risen above the threshold."
			log_event("Allowance STOPPED after a mid-year review.")
		else:
			log_event("Allowance reduced at the mid-year review, $%.0f down to $%.0f a week." % [
				before, allowance_weekly])
		deliver_message("allowance_review")
	elif roll < 0.55:
		var before2: float = allowance_weekly
		allowance_weekly = minf(ALLOWANCE_FULL_WEEKLY, round(allowance_weekly * randf_range(1.2, 1.6)))
		log_event("Allowance increased at the mid-year review, $%.0f up to $%.0f a week." % [
			before2, allowance_weekly])
		deliver_message("allowance_review")
	# Otherwise nothing changes and you never hear about it, which is also
	# what usually happens.
	stats_changed.emit()


func _pay_allowance() -> void:
	if allowance_status != "approved" or allowance_weekly <= 0.0:
		return
	var elapsed: int = get_elapsed_days()
	if elapsed <= 0 or elapsed % 7 != 0:
		return
	# Serve out the stand-down first: entitled, approved, and still not being
	# paid for a few weeks.
	if allowance_stand_down_weeks > 0:
		allowance_stand_down_weeks -= 1
		log_event("Allowance stand-down: %d week%s to go before payments start." % [
			allowance_stand_down_weeks,
			"" if allowance_stand_down_weeks == 1 else "s"])
		stats_changed.emit()
		return
	money += allowance_weekly
	allowance_received += allowance_weekly
	log_event("Student Allowance paid: $%.2f (not repayable)" % allowance_weekly)
	stats_changed.emit()


## The smaller supplement, paid to people who missed out on the allowance
## itself but are living away from home.
func _pay_accommodation_benefit() -> void:
	if accommodation_benefit_weekly <= 0.0:
		return
	var elapsed: int = get_elapsed_days()
	if elapsed <= 0 or elapsed % 7 != 0:
		return
	money += accommodation_benefit_weekly
	allowance_received += accommodation_benefit_weekly
	log_event("Accommodation Benefit paid: $%.2f" % accommodation_benefit_weekly)
	stats_changed.emit()


func allowance_status_text() -> String:
	match allowance_status:
		"none":
			return "No application. The allowance is means-tested but it is not repaid — worth applying even if you expect a no."
		"submitted":
			if not parents_confirmed_income:
				return "WAITING ON YOUR PARENTS. They have to complete their section before anything is assessed — it's been %d day%s. Text them." % [
					allowance_waiting_days, "" if allowance_waiting_days == 1 else "s"]
			return "Being assessed. Decision in %d day%s." % [allowance_days_left, "" if allowance_days_left == 1 else "s"]
		"approved":
			var rate_note: String = " (full rate)" if allowance_weekly >= ALLOWANCE_FULL_WEEKLY else " (reduced rate — your parents are over the full-rate threshold)"
			var stand: String = ""
			if allowance_stand_down_weeks > 0:
				stand = "  STAND-DOWN: payments start in %d week%s." % [
					allowance_stand_down_weeks, "" if allowance_stand_down_weeks == 1 else "s"]
			return "APPROVED at $%.0f a week%s.%s Received so far: $%.2f — none of it repayable." % [
				allowance_weekly, rate_note, stand, allowance_received]
		"declined":
			if accommodation_benefit_weekly > 0.0:
				return "Allowance DECLINED — %s\n\nAccommodation Benefit is being paid at $%.0f a week. Received so far: $%.2f." % [
					allowance_decline_reason, accommodation_benefit_weekly, allowance_received]
			return "DECLINED — %s" % allowance_decline_reason
	return allowance_status


# =============================================================================
# ACCOMMODATION
# =============================================================================
# Where you're actually going to live next year. Applications run alongside
# the academic one and close before it — every year people get an offer and
# then find there's nowhere to sleep.

const ACCOMMODATION: Dictionary = {
	"halls": {
		"label": "Catered halls of residence",
		"deposit": 500.0,
		"year_cost": 18500.0,
		"blurb": "A room, three meals a day and a hundred other first-years in the same boat. The expensive option, and the one that makes the first year socially survivable.",
	},
	"flat": {
		"label": "Flatting",
		"deposit": 900.0,
		"year_cost": 11000.0,
		"blurb": "Cheaper, and you cook, clean and chase a landlord. Bond is due up front, which is why the deposit is higher than halls.",
	},
	"home": {
		"label": "Stay at home and commute",
		"deposit": 0.0,
		"year_cost": 1200.0,
		"blurb": "Free rent, no bond, and a long bus ride twice a day. Cheapest by a mile if the campus is close enough to your town.",
	},
}

## "" | "halls" | "flat" | "home"
var accommodation_choice: String = ""
var accommodation_deposit_paid: bool = false
var ACCOM_APPLY_CLOSES_DAY: int = 82


func accommodation_applications_open() -> bool:
	return get_elapsed_days() < ACCOM_APPLY_CLOSES_DAY


## Records a preference. The deposit is only taken when you confirm it.
func choose_accommodation(kind: String) -> Array:
	if not ACCOMMODATION.has(kind):
		return [false, "Unknown accommodation option."]
	if not accommodation_applications_open():
		return [false, "Accommodation applications for next year have closed."]
	if accommodation_choice == kind:
		return [false, "That's already your preference."]
	# Changing your mind after paying means forfeiting what you paid, same as
	# the real thing.
	if accommodation_deposit_paid:
		accommodation_deposit_paid = false
		log_event("Changed accommodation preference — the deposit is not refunded.")
	accommodation_choice = kind
	log_event("Accommodation preference set to: %s" % str(ACCOMMODATION[kind].label))
	stats_changed.emit()
	return [true, "Preference recorded. It isn't confirmed until the deposit is paid."]


func confirm_accommodation() -> Array:
	if accommodation_choice == "":
		return [false, "Choose an option first."]
	if accommodation_deposit_paid:
		return [false, "Already confirmed."]
	var deposit: float = ACCOMMODATION[accommodation_choice].get("deposit", 0.0)
	if deposit > money:
		return [false, "You need $%.0f for the deposit and you have $%.2f." % [deposit, money]]
	money -= deposit
	accommodation_deposit_paid = true
	log_event("Paid a $%.0f accommodation deposit for %s." % [deposit, str(ACCOMMODATION[accommodation_choice].label)])
	stats_changed.emit()
	return [true, "Confirmed. $%.0f deposit paid." % deposit]


func accommodation_status_text() -> String:
	if accommodation_choice == "":
		if accommodation_applications_open():
			return "No preference recorded. Applications close on day %d." % ACCOM_APPLY_CLOSES_DAY
		return "No preference recorded, and applications have closed."
	var data: Dictionary = ACCOMMODATION[accommodation_choice]
	if accommodation_deposit_paid:
		return "%s — CONFIRMED (deposit paid)." % str(data.label)
	return "%s — preference recorded but NOT confirmed. Deposit of $%.0f still to pay." % [
		str(data.label), data.get("deposit", 0.0)]


## Submit the StudyLink application. Returns [ok, message].
func apply_for_student_loan(ird: String, want_fees: bool, want_living: bool) -> Array:
	if loan_status == "submitted":
		return [false, "You already have an application being processed."]
	if loan_status == "approved":
		return [false, "Your loan is already approved."]
	if not want_fees and not want_living:
		return [false, "You have to apply for at least one part of the loan."]

	var cleaned: String = ird.strip_edges().replace("-", "").replace(" ", "")
	if cleaned.length() < 8 or not cleaned.is_valid_int():
		return [false, "That IRD number doesn't look right. It should be 8 or 9 digits."]

	loan_ird_number = cleaned
	loan_wants_fees = want_fees
	loan_wants_living_costs = want_living
	loan_days_left = LOAN_PROCESSING_DAYS
	loan_decline_reason = ""

	if not loan_applications_open():
		# Late applications are still accepted — they just don't come back
		# in time to be any use, which is the actual failure mode.
		loan_status = "submitted"
		loan_decline_reason = "Application received after the cut-off for this academic year."
		log_event("Applied to StudyLink — but applications for this year closed a while ago.")
		stats_changed.emit()
		return [true, "Submitted. Note: applications for this academic year closed on day %d." % LOAN_APPLY_CLOSES_DAY]

	loan_status = "submitted"
	log_event("Applied to StudyLink for a student loan. Decision in about %d days." % LOAN_PROCESSING_DAYS)
	stats_changed.emit()
	return [true, "Application submitted. StudyLink will be in touch in about %d days." % LOAN_PROCESSING_DAYS]


## Ticked once per day from advance_day().
func _tick_loan_application() -> void:
	if loan_status != "submitted":
		return
	loan_days_left -= 1
	if loan_days_left > 0:
		return

	if loan_decline_reason != "":
		loan_status = "declined"
		log_event("StudyLink declined your application: %s" % loan_decline_reason)
		deliver_message("studylink_declined")
	else:
		loan_status = "approved"
		log_event("StudyLink approved your student loan.")
		deliver_message("studylink_approved")
	stats_changed.emit()


## Weekly living-costs payment, if that part was approved and switched on.
func _pay_loan_living_costs() -> void:
	if loan_status != "approved" or not loan_wants_living_costs:
		return
	var elapsed: int = get_elapsed_days()
	if elapsed <= 0 or elapsed % 7 != 0:
		return
	money += LOAN_LIVING_COSTS_WEEKLY
	loan_debt += LOAN_LIVING_COSTS_WEEKLY
	log_event("StudyLink living costs paid: $%.2f (total borrowed $%.2f)" % [
		LOAN_LIVING_COSTS_WEEKLY, loan_debt])
	stats_changed.emit()


## Turn the weekly living-costs payments on or off after approval.
func set_living_costs(enabled: bool) -> void:
	if loan_status != "approved":
		return
	loan_wants_living_costs = enabled
	stats_changed.emit()


func loan_status_text() -> String:
	match loan_status:
		"none":
			if loan_applications_open():
				return "No application. Applications close on day %d." % LOAN_APPLY_CLOSES_DAY
			return "No application — and applications for this year have closed."
		"submitted":
			return "Being processed. Decision in %d day%s." % [loan_days_left, "" if loan_days_left == 1 else "s"]
		"approved":
			var parts: Array = []
			if loan_wants_fees:
				parts.append("course fees")
			if loan_wants_living_costs:
				parts.append("living costs ($%.0f/week)" % LOAN_LIVING_COSTS_WEEKLY)
			return "APPROVED — %s. Borrowed so far: $%.2f" % [", ".join(parts) if not parts.is_empty() else "nothing selected", loan_debt]
		"declined":
			return "DECLINED — %s" % loan_decline_reason
	return loan_status


## Can a loan actually pay this year's fees at enrolment?
func loan_covers_fees() -> bool:
	return loan_status == "approved" and loan_wants_fees


# --- NCEA credits & University Entrance ----------------------------------------
# The real UE requirement is NCEA Level 3, 14 credits in each of three
# approved subjects, plus 10 literacy and 10 numeracy credits.
#
# In this game literacy and numeracy are ALREADY DONE — you sat those in Year
# 12, like almost everyone actually does, and they carry over. They're tracked
# below so the NZQA page can show them as met, but they are not something you
# can fail this year. The only thing standing between you and UE is 14 credits
# in three of your subjects.
#
# CREDITS COME FROM INTERNALS ONLY. Not from studying at a desk, not from the
# laptop, not from chatting to a teacher. Sitting the assessment is the only
# thing that banks a credit — which is exactly how it works.

var UE_CREDITS_PER_SUBJECT: int = 14
var UE_SUBJECTS_REQUIRED: int = 3
## Carried in from Year 12. Kept as numbers so the portal can display them,
## but never a barrier — see has_university_entrance().
var UE_LITERACY_REQUIRED: int = 10
var UE_NUMERACY_REQUIRED: int = 10

## Flip to true if you'd rather externals awarded credits too, as real NCEA
## externals do. Left false because internals are the credit engine here and
## externals are what set your final grade.
const EXTERNALS_AWARD_CREDITS: bool = false

## Subjects that count toward the literacy / numeracy requirements.
const LITERACY_SUBJECTS := ["english", "history", "geography", "economics", "media_studies"]
const NUMERACY_SUBJECTS := ["maths", "statistics", "physics", "chemistry", "digital_technologies"]

## subject -> credits earned. Populated when the major is chosen.
var subject_credits: Dictionary = {}

# =============================================================================
# PREPAREDNESS  —  what studying is actually FOR
# =============================================================================
# Studying at a desk or on the laptop no longer moves your grade and never
# gives you credits. What it does is make you READY, which is the honest
# version: an evening of past papers doesn't add marks to a piece of paper you
# haven't sat yet.
#
# Preparedness does two things:
#   1. It tells you what you'd probably get — predicted_band() — so revision
#      gives you information rather than a number going up.
#   2. It buys you 50/50 eliminations in the actual assessment, one per
#      PREP_PER_HINT points. Being prepared makes the paper easier, which is
#      the only way it should ever help.
#
# It also fades. Skip a subject for a fortnight and you'll feel it.

## subject -> 0..100 readiness.
var subject_prep: Dictionary = {}
## Preparedness lost per day, per subject.
const PREP_DECAY_PER_DAY: float = 1.2
## How much preparedness buys one 50/50 elimination in an assessment.
const PREP_PER_HINT: float = 30.0
## Ceiling on eliminations, so a fully-prepped student still sits the paper.
const MAX_HINTS: int = 3


func change_prep(subject: String, amount: float) -> void:
	subject_prep[subject] = clampf(subject_prep.get(subject, 0.0) + amount, 0.0, 100.0)
	stats_changed.emit()


func get_prep(subject: String) -> float:
	return subject_prep.get(subject, 0.0)


## How many wrong answers get struck out for you in this subject's assessment.
func hints_for(subject: String) -> int:
	return mini(MAX_HINTS, int(get_prep(subject) / PREP_PER_HINT))


## What you'd probably get if you sat it right now. Deliberately vague at low
## preparedness — if you haven't revised, you genuinely don't know.
func predicted_band(subject: String) -> String:
	var prep: float = get_prep(subject)
	if prep < 15.0:
		return "no idea"
	if prep < 35.0:
		return "shaky — Not Achieved likely"
	if prep < 55.0:
		return "borderline Achieved"
	if prep < 75.0:
		return "comfortable Achieved"
	if prep < 90.0:
		return "Merit territory"
	return "Excellence territory"


## Plain-English readout for the desk, laptop and journal.
func prep_report(subject: String) -> String:
	return "%s — revision %.0f%%, %s. %s" % [
		str(subject).capitalize().replace("_", " "),
		get_prep(subject), predicted_band(subject),
		"No help in the exam yet." if hints_for(subject) == 0 else
		"%d wrong answer%s will be struck out for you." % [
			hints_for(subject), "" if hints_for(subject) == 1 else "s"]]


func _decay_prep() -> void:
	for subject in subject_prep:
		subject_prep[subject] = maxf(0.0, subject_prep[subject] - PREP_DECAY_PER_DAY)


# =============================================================================
# COMMITMENTS  —  saying yes and then not turning up
# =============================================================================
# Agreeing to a shift or a study session in conversation now BOOKS it. Miss it
# and something happens: Deb notices, Priya notices, and three no-shows at work
# means you are off the roster for the rest of the year.

## Array of {kind, label, day, id}
var commitments: Array = []
var work_no_shows: int = 0
var study_no_shows: int = 0
## Set true once you've been taken off the roster. No more shifts, no more pay.
var fired_from_work: bool = false
const WORK_NO_SHOWS_BEFORE_FIRED: int = 3


func add_commitment(kind: String, label: String, day: int) -> void:
	for c in commitments:
		if c.kind == kind and c.day == day:
			return   # already booked for that day
	commitments.append({"kind": kind, "label": label, "day": day})
	log_event("Agreed to: %s (day %d)." % [label, day])
	stats_changed.emit()


## Call this when the player actually does the thing. Returns true if it
## cleared a booking.
func fulfil_commitment(kind: String) -> bool:
	var today: int = get_elapsed_days()
	for i in range(commitments.size() - 1, -1, -1):
		var c: Dictionary = commitments[i]
		if c.kind == kind and c.day <= today:
			commitments.remove_at(i)
			change_sanity(5.0)
			log_event("Turned up: %s." % c.label)
			stats_changed.emit()
			return true
	return false


func has_commitment_today(kind: String) -> bool:
	var today: int = get_elapsed_days()
	for c in commitments:
		if c.kind == kind and c.day == today:
			return true
	return false


func commitments_today() -> Array:
	var today: int = get_elapsed_days()
	var out: Array = []
	for c in commitments:
		if c.day == today:
			out.append(c)
	return out


## Anything booked for a day that has now passed is a no-show.
func _check_missed_commitments() -> void:
	var today: int = get_elapsed_days()
	for i in range(commitments.size() - 1, -1, -1):
		var c: Dictionary = commitments[i]
		if c.day >= today:
			continue
		commitments.remove_at(i)
		match str(c.kind):
			"work":
				work_no_shows += 1
				change_sanity(-10.0)
				if work_no_shows >= WORK_NO_SHOWS_BEFORE_FIRED and not fired_from_work:
					fired_from_work = true
					log_event("No-showed a third shift. Deb has taken you off the roster.")
					deliver_message("work_fired")
				else:
					log_event("Missed a shift without telling anyone. (%d of %d)" % [
						work_no_shows, WORK_NO_SHOWS_BEFORE_FIRED])
					deliver_message("work_noshow")
			"study_group":
				study_no_shows += 1
				change_sanity(-6.0)
				log_event("Said you'd be at the study group and weren't.")
				deliver_message("study_group_noshow")
			_:
				change_sanity(-4.0)
				log_event("Missed: %s." % c.label)
		stats_changed.emit()
var literacy_credits: int = 0
var numeracy_credits: int = 0


# --- Run statistics, purely so the ending can describe your year -------------
var stat_study_sessions: int = 0
var stat_study_hours: float = 0.0
var stat_shifts: int = 0
var stat_work_hours: float = 0.0
var stat_earned: float = 0.0
var stat_exams_sat: int = 0
var stat_exams_missed: int = 0
var stat_nights_slept: int = 0
var stat_meals_cooked: int = 0
var stat_conversations: int = 0
var stat_messages_replied: int = 0
var stat_lowest_sanity: float = 100.0
var stat_doomscrolls: int = 0


func award_credits(subject: String, amount: int) -> void:
	if amount <= 0:
		return
	subject_credits[subject] = subject_credits.get(subject, 0) + amount
	if subject in LITERACY_SUBJECTS:
		literacy_credits += amount
	if subject in NUMERACY_SUBJECTS:
		numeracy_credits += amount
	stats_changed.emit()


func total_credits() -> int:
	var total: int = 0
	for v in subject_credits.values():
		total += v
	return total


## How many subjects have hit the 14-credit threshold.
func subjects_meeting_credit_threshold() -> int:
	var count: int = 0
	for v in subject_credits.values():
		if v >= UE_CREDITS_PER_SUBJECT:
			count += 1
	return count


## Literacy and numeracy were banked in Year 12, so the only live requirement
## is the 14-credits-in-three-subjects one.
func has_university_entrance() -> bool:
	return subjects_meeting_credit_threshold() >= UE_SUBJECTS_REQUIRED


## Human-readable breakdown for the Journal / ending screen.
func ue_status_text() -> String:
	var lines: Array = []
	lines.append("Subjects with %d+ credits: %d / %d" % [
		UE_CREDITS_PER_SUBJECT, subjects_meeting_credit_threshold(), UE_SUBJECTS_REQUIRED])
	lines.append("Literacy: %d / %d — carried over from Year 12" % [literacy_credits, UE_LITERACY_REQUIRED])
	lines.append("Numeracy: %d / %d — carried over from Year 12" % [numeracy_credits, UE_NUMERACY_REQUIRED])
	lines.append("Total credits: %d" % total_credits())
	return "\n".join(lines)


## Exactly which requirement(s) you fell short on. This is what the NZQA
## portal on the laptop shows you, rather than a bare "not achieved".
func ue_shortfall_reasons() -> Array:
	var reasons: Array = []
	var subs: int = subjects_meeting_credit_threshold()
	if subs < UE_SUBJECTS_REQUIRED:
		reasons.append("You have %d subject%s at %d+ Level 3 credits. University Entrance needs %d." % [
			subs, "" if subs == 1 else "s", UE_CREDITS_PER_SUBJECT, UE_SUBJECTS_REQUIRED])
	# Literacy and numeracy came in from Year 12, so they never appear as a
	# shortfall — they're shown on the portal as met and left alone.
	return reasons


func _pretty_list(items: Array) -> String:
	var out: Array = []
	for s in items:
		out.append(str(s).capitalize().replace("_", " "))
	return ", ".join(out)


# --- Exams ---------------------------------------------------------------------
# Scheduled tests you must actually sit at school. Miss one and you take a
# heavy hit; pass and your grade jumps. These are the spine of the run: they
# turn "study a bit whenever" into "be ready by day X".

## Roughly one internal every this many days. Because internals are now the
## ONLY source of credits, this has to be frequent enough that five subjects
## can each reach 14: at 3 days that's ~25 internals, 5 per subject, 3-5
## credits each. Stretch it and UE stops being reachable.
var EXAM_INTERVAL_DAYS: int = 3
const EXAM_QUESTION_COUNT: int = 10
## How many days at the end of the year are reserved for externals.
var EXTERNALS_WINDOW_DAYS: int = 14
## Never timetable more than this many externals on one day.
const MAX_EXAMS_PER_DAY: int = 2
## How many days ahead the exam timetable notice appears.
const TIMETABLE_NOTICE_DAYS: int = 2
## Sitting a derived grade exam needs a decent reason; you get this many.
const DERIVED_GRADE_ALLOWANCE: int = 2
const EXAM_PASS_RATIO: float = 0.6   ## fraction correct needed to pass

## Array of {day:int, subject:String, taken:bool, passed:bool, kind, accuracy, result_released}
var exam_schedule: Array = []
## Spent when you sit a derived grade exam (used if you miss an external).
var derived_grades_left: int = DERIVED_GRADE_ALLOWANCE


## NCEA-style band from an accuracy fraction. Used everywhere results are
## reported so the wording is consistent.
static func band_for(accuracy: float) -> String:
	if accuracy >= 0.90:
		return "Excellence"
	if accuracy >= 0.78:
		return "Merit"
	if accuracy >= 0.60:
		return "Achieved"
	return "Not Achieved"


## Builds the exam timetable for the run. Called when the major is chosen, so
## exams are always for subjects you're actually studying.
func generate_exam_schedule() -> void:
	exam_schedule.clear()
	derived_grades_left = DERIVED_GRADE_ALLOWANCE
	if active_subjects.is_empty():
		return
	# Internals run through the year and you get the result straight away.
	# Externals sit at the very end and, like NCEA, stay sealed until results
	# day — you finish the paper with no idea how you went.
	var day: int = EXAM_INTERVAL_DAYS
	var i: int = 0
	while day < TOTAL_DAYS - EXTERNALS_WINDOW_DAYS:
		exam_schedule.append({
			"day": day,
			"subject": active_subjects[i % active_subjects.size()],
			"taken": false,
			"passed": false,
			"kind": "internal",
			"accuracy": 0.0,
			"result_released": true,
		})
		day += EXAM_INTERVAL_DAYS
		i += 1

	# Externals are timetabled like NZQA's: spread across the exam window,
	# never more than MAX_EXAMS_PER_DAY on the same day, and with gaps rather
	# than one solid block — so some days are doubles and some are free.
	var window_start: int = TOTAL_DAYS - EXTERNALS_WINDOW_DAYS
	var candidate_days: Array = []
	var d: int = window_start
	while d < TOTAL_DAYS - 1:
		candidate_days.append(d)
		d += 1
	candidate_days.shuffle()

	var subjects_to_place: Array = active_subjects.duplicate()
	subjects_to_place.shuffle()
	var per_day: Dictionary = {}   # day -> how many already booked

	for subject in subjects_to_place:
		var placed: bool = false
		# `exam_day` rather than `day` — the internals loop above already
		# uses `day` in this scope.
		for exam_day in candidate_days:
			if per_day.get(exam_day, 0) < MAX_EXAMS_PER_DAY:
				per_day[exam_day] = per_day.get(exam_day, 0) + 1
				exam_schedule.append({
					"day": exam_day,
					"subject": subject,
					"taken": false,
					"passed": false,
					"kind": "external",
					"accuracy": 0.0,
					"result_released": false,
				})
				placed = true
				break
		if not placed:
			# More subjects than the window can hold — extend into the last day.
			exam_schedule.append({
				"day": TOTAL_DAYS - 1,
				"subject": subject,
				"taken": false,
				"passed": false,
				"kind": "external",
				"accuracy": 0.0,
				"result_released": false,
			})

	# Keep the list in date order so the timetable reads correctly.
	exam_schedule.sort_custom(func(a, b): return a.day < b.day)

	journal_updated.emit()


## Every exam on a given day (0, 1 or 2 of them).
func exams_on_day(day: int) -> Array:
	var out: Array = []
	for exam in exam_schedule:
		if exam.day == day:
			out.append(exam)
	return out


## All exams still to sit today, respecting the two-a-day cap.
func exams_due_today() -> Array:
	var out: Array = []
	var today: int = get_elapsed_days()
	for exam in exam_schedule:
		if exam.day == today and not exam.taken:
			out.append(exam)
	return out


## True when we're close enough to an exam to post the timetable notice.
func should_show_timetable() -> bool:
	var days: int = days_until_next_exam()
	return days >= 0 and days <= TIMETABLE_NOTICE_DAYS


## The full external timetable as display rows, newest first by date.
## The timetable, as display rows. `kind` filters to internals or externals;
## pass "" for everything. The old version silently returned externals only,
## which is why the internal reminder opened a list the internal wasn't on.
func get_timetable(kind: String = "") -> Array:
	var rows: Array = []
	var today: int = get_elapsed_days()
	for exam in exam_schedule:
		var this_kind: String = str(exam.get("kind", "internal"))
		if kind != "" and this_kind != kind:
			continue
		rows.append({
			"day": exam.day,
			"subject": exam.subject,
			"taken": exam.taken,
			"kind": this_kind,
			"where": next_exam_location(this_kind),
			"days_away": exam.day - today,
		})
	rows.sort_custom(func(a, b): return a.day < b.day)
	return rows


## The next exam still to be sat, or {} if there are none left.
func get_next_exam() -> Dictionary:
	var elapsed: int = get_elapsed_days()
	for exam in exam_schedule:
		if not exam.taken and exam.day >= elapsed:
			return exam
	return {}


## Days until the next exam. -1 if none scheduled. 0 means it's today.
func days_until_next_exam() -> int:
	var nxt: Dictionary = get_next_exam()
	if nxt.is_empty():
		return -1
	return nxt.day - get_elapsed_days()


## The exam due today that hasn't been sat, or {} if there isn't one.
##
## `kind` filters to "internal" or "external". This matters more than it
## looks: internals are sat in class at SCHOOL, externals are sat in the EXAM
## HALL, and an unfiltered version of this function is why the school desks
## used to announce an exam that was actually happening across town.
func get_exam_due_today(kind: String = "") -> Dictionary:
	var elapsed: int = get_elapsed_days()
	for exam in exam_schedule:
		if exam.taken or exam.day != elapsed:
			continue
		if kind != "" and str(exam.get("kind", "internal")) != kind:
			continue
		return exam
	return {}


## Today's internal, sat in class at school.
func get_internal_due_today() -> Dictionary:
	return get_exam_due_today("internal")


## Today's external, sat in the exam hall.
func get_external_due_today() -> Dictionary:
	return get_exam_due_today("external")


## Every exam of a given kind still to sit today.
func exams_due_today_of_kind(kind: String) -> Array:
	var out: Array = []
	for exam in exams_due_today():
		if str(exam.get("kind", "internal")) == kind:
			out.append(exam)
	return out


## Where today's next exam actually happens, for the HUD banner.
func next_exam_location(kind: String) -> String:
	return "exam hall" if kind == "external" else "school"


## Called by the school scene once an exam has been sat.
func complete_exam(subject: String, correct: int, total: int) -> bool:
	var accuracy: float = 0.0 if total <= 0 else float(correct) / float(total)
	var passed: bool = accuracy >= EXAM_PASS_RATIO
	var kind: String = "internal"

	for exam in exam_schedule:
		if not exam.taken and exam.subject == subject and exam.day <= get_elapsed_days():
			exam.taken = true
			exam.passed = passed
			exam.accuracy = accuracy
			kind = exam.get("kind", "internal")
			break

	stat_exams_sat += 1

	if kind == "external":
		# Sealed until results day: no grade change, no credits, no feedback.
		# You walk out genuinely not knowing.
		_queue_hours(2.5)
		change_energy(-20.0)
		change_sanity(-6.0)
		change_thirst(-8.0)
		log_event("Sat the %s external. Results come out at the end of the year." % subject.capitalize())
		stats_changed.emit()
		return true   # "did you sit it", not "did you pass"

	# Internals are marked in class, so you know immediately.
	var swing: float = (accuracy - EXAM_PASS_RATIO) * 40.0
	subject_grades[subject] = clamp(subject_grades.get(subject, 50.0) + swing, 0.0, 100.0)

	# Internals are where every credit in this game comes from.
	var credits: int = 0
	if accuracy >= 0.90:
		credits = 5
	elif accuracy >= 0.78:
		credits = 4
	elif accuracy >= EXAM_PASS_RATIO:
		credits = 3
	award_credits(subject, credits)
	# Sitting the paper burns off some of your readiness for it — you've used
	# what you revised. It also leaves you knowing the subject better than a
	# fortnight ago, so this is a dip, not a wipe.
	change_prep(subject, -18.0)

	_queue_hours(2.0)
	change_energy(-18.0)
	change_sanity(10.0 if passed else -14.0)
	change_thirst(-8.0)

	log_event("%s internal: %d/%d — %s (%s, grade now %.0f)" % [
		subject.capitalize(), correct, total, band_for(accuracy),
		"passed" if passed else "failed", subject_grades[subject]])
	stats_changed.emit()
	return passed


## Results day. Applies every sealed external at once — this is where a year
## of externals finally lands on your grades and credits.
func release_external_results() -> void:
	var released: int = 0
	for exam in exam_schedule:
		if exam.get("kind", "") != "external" or exam.get("result_released", true):
			continue
		exam.result_released = true
		released += 1
		var subject: String = exam.subject
		if not exam.taken:
			# Never sat it, and no derived grade to fall back on.
			subject_grades[subject] = clamp(subject_grades.get(subject, 50.0) - 20.0, 0.0, 100.0)
			log_event("%s external: absent — grade dropped to %.0f." % [
				subject.capitalize(), subject_grades[subject]])
			continue
		var accuracy: float = exam.get("accuracy", 0.0)
		var swing: float = (accuracy - EXAM_PASS_RATIO) * 55.0   # externals hit harder
		subject_grades[subject] = clamp(subject_grades.get(subject, 50.0) + swing, 0.0, 100.0)
		var credits: int = 0
		if EXTERNALS_AWARD_CREDITS:
			if accuracy >= 0.90:
				credits = 6
			elif accuracy >= 0.78:
				credits = 5
			elif accuracy >= EXAM_PASS_RATIO:
				credits = 4
			award_credits(subject, credits)
		log_event("%s external: %s (%.0f%%) — grade now %.0f%s" % [
			subject.capitalize(), band_for(accuracy), accuracy * 100.0,
			subject_grades[subject],
			", %d credits" % credits if credits > 0 else " (externals set your grade, not your credits)"])
	if released > 0:
		stats_changed.emit()
		journal_updated.emit()


## Sit a derived grade exam for an external you couldn't attend. Uses your
## allowance and records a slightly discounted result, as NZQA derived grades
## are based on prior evidence rather than the paper itself.
func use_derived_grade(subject: String) -> bool:
	if derived_grades_left <= 0:
		return false
	for exam in exam_schedule:
		if exam.get("kind", "") == "external" and exam.subject == subject and not exam.taken:
			derived_grades_left -= 1
			exam.taken = true
			exam["derived"] = true
			# Derived from how you've been doing all year, not a fresh sitting.
			var evidence: float = clampf(subject_grades.get(subject, 50.0) / 100.0, 0.0, 1.0)
			exam.accuracy = clampf(evidence * 0.9, 0.0, 1.0)
			log_event("Applied for a derived grade in %s." % subject.capitalize())
			stats_changed.emit()
			return true
	return false


## Any exam whose day has passed without being sat is a hard fail. Called
## from advance_day() so skipping school has real consequences.
func _check_missed_exams() -> void:
	var elapsed: int = get_elapsed_days()
	for exam in exam_schedule:
		if exam.taken or exam.day >= elapsed:
			continue
		# Externals are handled by release_external_results() on results day,
		# so that a missed one still shows up as "absent" alongside the rest.
		if exam.get("kind", "internal") == "external":
			continue
		exam.taken = true
		exam.passed = false
		stat_exams_missed += 1
		subject_grades[exam.subject] = clamp(subject_grades.get(exam.subject, 50.0) - 15.0, 0.0, 100.0)
		change_sanity(-15.0)
		log_event("MISSED the %s internal — grade dropped to %.0f" % [
			exam.subject.capitalize(), subject_grades[exam.subject]])
		stats_changed.emit()


## Full per-subject results breakdown, with the reasoning behind each grade.
## This is what the NZQA portal on the laptop reads.
func subject_result_detail(subject: String) -> Dictionary:
	var internals: Array = []
	var externals: Array = []
	var today: int = get_elapsed_days()
	for exam in exam_schedule:
		if exam.subject != subject:
			continue
		# An exam that hasn't happened yet is UPCOMING, not absent. The first
		# version reported every future paper as "Absent", so the NZQA page
		# told you you'd missed five exams on day one.
		var upcoming: bool = not exam.taken and exam.day >= today
		var band: String = "Absent"
		if exam.taken:
			band = band_for(exam.get("accuracy", 0.0))
		elif upcoming:
			band = "Not yet sat"
		var row: Dictionary = {
			"day": exam.day,
			"taken": exam.taken,
			"upcoming": upcoming,
			"accuracy": exam.get("accuracy", 0.0),
			"band": band,
			"derived": exam.get("derived", false),
		}
		if exam.get("kind", "internal") == "external":
			externals.append(row)
		else:
			internals.append(row)

	var credits: int = subject_credits.get(subject, 0)
	var grade: float = subject_grades.get(subject, 0.0)

	# The "why" — spelled out rather than left for the player to reverse-engineer.
	var why: Array = []
	var sat: int = 0
	var absent: int = 0
	var upcoming_count: int = 0
	var excellences: int = 0
	for r in internals + externals:
		if r.taken:
			sat += 1
			if r.band == "Excellence":
				excellences += 1
		elif r.upcoming:
			upcoming_count += 1
		else:
			absent += 1

	if sat == 0 and absent == 0:
		why.append("Nothing assessed yet — %d paper%s still to sit." % [
			upcoming_count, "" if upcoming_count == 1 else "s"])
	if upcoming_count > 0 and sat > 0:
		why.append("%d paper%s still to sit, so this can still move." % [
			upcoming_count, "" if upcoming_count == 1 else "s"])
	if absent > 0:
		why.append("%d assessment%s missed — each absence costs credits and pulls the grade down." % [
			absent, "" if absent == 1 else "s"])
	if excellences > 0:
		why.append("%d Excellence result%s pushed both the grade and the credit count up." % [
			excellences, "" if excellences == 1 else "s"])
	if sat > 0 and excellences == 0 and absent == 0:
		why.append("Consistent attendance, no standout papers — a solid middle result.")
	if credits >= UE_CREDITS_PER_SUBJECT:
		why.append("%d credits: meets the %d needed for this subject to count toward UE." % [
			credits, UE_CREDITS_PER_SUBJECT])
	elif upcoming_count > 0:
		why.append("%d credits so far, %d short of the %d needed — %d paper%s left to earn them in." % [
			credits, UE_CREDITS_PER_SUBJECT - credits, UE_CREDITS_PER_SUBJECT,
			upcoming_count, "" if upcoming_count == 1 else "s"])
	else:
		why.append("%d credits: %d short of the %d this subject needs to count toward UE." % [
			credits, UE_CREDITS_PER_SUBJECT - credits, UE_CREDITS_PER_SUBJECT])
	if subject in LITERACY_SUBJECTS:
		why.append("Counts toward literacy.")
	if subject in NUMERACY_SUBJECTS:
		why.append("Counts toward numeracy.")

	return {
		"subject": subject,
		"grade": grade,
		"credits": credits,
		"internals": internals,
		"externals": externals,
		"why": why,
	}


# --- Journal -----------------------------------------------------------------
# Array of {day: int, text: String}. UI reads this directly; use log_event()
# to add to it so the day number and signal are always consistent.
var journal: Array = []

# --- Phone messages -----------------------------------------------------------
# Which threads have arrived, been read, and been completed. Persisting this
# on GameBackend means the inbox survives leaving and re-entering scenes.
## thread_id -> {arrived, read, done, day, step, log}
## `step` is how far through the conversation you are, and `log` is the
## transcript so far — both persisted so a thread resumes where you left it
## instead of restarting every time you open the app.
var message_state: Dictionary = {}
var unread_count: int = 0

signal messages_changed
## Fires the moment a new thread lands, so the notifier can pop a toast and
## the badges can update. Carries the contact name.
signal message_arrived(sender: String, thread_id: String)
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


## Sets the player's subjects for the year based on their chosen major.
## Called once from the major-select screen, right after choosing a university.
func set_major(major: String) -> void:
	if not MAJORS.has(major):
		push_warning("GameBackend: unknown major '%s'" % major)
		return
	selected_major = major
	active_subjects = MAJORS[major].duplicate()
	subject_grades = {}
	subject_credits = {}
	subject_prep = {}
	# Banked in Year 12 and carried forward, same as the real thing.
	literacy_credits = UE_LITERACY_REQUIRED
	numeracy_credits = UE_NUMERACY_REQUIRED
	for subject in active_subjects:
		subject_grades[subject] = 50.0
		subject_credits[subject] = 0
		subject_prep[subject] = 0.0
	generate_exam_schedule()
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


## How many consecutive days you've ended on empty. Hitting zero is a warning,
## not an execution — you get a day to sleep, eat, and talk to somebody before
## the run ends. Bottoming out should be a crisis you can climb out of.
var days_at_rock_bottom: int = 0
const DAYS_AT_ZERO_BEFORE_BURNOUT: int = 2


func change_sanity(amount: float) -> void:
	var was_above: bool = sanity > 0.0
	sanity = clamp(sanity + amount, 0.0, 100.0)
	stat_lowest_sanity = min(stat_lowest_sanity, sanity)
	stats_changed.emit()
	# The moment you first hit zero you get told, plainly, once.
	if was_above and sanity <= 0.0 and not game_over:
		log_event("You have nothing left. Sleep, eat, and talk to someone — today.")
		deliver_message("rock_bottom")


## Checked once per day rather than on every stat change, so a single bad
## afternoon can't end the run.
func _check_burnout() -> void:
	if game_over:
		return
	if sanity <= 0.0:
		days_at_rock_bottom += 1
		if days_at_rock_bottom >= DAYS_AT_ZERO_BEFORE_BURNOUT:
			_end_game("bad_sanity")
	else:
		days_at_rock_bottom = 0


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
	if dev_no_decay:   # dev panel god mode; always false in a normal build
		return
	change_thirst(-hours * THIRST_BASE_DRAIN)

	# These used to be flat additions that all stacked, so the worst case was
	# roughly three times the base rate — which is where the unfair burnouts
	# were coming from. They're now a single multiplier with a hard ceiling,
	# so a bad day is meaningfully worse than a good one without being
	# unsurvivable.
	var pressure: float = 1.0
	if energy < 25.0:
		pressure += 0.35
	if thirst < 25.0:
		pressure += 0.35
	pressure += (temptation / 100.0) * 0.4

	var days_to_exam: int = days_until_next_exam()
	if days_to_exam >= 0 and days_to_exam <= 2:
		pressure += 0.3

	var uni: Dictionary = universities.get(selected_university, {})
	if get_overall_grade() < uni.get("grades_needed", 0) - 15.0:
		pressure += 0.2

	# Never more than double the base rate, whatever else is going on.
	pressure = minf(pressure, 2.0)
	change_sanity(-hours * SANITY_BASE_DRAIN * pressure)


## Called once per in-game day. Ticks the deadline down and checks whether
## the year is over.
func advance_day() -> void:
	if game_over:
		return
	# Once results are out the normal countdown stops; we just step through
	# the results -> offer sequence one day at a time.
	if results_phase == 1:
		release_university_offer()
		return
	if results_phase == 2:
		return

	days_remaining -= 1
	_apply_daily_banking()
	_tick_loan_application()
	_pay_loan_living_costs()
	_tick_allowance()
	_pay_allowance()
	_pay_accommodation_benefit()
	_maybe_review_allowance()
	_decay_prep()
	_check_missed_commitments()
	_check_missed_exams()
	_check_burnout()
	# Messages scheduled for this day land now.
	if has_node("/root/MessageData"):
		get_node("/root/MessageData").deliver_due_messages(get_elapsed_days())
	if days_remaining <= 0:
		days_remaining = 0
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


## Grade needed for your chosen university, plus any conjoint surcharge, plus
## a penalty for any subject the programme expects that you aren't taking.
func required_grade() -> float:
	var uni: Dictionary = universities.get(selected_university, {})
	var req: float = uni.get("grades_needed", 0)
	if selected_conjoint != "" and CONJOINTS.has(selected_conjoint):
		req += CONJOINTS[selected_conjoint].get("grade_bonus_required", 0.0)
	# Switching to a programme your subject line-up doesn't support is
	# allowed, but universities compensate by wanting a stronger average.
	req += float(missing_required_subjects().size()) * MISSING_SUBJECT_PENALTY
	return req


# =============================================================================
# CHANGING YOUR MIND
# =============================================================================
# Your university and programme preference are a PREFERENCE, not a contract.
# Real applicants change them, often more than once. What you can't change is
# your subjects — you picked those in year 12 and you're stuck with them,
# which is exactly why switching to a programme you have no subjects for
# costs you something.

## Extra average required per expected subject you aren't taking.
const MISSING_SUBJECT_PENALTY: float = 5.0
## How many times the preference has been changed, purely for flavour.
var preference_changes: int = 0


## The subjects the currently-selected programme expects.
func programme_required_subjects() -> Array:
	if selected_conjoint != "" and CONJOINTS.has(selected_conjoint):
		return (CONJOINTS[selected_conjoint].get("subjects", []) as Array).duplicate()
	if MAJORS.has(selected_major):
		return (MAJORS[selected_major] as Array).duplicate()
	return []


## Expected subjects you are NOT taking. Empty at the start of every run,
## because set_major() gives you exactly the programme's subjects.
func missing_required_subjects() -> Array:
	var out: Array = []
	for subject in programme_required_subjects():
		if not subject in active_subjects:
			out.append(subject)
	return out


## Preferences are locked once results are released — at that point the
## decision is already being made.
func can_change_preference() -> bool:
	return results_phase == 0 and not game_over


func change_university(uni_name: String) -> Array:
	if not can_change_preference():
		return [false, "Preferences are locked once results have been released."]
	if not universities.has(uni_name):
		return [false, "Unknown university."]
	if uni_name == selected_university:
		return [false, "That's already your first preference."]
	var previous: String = selected_university
	selected_university = uni_name
	preference_changes += 1
	log_event("Changed first preference from %s to %s." % [previous, uni_name])
	stats_changed.emit()
	return [true, "First preference updated to %s." % university_full_name()]


## Change programme. Your SUBJECTS do not change — you can't un-take a year of
## school — so a badly matched switch raises the average you'll need.
func change_programme(programme: String) -> Array:
	if not can_change_preference():
		return [false, "Preferences are locked once results have been released."]

	if CONJOINTS.has(programme):
		selected_conjoint = programme
		selected_major = programme
	elif MAJORS.has(programme):
		selected_conjoint = ""
		selected_major = programme
	else:
		return [false, "Unknown programme."]

	preference_changes += 1
	var missing: Array = missing_required_subjects()
	log_event("Changed programme to %s." % programme)
	stats_changed.emit()

	if missing.is_empty():
		return [true, "Programme updated to %s. Your subjects cover it." % programme]
	return [true, "Programme updated to %s.\n\nYou are not taking %s, which this programme expects. Entry average raised by %.0f." % [
		programme, _pretty_list(missing), float(missing.size()) * MISSING_SUBJECT_PENALTY]]


## Results day. Externals are marked and pushed to the phone; the university
## decision follows a day later, mirroring how it actually works.
func _check_deadline_ending() -> void:
	if game_over:
		return
	if results_phase != 0:
		return   # already in the results run-out

	release_external_results()
	results_phase = 1
	deliver_message("nzqa_results")
	log_event("NCEA results released — check your phone or the NZQA site on your laptop.")
	messages_changed.emit()
	stats_changed.emit()


## Called on the day after results. Sends the offer, but does NOT end the run —
## the ending fires when the player actually opens and reads that message.
func release_university_offer() -> void:
	if results_phase != 1:
		return
	results_phase = 2
	deliver_message("university_offer")
	log_event("A decision on your university application has arrived.")
	messages_changed.emit()


## The player has read their offer. Now the year closes.
func acknowledge_offer() -> void:
	if game_over:
		return
	_end_game(pending_ending_result())


## Works out which ending applies, without committing to it — so the offer
## message, the laptop portal and the ending screen always agree.
##
## Priority order matters: University Entrance is the hard gate — without it,
## grades and savings don't matter, which is how it actually works under NZQA.
func pending_ending_result() -> String:
	var uni: Dictionary = universities.get(selected_university, {})
	var money_needed: float = uni.get("money_needed", 0)
	var grade: float = get_overall_grade()
	var req: float = required_grade()

	if not has_university_entrance():
		return "no_ue"
	if sanity <= SANITY_DEFER_THRESHOLD and grade >= req:
		return "deferred"
	if grade >= 90.0 and grade >= req:
		return "scholarship"
	if grade >= req and money >= money_needed:
		return "good"
	if grade >= req and loan_covers_fees():
		return "student_loan"
	if grade >= req:
		# Earned the place, can't pay for it, and never got a loan sorted.
		return "unfunded"
	if grade >= req - 8.0:
		return "second_choice"
	if grade >= req - 20.0:
		return "foundation_year"
	return "bad_deadline"


## The text shown in the university offer message on your phone.
##
## NOTE ON `_`:  in a GDScript `match` block, `_` is the wildcard pattern —
## "anything not matched above". It is match's version of `default:` in a
## C/Java switch, or `else` on an if-chain. It is NOT a string called "_",
## and it is NOT specific to bad_deadline; every unlisted result lands here.
## Because relying on that made it unclear, "bad_deadline" now has its own
## explicit case below and `_` is only a genuine catch-all safety net.
func offer_message() -> String:
	var uni_name: String = university_full_name()
	match pending_ending_result():
		"scholarship":
			return "CONGRATULATIONS. You have been offered a place at %s, with a scholarship covering your tuition fees in full." % uni_name
		"good":
			return "CONGRATULATIONS. You have been offered a place at %s. Your fees are covered by your own savings." % uni_name
		"student_loan":
			return "You have been offered a place at %s. StudyLink has confirmed your student loan will cover this year's fees." % uni_name
		"unfunded":
			return "You have been offered a place at %s. However, we have no record of an approved StudyLink loan, and your savings do not cover the fees. The offer cannot be taken up this year." % uni_name
		"deferred":
			return "You have been offered a place at %s, deferred by one year at your request." % uni_name
		"second_choice":
			return "%s was unable to offer you a place. However, another university has offered you one." % uni_name
		"foundation_year":
			return "%s has offered you a place on a foundation programme, with entry to the degree next year." % uni_name
		"no_ue":
			return "We are unable to make you an offer. University Entrance was not achieved."
		"bad_deadline":
			return "We regret that %s is unable to offer you a place this year." % uni_name
		_:
			# Genuine catch-all. If you add a new ending id and forget to add
			# a case above, you get this rather than a blank message.
			return "A decision has been made on your application to %s. Please check the applicant portal." % uni_name


## Plain-English reasons for the decision, shown in the applicant portal on
## the laptop. This is the "why did I get that result" the offer text doesn't
## have room for.
func offer_reasons() -> Array:
	var uni: Dictionary = universities.get(selected_university, {})
	var money_needed: float = uni.get("money_needed", 0)
	var grade: float = get_overall_grade()
	var req: float = required_grade()
	var reasons: Array = []

	if not has_university_entrance():
		reasons.append("University Entrance was NOT achieved. This is a hard requirement — no degree programme can admit you without it.")
		reasons.append_array(ue_shortfall_reasons())
		return reasons

	reasons.append("University Entrance: ACHIEVED (%d subjects at %d+ credits, %d literacy, %d numeracy)." % [
		subjects_meeting_credit_threshold(), UE_CREDITS_PER_SUBJECT, literacy_credits, numeracy_credits])

	var missing: Array = missing_required_subjects()
	if not missing.is_empty():
		reasons.append("You are not taking %s, which this programme expects. That raised the entry average by %.0f." % [
			_pretty_list(missing), float(missing.size()) * MISSING_SUBJECT_PENALTY])

	if grade >= req:
		reasons.append("Academic average %.0f meets the %.0f required for %s%s." % [
			grade, req, selected_major if selected_major != "" else "your programme",
			" (conjoint surcharge included)" if selected_conjoint != "" else ""])
	else:
		reasons.append("Academic average %.0f is %.0f short of the %.0f required." % [grade, req - grade, req])

	if sanity <= SANITY_DEFER_THRESHOLD and grade >= req:
		reasons.append("You asked to defer. You finished the year on %.0f%% wellbeing — starting first year in that state was not realistic." % sanity)

	if grade >= req:
		if money >= money_needed:
			reasons.append("Fees of $%.0f are covered by your savings of $%.0f." % [money_needed, money])
		elif loan_covers_fees():
			reasons.append("Fees of $%.0f are covered by your approved StudyLink loan. Total borrowed: $%.2f." % [money_needed, loan_debt + money_needed])
		else:
			reasons.append("Fees of $%.0f are NOT covered. You have $%.0f saved and %s." % [
				money_needed, money,
				"no approved student loan" if loan_status != "approved" else "a loan that does not include the fees component"])
			if allowance_status == "approved":
				reasons.append("Your Student Allowance of $%.0f a week helped, but an allowance covers living costs, not tuition." % allowance_weekly)
			match loan_status:
				"none":
					reasons.append("You never submitted a StudyLink application. Applications for this year closed on day %d." % LOAN_APPLY_CLOSES_DAY)
				"submitted":
					reasons.append("Your StudyLink application was still being processed when enrolment closed.")
				"declined":
					reasons.append("StudyLink declined your application: %s" % loan_decline_reason)
				"approved":
					reasons.append("Your loan was approved for living costs only — you didn't tick the course fees box.")
	return reasons


func _end_game(result: String) -> void:
	if game_over:
		return
	game_over = true
	ending_result = result
	log_event("--- The year is over. ---" if result != "bad_sanity" else "--- Burnout. ---")
	game_ended.emit(result)


# =============================================================================
# EPILOGUE — the closing text on the ending screen.
# =============================================================================
# The word you were reaching for is "epilogue" (you'll also see it called a
# post-game summary, a run recap, or a denouement). It's the bit after the
# result that tells you what your year actually looked like.

## A few paragraphs describing how this particular run went. Built from the
## run statistics above, so no two playthroughs read the same.
func build_epilogue() -> String:
	var paras: Array = []

	# 1. How you spent the year.
	var effort: Array = []
	if stat_study_sessions > 0:
		effort.append("%d study session%s (%.0f hours at a desk)" % [
			stat_study_sessions, "" if stat_study_sessions == 1 else "s", stat_study_hours])
	if stat_shifts > 0:
		effort.append("%d shift%s at the supermarket, %.0f hours for $%.0f" % [
			stat_shifts, "" if stat_shifts == 1 else "s", stat_work_hours, stat_earned])
	if stat_conversations > 0:
		effort.append("%d proper conversation%s with people who noticed you were struggling" % [
			stat_conversations, "" if stat_conversations == 1 else "s"])
	if effort.is_empty():
		paras.append("Ninety days went past and you have almost nothing to show for them.")
	else:
		paras.append("Across ninety days you managed " + _join_natural(effort) + ".")

	# 2. Exams.
	if stat_exams_missed == 0 and stat_exams_sat > 0:
		paras.append("You sat every single assessment you were timetabled for. %d of them. That alone puts you ahead of half the cohort." % stat_exams_sat)
	elif stat_exams_missed > 0:
		paras.append("You sat %d assessments and missed %d. The missed ones are the ones you'll think about." % [stat_exams_sat, stat_exams_missed])

	# 3. Wellbeing.
	if stat_lowest_sanity <= 15.0:
		paras.append("There was a stretch where you were genuinely running on nothing — you bottomed out at %.0f%%. You got through it, but not gracefully." % stat_lowest_sanity)
	elif stat_lowest_sanity <= 40.0:
		paras.append("It got heavy around the middle of the year. You dipped to %.0f%% and pulled back out of it." % stat_lowest_sanity)
	else:
		paras.append("Remarkably, you kept your head above water the whole way — you never dropped below %.0f%%." % stat_lowest_sanity)

	if temptation >= 65.0:
		paras.append("You also spent a lot of the year not doing the thing you were supposed to be doing. %d refreshes of a feed that never had anything new on it." % stat_doomscrolls)

	# 4. Money and the loan.
	match loan_status:
		"approved":
			paras.append("StudyLink came through. You start next year owing $%.2f, which is a problem for a future version of you." % (loan_debt + (universities.get(selected_university, {}).get("money_needed", 0) if loan_covers_fees() and ending_result == "student_loan" else 0.0)))
		"declined":
			paras.append("StudyLink said no. %s" % loan_decline_reason)
		"submitted":
			paras.append("Your StudyLink application was still sitting in a queue somewhere when the year ended.")
		"none":
			paras.append("You never got round to applying to StudyLink. It was always a next-week job.")

	# 4b. Accommodation and the allowance.
	if allowance_status == "approved":
		paras.append("The Student Allowance came through at $%.0f a week — $%.2f across the year that you will never have to pay back. Not everyone gets that, and it made a difference." % [
			allowance_weekly, allowance_received])
	elif allowance_status == "declined":
		paras.append("The Student Allowance was declined. %s That is how it works for most people, and it still stings." % allowance_decline_reason)

	if accommodation_deposit_paid:
		paras.append("You've got somewhere to live: %s, deposit paid. That is one thing off the list." % str(ACCOMMODATION[accommodation_choice].label).to_lower())
	elif accommodation_choice != "":
		paras.append("You picked out accommodation and never paid the deposit, so it isn't actually held.")
	else:
		paras.append("You never sorted anywhere to live next year. That's a February problem now.")

	if preference_changes > 0:
		paras.append("You changed your mind about where you were going %d time%s. That's not indecision — that's the only sensible response to being asked at seventeen." % [
			preference_changes, "" if preference_changes == 1 else "s"])

	# 5. Sign-off tuned to the ending.
	match ending_result:
		"scholarship":
			paras.append("Someone read your results and decided to pay for you. Take the win.")
		"good":
			paras.append("Paid for out of your own pocket, out of your own shifts. Nobody handed you that.")
		"student_loan":
			paras.append("Going, and going into debt to do it. That is what most people do.")
		"unfunded":
			paras.append("The cruellest version of this: you did the work, you got the offer, and the money wasn't there.")
		"deferred":
			paras.append("The place will still be there in a year. You needed the year more.")
		"second_choice":
			paras.append("Not the one on the poster in your room. Still a start.")
		"foundation_year":
			paras.append("The long way round is still the way round.")
		"no_ue":
			paras.append("Credits, not grades. That's the bit nobody explains properly until it's too late.")
		"bad_sanity":
			paras.append("The year didn't finish. You did.")
		"bad_deadline":
			paras.append("Ninety days is not very long, in the end.")
	return "\n\n".join(paras)


func _join_natural(items: Array) -> String:
	if items.is_empty():
		return ""
	if items.size() == 1:
		return str(items[0])
	var head: Array = items.slice(0, items.size() - 1)
	return ", ".join(head) + " and " + str(items[-1])


## The handful of journal lines worth putting on the ending screen — exams,
## results, the loan, and anything flagged as a turning point.
func notable_events(limit: int = 8) -> Array:
	var keywords := ["MISSED", "external", "internal", "StudyLink", "Burnout", "Term deposit", "results"]
	var hits: Array = []
	for entry in journal:
		for k in keywords:
			if str(entry.text).findn(k) != -1:
				hits.append(entry)
				break
	if hits.size() <= limit:
		return hits
	# Keep the first couple and the last few — beginning and end of the year.
	var out: Array = hits.slice(0, 2)
	out.append_array(hits.slice(hits.size() - (limit - 2), hits.size()))
	return out


## Resets everything for a fresh playthrough (called from the ending screen's
## "Main Menu" button, or wherever you want to let the player restart).
func reset_run() -> void:
	player_name = "Alex"
	selected_university = ""
	selected_major = ""
	selected_conjoint = ""
	active_subjects = ["english", "maths", "physics"]
	money = 100.0
	subject_grades = {"english": 50.0, "maths": 50.0, "physics": 50.0}
	subject_credits = {}
	subject_prep = {}
	literacy_credits = UE_LITERACY_REQUIRED
	numeracy_credits = UE_NUMERACY_REQUIRED
	commitments.clear()
	work_no_shows = 0
	study_no_shows = 0
	fired_from_work = false
	energy = 100.0
	sanity = 100.0
	thirst = 100.0
	temptation = 0.0
	game_hour = DAY_START_HOUR
	game_day = 1
	pending_hours = 0.0
	saved_current_time = DAY_START_HOUR
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
	results_phase = 0
	ending_result = ""
	exam_schedule.clear()
	derived_grades_left = DERIVED_GRADE_ALLOWANCE
	message_state = {}
	unread_count = 0
	journal.clear()

	ird_number = ""
	_ensure_ird()
	household_income = 0.0
	allowance_status = "none"
	allowance_days_left = 0
	allowance_decline_reason = ""
	allowance_weekly = 0.0
	allowance_received = 0.0
	parents_confirmed_income = false
	allowance_waiting_days = 0
	allowance_outcome = ""
	allowance_stand_down_weeks = 0
	accommodation_benefit_weekly = 0.0
	allowance_reviewed = false
	accommodation_choice = ""
	accommodation_deposit_paid = false
	preference_changes = 0
	days_at_rock_bottom = 0
	# Note: test_mode and dev_no_decay deliberately survive reset_run(), so
	# restarting from the ending screen keeps you in the short year.

	loan_status = "none"
	loan_days_left = 0
	loan_decline_reason = ""
	loan_wants_fees = false
	loan_wants_living_costs = false
	loan_debt = 0.0
	loan_ird_number = ""

	stat_study_sessions = 0
	stat_study_hours = 0.0
	stat_shifts = 0
	stat_work_hours = 0.0
	stat_earned = 0.0
	stat_exams_sat = 0
	stat_exams_missed = 0
	stat_nights_slept = 0
	stat_meals_cooked = 0
	stat_conversations = 0
	stat_messages_replied = 0
	stat_lowest_sanity = 100.0
	stat_doomscrolls = 0

	if has_node("/root/MessageData"):
		get_node("/root/MessageData").reset_state()

	stats_changed.emit()
	journal_updated.emit()
	messages_changed.emit()


## Studying — at a school desk, at home, or on the laptop.
##
## This does NOT move your grade and does NOT award credits. Grades come from
## assessments, credits come from internals. What an evening of past papers
## actually buys you is knowing the material, so it raises preparedness, which
## makes the assessment itself easier and tells you where you stand.
##
## `depth` scales how much readiness one session is worth — a proper sit-down
## at a desk is worth more than ten minutes of revision videos.
func complete_study_session(subject: String, correct: int, total: int, hours: float,
		energy_cost: float = 6.0, depth: float = 14.0) -> void:
	if not subject_grades.has(subject):
		push_warning("GameBackend: unknown subject '%s'" % subject)
		return

	var accuracy: float = 0.0 if total <= 0 else float(correct) / float(total)
	# Getting them wrong still teaches you something — you just learn less
	# than someone who's on top of it. Never zero, or a bad session feels
	# like a punishment for trying.
	var gain: float = depth * (0.35 + 0.65 * accuracy)
	gain *= 1.0 - (temptation / 250.0)
	change_prep(subject, gain)

	_queue_hours(hours)
	change_energy(-energy_cost)
	change_sanity(-(3.0 - accuracy * 3.0))
	change_thirst(-hours * 2.0)
	temptation = clamp(temptation - 3.0, 0.0, 100.0)

	stat_study_sessions += 1
	stat_study_hours += hours

	log_event("Studied %s — %d/%d. Revision now %.0f%% (%s)." % [
		subject.capitalize(), correct, total, get_prep(subject), predicted_band(subject)])
	stats_changed.emit()


## Extra credit from the teacher. Along with assessments, this is the only
## thing that moves a grade — the deal being that you have to actually turn up
## and talk to Mr Halloway rather than grinding a desk on your own.
func teacher_extra_credit(subject: String, correct: int, total: int,
		hours: float = 0.4, energy_cost: float = 4.0, max_gain: float = 6.0) -> void:
	if not subject_grades.has(subject):
		return
	var accuracy: float = 0.0 if total <= 0 else float(correct) / float(total)
	var gain: float = max_gain * accuracy
	subject_grades[subject] = clamp(subject_grades[subject] + gain, 0.0, 100.0)
	change_prep(subject, 8.0 * accuracy)

	_queue_hours(hours)
	change_energy(-energy_cost)
	change_sanity(2.0 if accuracy >= 0.5 else -2.0)

	log_event("Extra credit with Mr Halloway (%s): %s — grade now %.0f." % [
		subject.capitalize(), "correct" if accuracy >= 0.5 else "not quite",
		subject_grades[subject]])
	stats_changed.emit()


## Work shifts are only available while you're still on the roster.
func can_work() -> bool:
	return not fired_from_work


## Called by the work scene when a shift ends. `performance` is 0..1 (accuracy
## across the shift's tasks). Physical work costs more energy/thirst than
## studying; a smooth shift is a genuine break from schoolwork stress.
func complete_work_shift(hours: float, performance: float, base_pay_per_hour: float = 25.0) -> void:
	performance = clamp(performance, 0.0, 1.0)
	var pay: float = base_pay_per_hour * hours * (0.6 + 0.4 * performance)
	pay *= 1.0 - (temptation / 300.0)  # distracted/run-down from procrastinating = less focused, less efficient shift

	_queue_hours(hours)
	money += pay
	change_energy(-hours * 12.0)
	change_thirst(-hours * 8.0)
	change_sanity(-(hours * 1.2) + (performance * hours * 2.0))
	temptation = clamp(temptation - hours * 1.5, 0.0, 100.0)

	stat_shifts += 1
	stat_work_hours += hours
	stat_earned += pay

	log_event("Worked a %.1fh shift — %.0f%% accuracy, earned $%.2f" % [hours, performance * 100.0, pay])
	stats_changed.emit()


## Drinking at a fountain/tap: small time cost, decent thirst refill.
func drink_water(amount: float = 40.0, hours: float = 0.05) -> void:
	_queue_hours(hours)
	change_thirst(amount)


## Sleeping in your own bed. Kept for compatibility with anything that still
## calls sleep(hours) directly — but prefer sleep_until_morning().
func sleep(hours: float = 8.0) -> void:
	_queue_hours(hours)
	energy = 100.0
	change_sanity(35.0)
	change_thirst(-hours * 1.0)
	stat_nights_slept += 1
	log_event("Slept for %.0f hours." % hours)
	stats_changed.emit()


## How many hours from right now until the next WAKE_HOUR.
func hours_until_morning() -> float:
	if game_hour < WAKE_HOUR:
		return WAKE_HOUR - game_hour
	return (24.0 - game_hour) + WAKE_HOUR


## Sleep through to the morning rather than for a fixed block. This is the
## fix for waking up at 4am and wandering into a locked school: whatever time
## you go to bed, you get up at WAKE_HOUR.
##
## Going to bed stupidly early (before ~8pm) means a long, restless night —
## you get the full restore but you've thrown away the evening. Going to bed
## after midnight means a short night and only a partial restore, which is
## exactly the trade-off an all-nighter should have.
func sleep_until_morning() -> Dictionary:
	var hours: float = hours_until_morning()
	# 0-1 quality scale: 8 hours is a full night, less is worse, and more
	# than about 10 doesn't help any further.
	var quality: float = clampf(hours / 8.0, 0.25, 1.0)

	_queue_hours(hours)
	energy = clamp(20.0 + 80.0 * quality, 0.0, 100.0)
	# A proper night is worth about two days of ordinary drain, so sleeping
	# is a real recovery rather than a slower decline.
	change_sanity(18.0 + 34.0 * quality)
	change_thirst(-hours * 0.8)
	temptation = clamp(temptation - 4.0, 0.0, 100.0)
	stat_nights_slept += 1

	var note: String = ""
	if hours <= 4.0:
		note = "A short, rubbish night — %.0f hours." % hours
	elif hours >= 11.0:
		note = "You went to bed far too early and slept badly for %.0f hours." % hours
	else:
		note = "Slept %.0f hours and woke up at %d:00." % [hours, int(WAKE_HOUR)]

	log_event(note)
	stats_changed.emit()
	return {"hours": hours, "quality": quality, "text": note}


## A short nap — tops up energy without eating the whole night.
func nap(hours: float = 2.0) -> void:
	_queue_hours(hours)
	change_energy(hours * 14.0)
	change_sanity(hours * 3.0)
	change_thirst(-hours * 0.8)
	log_event("Napped for %.0f hours." % hours)
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
	stat_meals_cooked += 1
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
	stat_conversations += 1
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
	stat_doomscrolls += 1
	stats_changed.emit()


# --- Phone message delivery ----------------------------------------------------

func _msg(thread_id: String) -> Dictionary:
	if thread_id == "":
		# Never let a blank id create a phantom entry — it would show up as an
		# empty chat in the inbox and count toward the unread badge.
		return {"arrived": false, "read": true, "done": true, "day": 0, "step": 0, "log": []}
	if not message_state.has(thread_id):
		message_state[thread_id] = {"arrived": false, "read": false, "done": false, "day": 0, "step": 0, "log": []}
	return message_state[thread_id]


func has_arrived(thread_id: String) -> bool:
	return _msg(thread_id).arrived


func is_read(thread_id: String) -> bool:
	return _msg(thread_id).read


func is_done(thread_id: String) -> bool:
	return _msg(thread_id).done


func arrived_on_day(thread_id: String) -> int:
	return int(_msg(thread_id).get("day", 0))


func mark_read(thread_id: String) -> void:
	var m: Dictionary = _msg(thread_id)
	if m.arrived and not m.read:
		m.read = true
		_recount_unread()


## How far through a thread the player has got.
func thread_step(thread_id: String) -> int:
	return int(_msg(thread_id).get("step", 0))


func set_thread_step(thread_id: String, step: int) -> void:
	_msg(thread_id)["step"] = step


## Saved transcript: an array of {speaker, body, mine}.
func thread_log(thread_id: String) -> Array:
	var m: Dictionary = _msg(thread_id)
	if not m.has("log"):
		m["log"] = []
	return m["log"]


func append_thread_log(thread_id: String, speaker: String, body: String, mine: bool) -> void:
	# The day is stored so the merged per-contact view can put a divider
	# between "Mum, day 3" and "Mum, day 41" instead of running two months of
	# conversation together as one wall.
	thread_log(thread_id).append({
		"speaker": speaker, "body": body, "mine": mine,
		"day": get_elapsed_days(),
	})


func mark_done(thread_id: String) -> void:
	_msg(thread_id).done = true
	messages_changed.emit()


## Delivers a thread to the inbox. Called by the daily/random drip in
## MessageData, or directly for story messages like results day.
func deliver_message(thread_id: String) -> void:
	var m: Dictionary = _msg(thread_id)
	if m.arrived:
		return
	m.arrived = true
	m.read = false
	m.day = get_elapsed_days()
	_recount_unread()

	var sender: String = thread_id
	if has_node("/root/MessageData"):
		var t: Dictionary = get_node("/root/MessageData").thread_by_id(thread_id)
		if not t.is_empty():
			sender = str(t.get("sender", thread_id))
	message_arrived.emit(sender, thread_id)


# =============================================================================
# CONTACTS
# =============================================================================
# The inbox is keyed by PERSON, not by conversation. Mum texting you on day 3
# and again on day 42 is one chat with Mum, the way it would be on a real
# phone — the threads are still separate objects underneath, they're just
# stacked into one scrolling history per contact.

## Every contact who has ever texted you, most recent first.
func contacts() -> Array:
	var seen: Dictionary = {}
	var out: Array = []
	var md = get_node_or_null("/root/MessageData")
	if md == null:
		return out
	for t in md.threads:
		var tid: String = str(t.get("id", ""))
		if tid == "" or not has_arrived(tid):
			continue
		var who: String = contact_name_for(tid)
		if not seen.has(who):
			seen[who] = arrived_on_day(tid)
			out.append(who)
		else:
			seen[who] = maxi(seen[who], arrived_on_day(tid))
	out.sort_custom(func(a, b): return seen[a] > seen[b])
	return out


## The display name for whoever sent a thread. Resolved through MessageData so
## the dynamic ones (the university admissions office) come out right.
func contact_name_for(thread_id: String) -> String:
	var md = get_node_or_null("/root/MessageData")
	if md == null:
		return thread_id
	var t: Dictionary = md.thread_by_id(thread_id)
	if t.is_empty():
		return thread_id
	if thread_id == "university_offer":
		return admissions_sender()
	return str(t.get("sender", thread_id))


## Every arrived thread from one contact, oldest first — this is the order the
## merged transcript is replayed in.
func threads_for_contact(who: String) -> Array:
	var out: Array = []
	var md = get_node_or_null("/root/MessageData")
	if md == null:
		return out
	for t in md.threads:
		var tid: String = str(t.get("id", ""))
		if tid == "" or not has_arrived(tid):
			continue
		if contact_name_for(tid) == who:
			out.append(tid)
	out.sort_custom(func(a, b): return arrived_on_day(a) < arrived_on_day(b))
	return out


## The next unfinished conversation with this contact, or "" if you're all
## caught up with them.
func active_thread_for_contact(who: String) -> String:
	for tid in threads_for_contact(who):
		if not is_done(tid):
			return tid
	return ""


func unread_for_contact(who: String) -> int:
	var n: int = 0
	for tid in threads_for_contact(who):
		if not is_read(tid):
			n += 1
	return n


func contact_has_unread(who: String) -> bool:
	return unread_for_contact(who) > 0


## Newest day anything arrived from this contact, for inbox ordering.
func last_activity_for_contact(who: String) -> int:
	var newest: int = -1
	for tid in threads_for_contact(who):
		newest = maxi(newest, arrived_on_day(tid))
	return newest


func mark_contact_read(who: String) -> void:
	for tid in threads_for_contact(who):
		mark_read(tid)


func _recount_unread() -> void:
	var n: int = 0
	for id in message_state:
		var m: Dictionary = message_state[id]
		if m.arrived and not m.read:
			n += 1
	unread_count = n
	messages_changed.emit()
