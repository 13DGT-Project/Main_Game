## dev_panel.gd
## Autoload: "DevPanel"     Toggle with F3.
##
## ============================================================================
##  HOW TO REMOVE THIS ENTIRELY BEFORE SHIPPING
## ============================================================================
##  1. Delete this file (Backend/Dev/dev_panel.gd).
##  2. Delete the one line   DevPanel="*res://Backend/Dev/dev_panel.gd"
##     from [autoload] in project.godot.
##  Nothing else in the game references DevPanel, so it comes out cleanly.
##
##  The only footprint left behind is the clearly-marked TEST MODE block in
##  GameBackend.gd and the `if dev_no_decay: return` line in
##  apply_passive_decay(). Both are inert without this file.
##
##  You don't strictly have to remove it — _ready() disables the panel unless
##  OS.is_debug_build(), so an exported release already ignores F3.
## ============================================================================
##
## STYLE NOTE: every button action is a NAMED function bound with .bind(),
## never an inline multi-statement lambda. GDScript's parser has to guess
## where a multi-line lambda body ends when arguments follow it, and a dev
## tool that won't compile is worse than no dev tool.
extends CanvasLayer

## Set false to hard-disable even in the editor.
const ENABLED_IN_DEBUG_ONLY: bool = true

const PANEL_SIZE := Vector2(960, 680)

const COL_BG := Color(0.07, 0.08, 0.10, 0.98)
const COL_HEAD := Color(1.0, 0.45, 0.35)
const COL_SECTION := Color(0.45, 0.78, 1.0)
const COL_MUTED := Color(0.60, 0.64, 0.72)
const COL_DANGER := Color(0.92, 0.38, 0.38)
const COL_GOOD := Color(0.40, 0.82, 0.52)
const COL_PLAIN := Color(1, 1, 1)

var _enabled: bool = true
var _root: Control
var _panel: PanelContainer
var _status: Label
var _log: Label
var _body: VBoxContainer
var _scroll: ScrollContainer
var _is_open: bool = false
var _last_action: String = "Ready. F3 closes this."


func _ready() -> void:
	_enabled = OS.is_debug_build() or not ENABLED_IN_DEBUG_ONLY
	if not _enabled:
		return
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		toggle()
		get_viewport().set_input_as_handled()
		return
	if _is_open and event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func open() -> void:
	_is_open = true
	_root.visible = true
	_centre()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_rebuild()


func close() -> void:
	_is_open = false
	_root.visible = false


func _centre() -> void:
	var vp: Vector2 = _root.size
	if vp.x <= 1.0:
		vp = get_viewport().get_visible_rect().size
	_panel.size = PANEL_SIZE
	_panel.position = ((vp - PANEL_SIZE) * 0.5).floor()


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "DevRoot"
	_root.visible = false
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	_panel = PanelContainer.new()
	_panel.size = PANEL_SIZE
	var st := StyleBoxFlat.new()
	st.bg_color = COL_BG
	st.border_width_left = 2
	st.border_width_right = 2
	st.border_width_top = 2
	st.border_width_bottom = 2
	st.border_color = COL_HEAD
	st.corner_radius_top_left = 8
	st.corner_radius_top_right = 8
	st.corner_radius_bottom_left = 8
	st.corner_radius_bottom_right = 8
	st.content_margin_left = 16
	st.content_margin_right = 16
	st.content_margin_top = 12
	st.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", st)
	_root.add_child(_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	_panel.add_child(outer)

	var head_row := HBoxContainer.new()
	outer.add_child(head_row)

	var title := Label.new()
	title.text = "DEV PANEL   ·   F3 to close"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", COL_HEAD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(90, 28)
	close_btn.pressed.connect(close)
	head_row.add_child(close_btn)

	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", COL_MUTED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_status)

	_log = Label.new()
	_log.add_theme_font_size_override("font_size", 13)
	_log.add_theme_color_override("font_color", COL_GOOD)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_log)

	outer.add_child(HSeparator.new())

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_body)


## Reports what the last button did, then redraws so toggle labels and the
## status line stay accurate without every action remembering to.
func _say(text: String) -> void:
	_last_action = text
	_rebuild()


func _rebuild() -> void:
	if not _is_open:
		return
	_refresh_status()
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_section_time()
	_section_money()
	_section_stats()
	_section_grades()
	_section_exams()
	_section_prep()
	_section_commitments()
	_section_studylink()
	_section_allowance()
	_section_messages()
	_section_endings()
	_section_results()
	_section_scenes()
	_section_inventory()
	_section_run()


func _refresh_status() -> void:
	var mins: int = int(fmod(GameBackend.game_hour, 1.0) * 60.0)
	_status.text = "Day %d/%d  ·  %02d:%02d  ·  $%.2f  ·  grade %.0f / %.0f  ·  E%.0f S%.0f T%.0f  ·  tempt %.0f\ncredits %d  ·  subjects at threshold %d/%d  ·  UE: %s  ·  loan %s  ·  allowance %s  ·  phase %d%s%s" % [
		GameBackend.get_elapsed_days(), GameBackend.TOTAL_DAYS,
		int(GameBackend.game_hour), mins,
		GameBackend.money, GameBackend.get_overall_grade(), GameBackend.required_grade(),
		GameBackend.energy, GameBackend.sanity, GameBackend.thirst, GameBackend.temptation,
		GameBackend.total_credits(),
		GameBackend.subjects_meeting_credit_threshold(), GameBackend.UE_SUBJECTS_REQUIRED,
		"YES" if GameBackend.has_university_entrance() else "no",
		GameBackend.loan_status, GameBackend.allowance_status, GameBackend.results_phase,
		"  ·  [TEST MODE]" if GameBackend.test_mode else "",
		"  ·  [NO DECAY]" if GameBackend.dev_no_decay else "",
	]
	_log.text = _last_action


# --- layout helpers ------------------------------------------------------------

func _section(title: String) -> HFlowContainer:
	var l := Label.new()
	l.text = title
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", COL_SECTION)
	_body.add_child(l)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(flow)
	return flow


func _btn(flow: HFlowContainer, text: String, action: Callable, width: float = 150.0, colour: Color = COL_PLAIN) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 32)
	b.add_theme_font_size_override("font_size", 13)
	if colour != COL_PLAIN:
		b.add_theme_color_override("font_color", colour)
	b.pressed.connect(action)
	flow.add_child(b)


func _note(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", COL_MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(880, 0)
	_body.add_child(l)


# =============================================================================
# TIME
# =============================================================================

func _section_time() -> void:
	var f := _section("TIME")
	_btn(f, "+1 hour", _act_hours.bind(1.0), 95)
	_btn(f, "+6 hours", _act_hours.bind(6.0), 95)
	_btn(f, "To morning", _act_to_morning, 110)
	_btn(f, "+1 day", _act_skip_days.bind(1), 95)
	_btn(f, "+7 days", _act_skip_days.bind(7), 95)
	_btn(f, "+30 days", _act_skip_days.bind(30), 95)
	_btn(f, "-1 day *", _act_rewind_days.bind(1), 95, COL_DANGER)
	_btn(f, "-7 days *", _act_rewind_days.bind(7), 95, COL_DANGER)
	_btn(f, "To final day", _act_to_final_day, 125)
	_note("* rewinding only puts days back on the clock. It does not undo exams sat, money earned or texts received — there is no undo history, so treat it as \"give me more runway\", not \"go back in time\".")


func _act_hours(h: float) -> void:
	GameBackend.advance_time(h)
	_say("Skipped %.0f hour(s)." % h)


func _act_to_morning() -> void:
	var h: float = GameBackend.hours_until_morning()
	GameBackend.advance_time(h)
	_say("Skipped %.1f hours to %d:00." % [h, int(GameBackend.WAKE_HOUR)])


func _act_skip_days(n: int) -> void:
	for i in n:
		if GameBackend.game_over:
			break
		GameBackend.advance_time(24.0)
	_say("Skipped %d day(s). Now day %d of %d." % [
		n, GameBackend.get_elapsed_days(), GameBackend.TOTAL_DAYS])


func _act_rewind_days(n: int) -> void:
	GameBackend.days_remaining = clampi(GameBackend.days_remaining + n, 0, GameBackend.TOTAL_DAYS)
	GameBackend.stats_changed.emit()
	_say("Put %d day(s) back. Now day %d of %d." % [
		n, GameBackend.get_elapsed_days(), GameBackend.TOTAL_DAYS])


func _act_to_final_day() -> void:
	GameBackend.days_remaining = 1
	GameBackend.stats_changed.emit()
	_say("Jumped to the last day of the year.")


# =============================================================================
# MONEY
# =============================================================================

func _section_money() -> void:
	var f := _section("MONEY")
	_btn(f, "+$50", _act_money.bind(50.0), 85)
	_btn(f, "+$500", _act_money.bind(500.0), 85)
	_btn(f, "+$5000", _act_money.bind(5000.0), 90)
	_btn(f, "Exact fees", _act_money_exact_fees, 115)
	_btn(f, "$1 short of fees", _act_money_just_short, 145)
	_btn(f, "Broke ($0)", _act_money_broke, 110, COL_DANGER)
	_btn(f, "Mature term deposit", _act_mature_deposit, 165)


func _act_money(amount: float) -> void:
	GameBackend.add_money(amount)
	_say("Added $%.0f. Wallet now $%.2f." % [amount, GameBackend.money])


func _fees() -> float:
	return GameBackend.universities.get(GameBackend.selected_university, {}).get("money_needed", 0)


func _act_money_exact_fees() -> void:
	GameBackend.money = _fees()
	GameBackend.stats_changed.emit()
	_say("Wallet set to $%.0f — exactly the fees." % GameBackend.money)


## The most useful single money button: one dollar off is the boundary between
## the "good" and "student_loan" / "unfunded" endings.
func _act_money_just_short() -> void:
	GameBackend.money = max(0.0, _fees() - 1.0)
	GameBackend.stats_changed.emit()
	_say("Wallet set to $%.0f — one dollar short of fees." % GameBackend.money)


func _act_money_broke() -> void:
	GameBackend.money = 0.0
	GameBackend.stats_changed.emit()
	_say("Wallet emptied.")


func _act_mature_deposit() -> void:
	GameBackend.term_deposit_days_left = 1
	_say("Term deposit will pay out on the next day tick.")


# =============================================================================
# STATS
# =============================================================================

func _section_stats() -> void:
	var f := _section("STATS")
	_btn(f, "Refill all bars", _act_refill, 135)
	_btn(f, "Sanity 24 (defer)", _act_sanity.bind(24.0), 145)
	_btn(f, "Sanity 5 (near burnout)", _act_sanity.bind(5.0), 180)
	_btn(f, "Temptation MAX", _act_temptation.bind(100.0), 145)
	_btn(f, "Temptation 0", _act_temptation.bind(0.0), 125)
	_btn(f, "God mode: %s" % ("ON" if GameBackend.dev_no_decay else "off"),
		_act_toggle_god, 150, COL_GOOD if GameBackend.dev_no_decay else COL_PLAIN)


func _act_refill() -> void:
	GameBackend.energy = 100.0
	GameBackend.sanity = 100.0
	GameBackend.thirst = 100.0
	GameBackend.stats_changed.emit()
	_say("Energy, sanity and thirst restored.")


func _act_sanity(value: float) -> void:
	GameBackend.sanity = value
	GameBackend.stats_changed.emit()
	_say("Sanity set to %.0f (defer threshold %.0f, burnout at 0)." % [
		value, GameBackend.SANITY_DEFER_THRESHOLD])


func _act_temptation(value: float) -> void:
	GameBackend.temptation = value
	GameBackend.stats_changed.emit()
	_say("Temptation set to %.0f." % value)


func _act_toggle_god() -> void:
	GameBackend.dev_no_decay = not GameBackend.dev_no_decay
	_say("Passive decay %s." % ("DISABLED — bars will not drain." if GameBackend.dev_no_decay else "re-enabled."))


# =============================================================================
# GRADES
# =============================================================================

func _section_grades() -> void:
	var f := _section("GRADES")
	_btn(f, "All 30", _act_set_grades.bind(30.0), 90)
	_btn(f, "All 50", _act_set_grades.bind(50.0), 90)
	_btn(f, "All 70", _act_set_grades.bind(70.0), 90)
	_btn(f, "All 90", _act_set_grades.bind(90.0), 90)
	_btn(f, "All 100", _act_set_grades.bind(100.0), 90)
	_btn(f, "Exactly at entry standard", _act_grades_at_requirement, 195)
	_btn(f, "One below entry standard", _act_grades_just_below, 195)


func _act_set_grades(value: float) -> void:
	for subject in GameBackend.active_subjects:
		GameBackend.subject_grades[subject] = value
	GameBackend.stats_changed.emit()
	_say("All subject grades set to %.0f (overall %.0f)." % [value, GameBackend.get_overall_grade()])


func _act_grades_at_requirement() -> void:
	_act_set_grades(GameBackend.required_grade())


func _act_grades_just_below() -> void:
	_act_set_grades(max(0.0, GameBackend.required_grade() - 1.0))


# =============================================================================
# EXAMS & CREDITS
# =============================================================================

func _section_exams() -> void:
	var f := _section("CREDITS & EXAMS")
	_btn(f, "Grant UE instantly", _act_grant_ue, 155, COL_GOOD)
	_btn(f, "Wipe all credits", _act_wipe_credits, 140, COL_DANGER)
	_btn(f, "Pass next internal", _act_next_exam.bind(1.0, "internal"), 165)
	_btn(f, "Fail next internal", _act_next_exam.bind(0.2, "internal"), 165)
	_btn(f, "Sit next external", _act_next_exam.bind(0.9, "external"), 160)
	_btn(f, "Sit ALL exams (95%)", _act_sit_all, 170)
	_btn(f, "Release externals now", _act_release_externals, 175)
	_btn(f, "Rebuild timetable", _act_rebuild_timetable, 150)

	var f2 := _section("ENDORSEMENTS")
	_btn(f2, "Grant Merit endorsement", _act_endorse.bind("Merit"), 190, COL_GOOD)
	_btn(f2, "Grant Excellence endorsement", _act_endorse.bind("Excellence"), 215, COL_GOOD)
	_btn(f2, "Show endorsement state", _act_show_endorsements, 190)
	_note("Certificate endorsement is 50 credits at Merit or better (50 at Excellence for an Excellence endorsement) — NOT 60. Course endorsement is 14 in one subject at Merit+, with at least 3 credits from internals and 3 from the external.")
	_note("Both internals and externals award credits — %d and %d respectively — and the credit value does not change with the grade. The grade sets the BAND, which is what endorsements count." % [GameBackend.INTERNAL_CREDITS, GameBackend.EXTERNAL_CREDITS])


## Fills the ledger with enough banded credits to endorse, split across
## internals and externals so course endorsements qualify too.
func _act_endorse(band: String) -> void:
	GameBackend.credit_awards.clear()
	for subject in GameBackend.active_subjects:
		GameBackend.subject_credits[subject] = 0
	GameBackend.literacy_credits = GameBackend.UE_LITERACY_REQUIRED
	GameBackend.numeracy_credits = GameBackend.UE_NUMERACY_REQUIRED
	for subject in GameBackend.active_subjects:
		# 4 internals + 1 external = 21 credits, all at the chosen band.
		for i in 4:
			GameBackend.award_credits(subject, GameBackend.INTERNAL_CREDITS, band, "internal")
		GameBackend.award_credits(subject, GameBackend.EXTERNAL_CREDITS, band, "external")
	GameBackend.stats_changed.emit()
	_say("Filled the ledger at %s: %d total, %d at Merit+, %d at Excellence. Certificate: %s." % [
		band, GameBackend.total_credits(),
		GameBackend.total_credits_at("Merit"),
		GameBackend.total_credits_at("Excellence"),
		GameBackend.certificate_endorsement() if GameBackend.certificate_endorsement() != "" else "none"])


func _act_show_endorsements() -> void:
	var parts: Array = [GameBackend.certificate_endorsement_progress()]
	for subject in GameBackend.active_subjects:
		parts.append("%s: %s" % [str(subject).capitalize(),
			GameBackend.course_endorsement_reason(subject)])
	_say(" | ".join(parts))


func _act_grant_ue() -> void:
	for subject in GameBackend.active_subjects:
		var short: int = GameBackend.UE_CREDITS_PER_SUBJECT - GameBackend.subject_credits.get(subject, 0)
		if short > 0:
			GameBackend.award_credits(subject, short, "Achieved", "internal")
	GameBackend.stats_changed.emit()
	_say("UE granted — every subject at the %d-credit threshold." % GameBackend.UE_CREDITS_PER_SUBJECT)


func _act_wipe_credits() -> void:
	GameBackend.credit_awards.clear()
	for subject in GameBackend.active_subjects:
		GameBackend.subject_credits[subject] = 0
	GameBackend.stats_changed.emit()
	_say("All credits wiped — the run will now end in 'no_ue'.")


## Pulls the next scheduled exam of that kind forward to today and resolves
## it, so you don't have to be in the right building on the right day.
func _act_next_exam(accuracy: float, kind: String) -> void:
	var nxt: Dictionary = {}
	for exam in GameBackend.exam_schedule:
		if not exam.taken and str(exam.get("kind", "internal")) == kind:
			nxt = exam
			break
	if nxt.is_empty():
		_say("No %s exams left to resolve." % kind)
		return
	var total: int = GameBackend.EXAM_QUESTION_COUNT
	var correct: int = int(round(accuracy * float(total)))
	var subject: String = str(nxt.subject)
	nxt.day = GameBackend.get_elapsed_days()
	GameBackend.complete_exam(subject, correct, total)
	_say("Resolved the %s %s at %d/%d.%s" % [subject, kind, correct, total,
		"  (Sealed until results day.)" if kind == "external" else ""])


func _act_sit_all() -> void:
	var n: int = 0
	for exam in GameBackend.exam_schedule:
		if not exam.taken:
			exam.taken = true
			exam.passed = true
			exam.accuracy = 0.95
			var kind: String = str(exam.get("kind", "internal"))
			GameBackend.award_credits(str(exam.subject),
				GameBackend.EXTERNAL_CREDITS if kind == "external" else GameBackend.INTERNAL_CREDITS,
				"Excellence", kind)
			n += 1
	GameBackend.stats_changed.emit()
	_say("Marked %d outstanding exam(s) as sat at 95%%. Release externals to apply their grade swing." % n)


func _act_release_externals() -> void:
	GameBackend.release_external_results()
	_say("External results applied to grades.")


func _act_rebuild_timetable() -> void:
	GameBackend.generate_exam_schedule()
	var internals: int = 0
	var externals: int = 0
	for e in GameBackend.exam_schedule:
		if str(e.get("kind", "")) == "external":
			externals += 1
		else:
			internals += 1
	_say("Timetable rebuilt: %d internals, %d externals across %d days." % [
		internals, externals, GameBackend.TOTAL_DAYS])


# =============================================================================
# PREPAREDNESS
# =============================================================================

func _section_prep() -> void:
	var f := _section("REVISION / PREPAREDNESS")
	_btn(f, "All prep 0", _act_set_prep.bind(0.0), 115)
	_btn(f, "All prep 50", _act_set_prep.bind(50.0), 115)
	_btn(f, "All prep 100", _act_set_prep.bind(100.0), 120)
	_btn(f, "Show prep", _act_show_prep, 120)
	_note("Studying at a desk or on the laptop no longer moves your grade or gives credits. It raises preparedness, which decides how many 50/50 eliminations you get in the exam and what the predicted band says.")


func _act_set_prep(value: float) -> void:
	for subject in GameBackend.active_subjects:
		GameBackend.subject_prep[subject] = value
	GameBackend.stats_changed.emit()
	_say("Preparedness set to %.0f in every subject." % value)


func _act_show_prep() -> void:
	var parts: Array = []
	for subject in GameBackend.active_subjects:
		parts.append("%s %.0f (%s)" % [
			str(subject).capitalize(), GameBackend.subject_prep.get(subject, 0.0),
			GameBackend.predicted_band(subject)])
	_say(" · ".join(parts))


# =============================================================================
# COMMITMENTS
# =============================================================================

func _section_commitments() -> void:
	var f := _section("COMMITMENTS")
	_btn(f, "List commitments", _act_list_commitments, 155)
	_btn(f, "Add work shift today", _act_add_shift, 175)
	_btn(f, "Add study session today", _act_add_study, 190)
	_btn(f, "Clear all", _act_clear_commitments, 110, COL_DANGER)
	_note("Agreeing to a shift or a study session in a conversation books it. Not turning up costs you — three no-shows at work and Deb takes you off the roster for good.")


func _act_list_commitments() -> void:
	if GameBackend.commitments.is_empty():
		_say("No outstanding commitments.")
		return
	var parts: Array = []
	for c in GameBackend.commitments:
		parts.append("day %d: %s (%s)" % [c.day, c.label, c.kind])
	_say("Booked — " + "  ·  ".join(parts) + "   [no-shows: work %d]" % GameBackend.work_no_shows)


func _act_add_shift() -> void:
	GameBackend.add_commitment("work", "Shift at the supermarket", GameBackend.get_elapsed_days())
	_say("Booked a shift for today.")


func _act_add_study() -> void:
	GameBackend.add_commitment("study_group", "Study group at the library", GameBackend.get_elapsed_days())
	_say("Booked a study group session for today.")


func _act_clear_commitments() -> void:
	GameBackend.commitments.clear()
	GameBackend.work_no_shows = 0
	GameBackend.stats_changed.emit()
	_say("All commitments cleared and the no-show counter reset.")


# =============================================================================
# STUDYLINK
# =============================================================================

func _section_studylink() -> void:
	var f := _section("STUDENT LOAN")
	_btn(f, "Approve (fees + living)", _act_loan_full, 185, COL_GOOD)
	_btn(f, "Approve (living only)", _act_loan_living_only, 180)
	_btn(f, "Decline", _act_loan_decline, 105, COL_DANGER)
	_btn(f, "Reset to 'none'", _act_loan_reset, 130)
	_btn(f, "Fast-forward decision", _act_fast_decision, 175)
	_note("\"Living only\" is the interesting one: you get an offer you earned and still can't take it up. That's the 'unfunded' ending.")


func _act_loan_full() -> void:
	GameBackend.loan_status = "approved"
	GameBackend.loan_wants_fees = true
	GameBackend.loan_wants_living_costs = true
	GameBackend.loan_days_left = 0
	GameBackend.stats_changed.emit()
	_say("Loan approved for fees and living costs.")


func _act_loan_living_only() -> void:
	GameBackend.loan_status = "approved"
	GameBackend.loan_wants_fees = false
	GameBackend.loan_wants_living_costs = true
	GameBackend.loan_days_left = 0
	GameBackend.stats_changed.emit()
	_say("Loan approved for living costs only — fees NOT covered.")


func _act_loan_decline() -> void:
	GameBackend.loan_status = "declined"
	GameBackend.loan_decline_reason = "[dev] forced decline"
	GameBackend.stats_changed.emit()
	_say("Loan declined.")


func _act_loan_reset() -> void:
	GameBackend.loan_status = "none"
	GameBackend.loan_debt = 0.0
	GameBackend.loan_decline_reason = ""
	GameBackend.loan_days_left = 0
	GameBackend.stats_changed.emit()
	_say("Loan application reset — you can submit it again.")


func _act_fast_decision() -> void:
	GameBackend.loan_days_left = 1
	GameBackend.allowance_days_left = 1
	_say("Loan and allowance decisions will land on the next day tick.")


func _section_allowance() -> void:
	var f := _section("ALLOWANCE & ACCOMMODATION")
	_btn(f, "Parents WILL qualify", _act_parents_qualify.bind(true), 175)
	_btn(f, "Parents WON'T qualify", _act_parents_qualify.bind(false), 180)
	_btn(f, "Parents confirm now", _act_parents_confirm, 165)
	_btn(f, "Approve allowance", _act_allowance_approve, 155, COL_GOOD)
	_btn(f, "Reset allowance", _act_allowance_reset, 140)
	_btn(f, "Confirm halls (free)", _act_confirm_accom, 160)
	_note("You never see your parents' income — you can't, you're seventeen. The application stalls until they complete their half, which arrives as a text from Mum.")


func _act_parents_qualify(qualifies: bool) -> void:
	GameBackend.household_income = 48000.0 if qualifies else 112000.0
	_say("Parental income set so the allowance %s." % (
		"will be approved" if qualifies else "will be declined"))


func _act_parents_confirm() -> void:
	GameBackend.parents_confirmed_income = true
	GameBackend.stats_changed.emit()
	_say("Parents' section marked complete — assessment can now proceed.")


func _act_allowance_approve() -> void:
	GameBackend.allowance_status = "approved"
	GameBackend.parents_confirmed_income = true
	GameBackend.allowance_weekly = GameBackend.ALLOWANCE_FULL_WEEKLY
	GameBackend.stats_changed.emit()
	_say("Allowance approved at the full rate.")


func _act_allowance_reset() -> void:
	GameBackend.allowance_status = "none"
	GameBackend.allowance_weekly = 0.0
	GameBackend.allowance_received = 0.0
	GameBackend.allowance_days_left = 0
	GameBackend.parents_confirmed_income = false
	GameBackend.stats_changed.emit()
	_say("Allowance reset, including the parental confirmation.")


func _act_confirm_accom() -> void:
	GameBackend.accommodation_choice = "halls"
	GameBackend.accommodation_deposit_paid = true
	GameBackend.stats_changed.emit()
	_say("Halls confirmed with the deposit waived.")


# =============================================================================
# MESSAGES
# =============================================================================

func _section_messages() -> void:
	var f := _section("PHONE & MESSAGES")
	_btn(f, "Deliver 1 random", _act_deliver_one, 140)
	_btn(f, "Deliver ALL", _act_deliver_all, 115)
	_btn(f, "Mark all read", _act_mark_read, 130)
	_btn(f, "Reset inbox", _act_reset_inbox, 120, COL_DANGER)
	_btn(f, "Test toast", _act_test_toast, 115)
	_btn(f, "Force NZQA message", _act_force_nzqa, 165)


func _act_deliver_one() -> void:
	var pool: Array = MessageData.due_ids(GameBackend.TOTAL_DAYS)
	if pool.is_empty():
		_say("No undelivered threads left.")
		return
	var tid: String = str(pool[randi() % pool.size()])
	GameBackend.deliver_message(tid)
	_say("Delivered thread: %s" % tid)


func _act_deliver_all() -> void:
	var n: int = 0
	for t in MessageData.threads:
		var tid: String = str(t.get("id", ""))
		if tid == "" or tid in MessageData.STORY_THREADS:
			continue
		if not GameBackend.has_arrived(tid):
			GameBackend.deliver_message(tid)
			n += 1
	_say("Delivered %d thread(s). Good for checking the inbox scrolls and the badge caps at 9+." % n)


func _act_mark_read() -> void:
	for tid in GameBackend.message_state.keys():
		GameBackend.mark_read(str(tid))
	_say("Inbox marked read — every badge should have cleared.")


func _act_reset_inbox() -> void:
	GameBackend.message_state = {}
	GameBackend.unread_count = 0
	GameBackend.messages_changed.emit()
	_say("All message state wiped, including saved transcripts.")


func _act_test_toast() -> void:
	Notifier.notify("Dev", "Toast layout check", COL_HEAD)
	_say("Fired a test notification.")


func _act_force_nzqa() -> void:
	GameBackend.deliver_message("nzqa_results")
	_say("NZQA results thread pushed to the inbox.")


# =============================================================================
# ENDINGS
# =============================================================================

const ALL_ENDINGS := ["scholarship", "good", "student_loan", "unfunded", "deferred",
	"second_choice", "foundation_year", "no_ue", "bad_deadline", "bad_sanity"]


func _section_endings() -> void:
	var f := _section("JUMP STRAIGHT TO AN ENDING")
	for e in ALL_ENDINGS:
		_btn(f, e, _act_force_ending.bind(e), 125)
	_note("These fire immediately using your CURRENT stats, so the epilogue and the \"why it ended this way\" list describe the run you are actually in. Set grades and money first if you want the reasoning to read sensibly.")


func _act_force_ending(result: String) -> void:
	close()
	GameBackend._end_game(result)


func _section_results() -> void:
	var f := _section("RESULTS SEQUENCE")
	_btn(f, "Trigger results day", _act_trigger_results, 160)
	_btn(f, "Send offer now", _act_send_offer, 140)
	_btn(f, "Preview my ending", _act_preview_ending, 150, COL_GOOD)


func _act_trigger_results() -> void:
	GameBackend.days_remaining = 0
	GameBackend._check_deadline_ending()
	_say("Externals marked and the NZQA message sent. The offer follows on the next day tick.")


func _act_send_offer() -> void:
	GameBackend.results_phase = 1
	GameBackend.release_university_offer()
	_say("Offer delivered. Open it on the phone to close out the run.")


func _act_preview_ending() -> void:
	_say("On current stats you would get: %s" % GameBackend.pending_ending_result().to_upper())


# =============================================================================
# SCENES & INVENTORY
# =============================================================================

const SCENES := {
	"Main map": "res://Main_Game/Scenes/MainMap.tscn",
	"Home": "res://Main_Game/Scenes/HomeScene.tscn",
	"School": "res://Main_Game/Scenes/school_scene.tscn",
	"Work": "res://Main_Game/Scenes/WorkScene.tscn",
	"Canteen": "res://Main_Game/Scenes/CanteenScene.tscn",
	"Dairy": "res://Main_Game/Scenes/DairyScene.tscn",
	"Exam hall": "res://Main_Game/Scenes/ExamHall.tscn",
	"Ending": "res://Main_Game/Scenes/EndingScene.tscn",
}


func _section_scenes() -> void:
	var f := _section("JUMP TO SCENE")
	for label in SCENES:
		_btn(f, label, _act_goto_scene.bind(str(SCENES[label])), 110)


func _act_goto_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		_say("Scene not found: %s" % path)
		return
	close()
	get_tree().change_scene_to_file(path)


func _section_inventory() -> void:
	var f := _section("INVENTORY")
	_btn(f, "Give phone", _act_give.bind("res://Backend/Resource/Items/Phone.tres", "Phone"), 120)
	_btn(f, "Give water bottle", _act_give.bind("res://Backend/Resource/Items/WaterBottle.tres", "Water Bottle"), 150)
	_btn(f, "Refill bottle", _act_refill_bottle, 120)


func _act_give(path: String, label: String) -> void:
	if not ResourceLoader.exists(path):
		_say("Item resource missing: %s" % path)
		return
	if Inventory.add_item(load(path)):
		_say("Added %s to the hotbar." % label)
	else:
		_say("Hotbar is full — drop something first.")


func _act_refill_bottle() -> void:
	GameBackend.refill_water_bottle()
	_say("Water bottle refilled.")


# =============================================================================
# RUN LENGTH
# =============================================================================

func _section_run() -> void:
	var f := _section("RUN LENGTH")
	if GameBackend.test_mode:
		_btn(f, "TEST MODE IS ON — restore the full year", _act_normal_mode, 310, COL_GOOD)
	else:
		_btn(f, "Enable TEST MODE (short year)", _act_test_mode, 310, COL_HEAD)
	_note("Test mode scales every day-count together: run length, exam interval, externals window, the credit threshold, and the StudyLink and accommodation cut-offs. Shortening TOTAL_DAYS on its own is the trap — the absolute deadlines would either never fire or already be in the past on day one.")

	var f2 := _section("DANGER")
	_btn(f2, "Reset entire run", _act_reset_run, 150, COL_DANGER)
	_btn(f2, "Dump state to console", _act_dump_state, 175)


func _act_test_mode() -> void:
	GameBackend.apply_test_mode()
	_say("TEST MODE on: %d-day year, internals every %d days, %d credits per subject, loan closes day %d." % [
		GameBackend.TOTAL_DAYS, GameBackend.EXAM_INTERVAL_DAYS,
		GameBackend.UE_CREDITS_PER_SUBJECT, GameBackend.LOAN_APPLY_CLOSES_DAY])


func _act_normal_mode() -> void:
	GameBackend.restore_normal_mode()
	_say("Back to the full %d-day year." % GameBackend.TOTAL_DAYS)


func _act_reset_run() -> void:
	GameBackend.reset_run()
	_say("Run reset. Test mode and god mode deliberately survive a reset.")


func _act_dump_state() -> void:
	print("=== DEV STATE ===")
	print("day %d/%d   hour %.2f   test_mode=%s" % [
		GameBackend.get_elapsed_days(), GameBackend.TOTAL_DAYS,
		GameBackend.game_hour, GameBackend.test_mode])
	print("money %.2f   savings %.2f   grade %.1f / %.1f" % [
		GameBackend.money, GameBackend.savings_balance,
		GameBackend.get_overall_grade(), GameBackend.required_grade()])
	print("credits ", GameBackend.subject_credits)
	print("prep    ", GameBackend.subject_prep)
	print("loan ", GameBackend.loan_status, "   allowance ", GameBackend.allowance_status)
	print("commitments ", GameBackend.commitments, "  work no-shows ", GameBackend.work_no_shows)
	print("would end as: ", GameBackend.pending_ending_result())
	print("exam schedule:")
	for e in GameBackend.exam_schedule:
		print("   day %d  %s  %s  taken=%s  acc=%.2f" % [
			e.day, e.kind, e.subject, e.taken, e.get("accuracy", 0.0)])
	_say("State dumped to the Output panel.")
