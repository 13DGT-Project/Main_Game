## Sites:
##   MyStudy      StudyLink — apply for the student loan, check the decision,
##                turn weekly living costs on and off
##   NZQA         your credit tally all year, and the full results breakdown
##                once results day comes — including WHY each grade landed
##   Applicant    the university's own portal: application status, and the
##                offer with the reasoning behind it spelled out
##   Fees         what next year actually costs against what you've got
##   Study        online study session (handled by whichever scene opened it)
## The window, title bar, sidebar and scroll area are real nodes you can open
## and edit in the editor. So are the five StyleBoxFlats (window, title bar,
## sidebar, card, callout) — change a colour or a corner radius there and it
## changes everywhere, no code involved.
##
## The PAGE CONTENT is still generated, because it has to be: what's on the
## StudyLink page depends on whether you've applied, the NZQA page depends on
## which subjects you take, and so on. But every generated widget is a
## duplicate() of a hidden template node under Templates/ in the scene — so
## the fonts, sizes and colours of headings, paragraphs, cards and callouts
## are all editable in the inspector too.
extends CanvasLayer

signal study_requested
signal game_requested

const WINDOW_SIZE := Vector2(940, 640)
const SIDEBAR_WIDTH := 200.0

const COL_BG := Color(0.08, 0.09, 0.12, 0.99)
const COL_SIDEBAR := Color(0.11, 0.12, 0.16, 1.0)
const COL_ACCENT := Color(0.35, 0.66, 1.0)
const COL_GOOD := Color(0.35, 0.80, 0.50)
const COL_BAD := Color(0.90, 0.36, 0.36)
const COL_WARN := Color(0.95, 0.72, 0.25)
const COL_MUTED := Color(0.62, 0.66, 0.74)

# --- Scene nodes (see Laptop.tscn) ---------------------------------------------
@onready var _root: Control = $Root
@onready var _window: PanelContainer = $Root/Window
@onready var _title: Label = $Root/Window/Outer/TitleBar/BarRow/Title
@onready var _close_button: Button = $Root/Window/Outer/TitleBar/BarRow/CloseButton
@onready var _nav: VBoxContainer = $Root/Window/Outer/Body/SidePanel/Nav
@onready var _scroll: ScrollContainer = $Root/Window/Outer/Body/Scroll
@onready var _content: VBoxContainer = $Root/Window/Outer/Body/Scroll/Pad/Content

# --- Style templates, duplicated whenever a widget is needed -------------------
@onready var _t_h1: Label = $Templates/H1
@onready var _t_h2: Label = $Templates/H2
@onready var _t_para: Label = $Templates/Para
@onready var _t_card_line: Label = $Templates/CardLine
@onready var _t_nav_header: Label = $Templates/NavHeader
@onready var _t_nav_button: Button = $Templates/NavButton
@onready var _t_action_button: Button = $Templates/ActionButton
@onready var _t_callout: PanelContainer = $Templates/Callout
@onready var _t_card: PanelContainer = $Templates/Card
@onready var _t_card_heading: Label = $Templates/CardHeading

var _is_open: bool = false
var _page: String = "home"

# StudyLink form state, kept between page visits so a half-filled form
# doesn't vanish when you click away.
var _form_ird: String = ""
var _form_fees: bool = true
var _form_living: bool = true
var _form_message: String = ""
var _allowance_message: String = ""
var _accom_message: String = ""
var _pref_message: String = ""
var _show_programmes: bool = false

## The one-off hardship grant can only be claimed once per run.
var _hardship_claimed: bool = false
const HARDSHIP_GRANT: float = 400.0
const HARDSHIP_MONEY_CEILING: float = 150.0


func _ready() -> void:
	# layer and process_mode are set on the scene root in Laptop.tscn.
	_close_button.pressed.connect(close)
	GameBackend.game_ended.connect(_on_game_ended)
	GameBackend.stats_changed.connect(_on_stats_changed)


func _centre_window() -> void:
	var vp: Vector2 = _root.size
	if vp.x <= 0.0:
		vp = get_viewport().get_visible_rect().size
	_window.size = WINDOW_SIZE
	_window.position = ((vp - WINDOW_SIZE) * 0.5).floor()


func open(page: String = "home") -> void:
	Audio.play("open")
	_is_open = true
	_root.visible = true
	_page = page
	_centre_window()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_last_state_key = _state_key()
	_rebuild()


func close() -> void:
	Audio.play("close")
	_is_open = false
	_root.visible = false


func is_open() -> bool:
	return _is_open


func _on_game_ended(_result: String) -> void:
	close()


## What the visible page actually depends on. Rebuilding on every
## stats_changed would be correct but unusable — the signal fires on passive
## decay, and a rebuild recreates the IRD text box, so you'd lose whatever you
## were halfway through typing. Rebuild only when something structural moves.
func _state_key() -> String:
	return "%s|%s|%s|%s|%d|%d" % [
		GameBackend.loan_status, GameBackend.allowance_status,
		GameBackend.accommodation_choice, str(GameBackend.accommodation_deposit_paid),
		GameBackend.results_phase, GameBackend.loan_days_left]

var _last_state_key: String = ""


func _on_stats_changed() -> void:
	if not _is_open:
		return
	var key: String = _state_key()
	if key == _last_state_key:
		return
	_last_state_key = key
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("Escape") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
		close()
		get_viewport().set_input_as_handled()

# NAVIGATION

func _rebuild() -> void:
	_build_nav()
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	match _page:
		"studylink":
			_title.text = "StudyLink — MyStudy"
			_page_studylink()
		"nzqa":
			_title.text = "NZQA — Learner Login"
			_page_nzqa()
		"applicant":
			_title.text = "%s — Applicant Portal" % GameBackend.selected_university
			_page_applicant()
		"accommodation":
			_title.text = "Accommodation Services"
			_page_accommodation()
		"fees":
			_title.text = "Fees & Budget"
			_page_fees()
		_:
			_title.text = "Home"
			_page_home()
	_scroll.scroll_vertical = 0


func _build_nav() -> void:
	for child in _nav.get_children():
		_nav.remove_child(child)
		child.queue_free()

	_nav_header("SITES")
	_nav_button("Home", "home")
	_nav_button("StudyLink", "studylink", _studylink_badge())
	_nav_button("NZQA", "nzqa", "NEW" if GameBackend.results_phase >= 1 else "")
	_nav_button("Applicant Portal", "applicant", "NEW" if GameBackend.results_phase >= 2 else "")
	_nav_button("Accommodation", "accommodation", _accom_badge())
	_nav_button("Fees & Budget", "fees")

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	_nav.add_child(gap)

	_nav_header("DO SOMETHING")

	var study: Button = _action(_nav, "Online study", 0, 34)
	study.pressed.connect(func():
		close()
		study_requested.emit())

	var game: Button = _action(_nav, "Play 'Sequence'", 0, 34)
	game.pressed.connect(func():
		close()
		game_requested.emit())


func _nav_header(text: String) -> void:
	var l: Label = _t_nav_header.duplicate()
	l.visible = true
	l.text = text
	_nav.add_child(l)


func _nav_button(label: String, page: String, badge: String = "") -> void:
	var btn: Button = _t_nav_button.duplicate()
	btn.visible = true
	btn.text = label if badge == "" else "%s   • %s" % [label, badge]
	if page == _page:
		btn.add_theme_color_override("font_color", COL_ACCENT)
	btn.pressed.connect(func():
		Audio.play("click")
		_page = page
		_rebuild())
	_nav.add_child(btn)


func _accom_badge() -> String:
	if GameBackend.accommodation_deposit_paid:
		return "OK"
	if GameBackend.accommodation_choice != "":
		return "PAY"
	return "TODO" if GameBackend.accommodation_applications_open() else "CLOSED"


func _studylink_badge() -> String:
	match GameBackend.loan_status:
		"none":
			return "TODO" if GameBackend.loan_applications_open() else "CLOSED"
		"submitted":
			return "%dd" % GameBackend.loan_days_left
		"approved":
			return "OK"
		"declined":
			return "!"
	return ""

# SHARED WIDGETS

func _h1(text: String) -> void:
	var l: Label = _t_h1.duplicate()
	l.visible = true
	l.text = text
	_content.add_child(l)


func _h2(text: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	_content.add_child(gap)
	var l: Label = _t_h2.duplicate()
	l.visible = true
	l.text = text
	_content.add_child(l)


## `colour` and `size` are overrides on top of the Para template. Pass neither
## and you get exactly what's set on the template in the editor.
func _para(text: String, colour: Color = COL_MUTED, size: int = 14) -> void:
	var l: Label = _t_para.duplicate()
	l.visible = true
	l.text = text
	if colour != COL_MUTED:
		l.add_theme_color_override("font_color", colour)
	if size != 14:
		l.add_theme_font_size_override("font_size", size)
	_content.add_child(l)


func _bullet(text: String, colour: Color = COL_MUTED) -> void:
	_para("   •  " + text, colour, 14)


func _rule() -> void:
	var r := HSeparator.new()
	_content.add_child(r)


## The callout template carries the shape (margins, corners, 4px left border);
## only the two colours are set here, because they change per message.
func _callout(text: String, colour: Color) -> void:
	var box: PanelContainer = _t_callout.duplicate()
	box.visible = true
	var st: StyleBoxFlat = box.get_theme_stylebox("panel").duplicate()
	st.bg_color = Color(colour.r, colour.g, colour.b, 0.13)
	st.border_color = colour
	box.add_theme_stylebox_override("panel", st)
	var l: Label = box.get_node("Text")
	l.text = text
	_content.add_child(box)

# HOME

func _page_home() -> void:
	_h1("Good %s, %s." % [_time_of_day_word(), GameBackend.player_name])
	_para("Day %d of %d. %d days until the end of the year." % [
		GameBackend.get_elapsed_days(), GameBackend.TOTAL_DAYS, GameBackend.days_remaining])

	_h2("What needs doing")
	var todo: Array = []

	match GameBackend.loan_status:
		"none":
			if GameBackend.loan_applications_open():
				todo.append(["StudyLink application not submitted. Applications close on day %d." % GameBackend.LOAN_APPLY_CLOSES_DAY, COL_WARN])
			else:
				todo.append(["StudyLink applications for this year have closed and you never submitted one.", COL_BAD])
		"submitted":
			todo.append(["StudyLink application is being processed — %d day%s to go." % [
				GameBackend.loan_days_left, "" if GameBackend.loan_days_left == 1 else "s"], COL_ACCENT])
		"approved":
			todo.append(["StudyLink loan approved.", COL_GOOD])
		"declined":
			todo.append(["StudyLink declined your application.", COL_BAD])

	if GameBackend.allowance_status == "submitted" and not GameBackend.parents_confirmed_income:
		todo.append(["Student Allowance is stuck waiting on your parents to fill in their section.", COL_WARN])
	if GameBackend.fired_from_work:
		todo.append(["You're off the work roster. No more shifts, no more income.", COL_BAD])
	for c in GameBackend.commitments_today():
		todo.append(["TODAY: %s — you said you'd be there." % str(c.label), COL_WARN])

	if not GameBackend.has_university_entrance():
		todo.append(["University Entrance not yet met — check the NZQA page for exactly what's missing.", COL_WARN])
	else:
		todo.append(["University Entrance requirements met.", COL_GOOD])

	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var fees: float = uni.get("money_needed", 0)
	if GameBackend.money < fees and not GameBackend.loan_covers_fees():
		todo.append(["Fees are $%.0f. You have $%.0f. See Fees & Budget." % [fees, GameBackend.money], COL_WARN])

	var days_exam: int = GameBackend.days_until_next_exam()
	if days_exam == 0:
		todo.append(["You have an exam TODAY.", COL_BAD])
	elif days_exam > 0:
		todo.append(["Next exam in %d day%s." % [days_exam, "" if days_exam == 1 else "s"], COL_MUTED])

	for item in todo:
		_bullet(str(item[0]), item[1])

	_h2("Bookmarks")
	_para("StudyLink — the student loan. Do this early; it takes about a week to come back.")
	_para("NZQA — your credits, and your results when they come out.")
	_para("Applicant Portal — where the offer actually turns up.")
	_para("Fees & Budget — what next year costs, against what you've actually got.")


func _time_of_day_word() -> String:
	var h: float = GameBackend.game_hour
	if h < 12.0:
		return "morning"
	if h < 17.0:
		return "afternoon"
	return "evening"

# STUDYLINK

func _page_studylink() -> void:
	_h1("StudyLink")
	_para("Student loans and allowances.", COL_MUTED, 13)
	_rule()

	# --- the bit everyone gets wrong, said plainly and once
	_callout("Two different things, and people mix them up every year:\n\n" +
		"LOAN — borrowed, repaid later out of your wages, NOT means-tested. If you qualify as a student, you get one.\n\n" +
		"ALLOWANCE — a weekly payment you never repay, but it IS means-tested on your parents' income until you're 24. Most applicants get a reduced rate or nothing.\n\n" +
		"Apply for both. Being declined for the allowance costs you nothing.", COL_ACCENT)

	_h2("Student Loan")
	match GameBackend.loan_status:
		"approved":
			_page_studylink_approved()
		"submitted":
			_page_studylink_submitted()
		"declined":
			_page_studylink_declined()
		_:
			_page_studylink_form()

	_rule()
	_page_allowance()
	_rule()
	_page_hardship_section()


# --- Student Allowance ---------------------------------------------------------

func _page_allowance() -> void:
	_h2("Student Allowance")

	match GameBackend.allowance_status:
		"approved":
			_callout("APPROVED — $%.0f a week.%s\n\nReceived so far: $%.2f, none of it repayable." % [
				GameBackend.allowance_weekly,
				"  (reduced rate — your household income is above the full-rate threshold)" if GameBackend.allowance_weekly < GameBackend.ALLOWANCE_FULL_WEEKLY else "  (full rate)",
				GameBackend.allowance_received], COL_GOOD)
			_para("Paid weekly, straight into your account, for as long as you're studying. This is the good one.")
			return
		"declined":
			_callout("DECLINED.\n\n%s" % GameBackend.allowance_decline_reason, COL_BAD)
			_para("This is the normal outcome for a lot of students, and it says nothing about you. The loan is unaffected — it is not means-tested.")
			return
		"submitted":
			if not GameBackend.parents_confirmed_income:
				_callout("WAITING ON YOUR PARENTS.\n\nYour half is done. StudyLink has emailed them for their income details and nothing happens until they send it back — it's been %d day%s.\n\nGo and message them." % [
					GameBackend.allowance_waiting_days,
					"" if GameBackend.allowance_waiting_days == 1 else "s"], COL_WARN)
				_para("This is the single most common reason an allowance application goes nowhere: not a refusal, just a form sitting in a parent's inbox.")
				return
			_callout("Being assessed. Decision in %d day%s." % [
				GameBackend.allowance_days_left,
				"" if GameBackend.allowance_days_left == 1 else "s"], COL_ACCENT)
			_para("Your parents have sent their part in. Nothing further to do.")
			return

	_para("A weekly payment toward living costs that you do NOT pay back. Full rate is $%.0f a week." % GameBackend.ALLOWANCE_FULL_WEEKLY)
	_para("Means-tested on your parents' combined income while you're under 24. You don't enter that figure and you never see it — StudyLink asks them directly, and you find out the answer at the same time you find out the decision.", COL_MUTED, 13)

	if not GameBackend.loan_applications_open():
		_callout("Applications for this academic year have closed.", COL_BAD)

	var apply: Button = _action(_content, "Apply for the Student Allowance", 280, 38)
	apply.pressed.connect(_on_submit_allowance)

	if _allowance_message != "":
		_callout(_allowance_message, COL_MUTED)


func _on_submit_allowance() -> void:
	# Uses the same IRD number as the loan form, filling it in if you've
	# already looked it up once.
	var ird: String = _form_ird if _form_ird != "" else GameBackend.ird_number
	var result: Array = GameBackend.apply_for_student_allowance(ird)
	_allowance_message = str(result[1])
	if bool(result[0]):
		Audio.play("correct")
		Notifier.notify("StudyLink", "Allowance application submitted", COL_ACCENT)
	else:
		Audio.play("error")
	_rebuild()


func _page_studylink_form() -> void:
	if not GameBackend.loan_applications_open():
		_callout("Applications for the coming academic year closed on day %d.\n\nYou can still submit one, but it will not be processed in time to help with this year's enrolment." % GameBackend.LOAN_APPLY_CLOSES_DAY, COL_BAD)
	else:
		_callout("Applications for the coming academic year close on day %d. Processing takes about %d days, so submitting on the last day is already too late." % [
			GameBackend.LOAN_APPLY_CLOSES_DAY, GameBackend.LOAN_PROCESSING_DAYS], COL_WARN)

	_h2("Apply for a Student Loan")
	_para("A student loan is not automatic and it is not part of your university application. You apply here, separately, and you wait for a decision.")

	_h2("1. Your IRD number")
	_para("Eight or nine digits. It's on any payslip from work.", COL_MUTED, 13)

	var ird := LineEdit.new()
	ird.placeholder_text = "e.g. 123456789"
	ird.text = _form_ird
	ird.custom_minimum_size = Vector2(280, 34)
	ird.text_changed.connect(func(t: String): _form_ird = t)
	_content.add_child(ird)

	var fill_row := HBoxContainer.new()
	fill_row.add_theme_constant_override("separation", 8)
	_content.add_child(fill_row)

	var fill: Button = _action(fill_row, "Look it up for me", 180, 30)
	fill.pressed.connect(func():
		_form_ird = GameBackend.ird_number
		Audio.play("click")
		_rebuild())

	var hint := Label.new()
	hint.text = "It's also on your bank profile — phone, Bank app."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", COL_MUTED)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fill_row.add_child(hint)

	_h2("2. What are you applying for?")

	var fees_box := CheckBox.new()
	fees_box.text = "Course fees — paid direct to the university at enrolment"
	fees_box.button_pressed = _form_fees
	fees_box.toggled.connect(func(on: bool): _form_fees = on)
	_content.add_child(fees_box)

	var living_box := CheckBox.new()
	living_box.text = "Living costs — up to $%.0f paid to you weekly" % GameBackend.LOAN_LIVING_COSTS_WEEKLY
	living_box.button_pressed = _form_living
	living_box.toggled.connect(func(on: bool): _form_living = on)
	_content.add_child(living_box)

	_para("Living costs are money now, and debt later. Course fees are the part that decides whether an offer is one you can actually take up.", COL_MUTED, 13)

	_h2("3. Submit")
	var submit: Button = _action(_content, "Submit application", 220, 40)
	submit.pressed.connect(_on_submit_loan)

	if _form_message != "":
		_callout(_form_message, COL_BAD if _form_message.begins_with("That") or _form_message.begins_with("You have") else COL_GOOD)


func _on_submit_loan() -> void:
	var result: Array = GameBackend.apply_for_student_loan(_form_ird, _form_fees, _form_living)
	_form_message = str(result[1])
	if bool(result[0]):
		Audio.play("correct")
		Notifier.notify("StudyLink", "Application submitted", COL_ACCENT)
	else:
		Audio.play("error")
	_rebuild()


func _page_studylink_submitted() -> void:
	_callout("Application received. A decision usually takes about %d days — %d to go." % [
		GameBackend.LOAN_PROCESSING_DAYS, GameBackend.loan_days_left], COL_ACCENT)
	_h2("Your application")
	var ird_tail: String = GameBackend.loan_ird_number
	if ird_tail.length() > 3:
		ird_tail = ird_tail.substr(ird_tail.length() - 3)
	_bullet("IRD number ending %s" % ird_tail)
	_bullet("Course fees: %s" % ("yes" if GameBackend.loan_wants_fees else "no"))
	_bullet("Living costs: %s" % ("yes" if GameBackend.loan_wants_living_costs else "no"))
	_para("There is nothing else to do here. Go and study.", COL_MUTED, 13)


func _page_studylink_approved() -> void:
	_callout("APPROVED. Your student loan is in place for next year.", COL_GOOD)
	_h2("What you're approved for")
	_bullet("Course fees: %s" % ("YES — paid direct to %s at enrolment" % GameBackend.university_full_name() if GameBackend.loan_wants_fees else "no"),
		COL_GOOD if GameBackend.loan_wants_fees else COL_WARN)
	_bullet("Living costs: %s" % ("YES — $%.0f per week" % GameBackend.LOAN_LIVING_COSTS_WEEKLY if GameBackend.loan_wants_living_costs else "no"))
	_bullet("Borrowed so far: $%.2f" % GameBackend.loan_debt, COL_WARN if GameBackend.loan_debt > 0.0 else COL_MUTED)

	if not GameBackend.loan_wants_fees:
		_callout("Warning: you applied for living costs only. If your savings don't cover the fees, an offer of place still can't be taken up.", COL_BAD)

	_h2("Weekly living costs")
	var toggle: Button = _action(_content, "Turn living costs OFF" if GameBackend.loan_wants_living_costs else "Turn living costs ON", 260, 36)
	toggle.pressed.connect(func():
		GameBackend.set_living_costs(not GameBackend.loan_wants_living_costs)
		Audio.play("click")
		_rebuild())
	_para("Taking living costs each week gives you money to live on now and adds to what you owe later. Turning it off stops the payments immediately.", COL_MUTED, 13)


func _page_studylink_declined() -> void:
	_callout("DECLINED.\n\n%s" % GameBackend.loan_decline_reason, COL_BAD)
	_para("You may reapply for the following academic year. For this year, your options are your own savings, a scholarship, or deferring.")


## One-off emergency grant. Not a loan
func _page_hardship_section() -> void:
	_h2("Hardship grant")
	if _hardship_claimed:
		_para("You've already claimed the one-off hardship grant this year.", COL_MUTED, 13)
		return
	if GameBackend.money > HARDSHIP_MONEY_CEILING:
		_para("Available to students with under $%.0f to their name. You currently have $%.0f, so you don't qualify — which is a good problem." % [
			HARDSHIP_MONEY_CEILING, GameBackend.money], COL_MUTED, 13)
		return
	_para("A one-off payment of $%.0f for students in genuine difficulty. Not repaid, and assessed on YOUR circumstances — your own bank balance, not your parents' income — so there's nothing to look up and nobody to ask." % HARDSHIP_GRANT)
	var claim: Button = _action(_content, "Apply for the grant", 220, 36)
	claim.pressed.connect(func():
		_hardship_claimed = true
		GameBackend.add_money(HARDSHIP_GRANT)
		GameBackend.log_event("Received a $%.0f hardship grant." % HARDSHIP_GRANT)
		Audio.play("cash")
		Notifier.notify("StudyLink", "Hardship grant paid: $%.0f" % HARDSHIP_GRANT, COL_GOOD)
		_rebuild())

# NZQA

func _page_nzqa() -> void:
	_h1("NZQA — Learner Login")
	_para("%s · National Student Number %s" % [
		GameBackend.player_name, str(abs(hash(GameBackend.player_name)) % 100000000).lpad(8, "0")], COL_MUTED, 13)
	_rule()

	if GameBackend.results_phase < 1:
		_h2("Record of Achievement — provisional")
		_para("Externals are not marked until the end of the year. What follows is your internal credit tally so far.")
	else:
		_h2("Record of Achievement — FINAL")

	# --- UE status, front and centre, because it's the thing that decides it
	if GameBackend.has_university_entrance():
		_callout("UNIVERSITY ENTRANCE: ACHIEVED", COL_GOOD)
	elif GameBackend.results_phase >= 1:
		_callout("UNIVERSITY ENTRANCE: NOT ACHIEVED", COL_BAD)
	else:
		_callout("UNIVERSITY ENTRANCE: not yet met on current credits", COL_WARN)

	# Endorsements, right under UE, because this is the line people actually
	# quote about their NCEA for the rest of their lives.
	var cert: String = GameBackend.certificate_endorsement()
	if cert == "Excellence":
		_callout("ENDORSED WITH EXCELLENCE — %d credits at Excellence." % GameBackend.total_credits_at("Excellence"), COL_GOOD)
	elif cert == "Merit":
		_callout("ENDORSED WITH MERIT — %d credits at Merit or better." % GameBackend.total_credits_at("Merit"), COL_GOOD)
	else:
		_callout(GameBackend.certificate_endorsement_progress(), COL_MUTED)

	_h2("Endorsement")
	_para("Certificate endorsement needs %d credits at Merit or better (or %d at Excellence). Note that's %d — the 60 people quote is what you need to ACHIEVE the level, which is a different thing." % [
		GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS, GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS,
		GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS], COL_MUTED, 13)
	_bullet("At Merit or better: %d / %d" % [
		GameBackend.total_credits_at("Merit"), GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS],
		COL_GOOD if GameBackend.total_credits_at("Merit") >= GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS else COL_WARN)
	_bullet("At Excellence: %d / %d" % [
		GameBackend.total_credits_at("Excellence"), GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS],
		COL_GOOD if GameBackend.total_credits_at("Excellence") >= GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS else COL_WARN)

	var endorsed: Dictionary = GameBackend.endorsed_courses()
	if endorsed.is_empty():
		_para("No course endorsements yet. A course endorses at %d credits at Merit or better — but at least %d of those must come from internals and %d from the external, which is the part that catches people out." % [
			GameBackend.COURSE_ENDORSEMENT_CREDITS,
			GameBackend.COURSE_ENDORSEMENT_MIN_PER_SOURCE,
			GameBackend.COURSE_ENDORSEMENT_MIN_PER_SOURCE], COL_MUTED, 13)
	else:
		for subj in endorsed:
			_bullet("%s — course endorsed with %s" % [
				str(subj).capitalize().replace("_", " "), endorsed[subj]], COL_GOOD)

	_h2("Requirements")
	_bullet("%d of %d subjects at %d+ Level 3 credits" % [
		GameBackend.subjects_meeting_credit_threshold(), GameBackend.UE_SUBJECTS_REQUIRED,
		GameBackend.UE_CREDITS_PER_SUBJECT],
		COL_GOOD if GameBackend.subjects_meeting_credit_threshold() >= GameBackend.UE_SUBJECTS_REQUIRED else COL_WARN)
	_bullet("Literacy: %d / %d — achieved in Year 12, carried forward" % [
		GameBackend.literacy_credits, GameBackend.UE_LITERACY_REQUIRED], COL_GOOD)
	_bullet("Numeracy: %d / %d — achieved in Year 12, carried forward" % [
		GameBackend.numeracy_credits, GameBackend.UE_NUMERACY_REQUIRED], COL_GOOD)
	_bullet("Total Level 3 credits this year: %d" % GameBackend.total_credits())
	_para("Literacy and numeracy were banked last year, like they are for most people. The only thing left between you and University Entrance is %d credits in %d subjects." % [
		GameBackend.UE_CREDITS_PER_SUBJECT, GameBackend.UE_SUBJECTS_REQUIRED], COL_MUTED, 13)

	var shortfalls: Array = GameBackend.ue_shortfall_reasons()
	if not shortfalls.is_empty():
		_h2("What's missing, and why")
		for r in shortfalls:
			_para(str(r), Color(0.90, 0.66, 0.45), 14)

	# --- per subject
	_h2("By subject")
	for subject in GameBackend.active_subjects:
		_subject_card(subject)


func _subject_card(subject: String) -> void:
	var d: Dictionary = GameBackend.subject_result_detail(subject)

	var card: PanelContainer = _make_card()
	var col: VBoxContainer = card.get_node("Column")
	var endorsement: String = GameBackend.course_endorsement(subject)
	_card_heading(col, "%s — %d credits, grade %.0f, revision %.0f%%%s" % [
		str(subject).capitalize().replace("_", " "), d.credits, d.grade,
		GameBackend.get_prep(subject),
		"   ★ %s" % endorsement.to_upper() if endorsement != "" else ""],
		COL_GOOD if d.credits >= GameBackend.UE_CREDITS_PER_SUBJECT else COL_WARN)

	# Internals
	if not d.internals.is_empty():
		var itext: Array = []
		for r in d.internals:
			if r.taken:
				itext.append("day %d: %s (%.0f%%)" % [r.day, r.band, r.accuracy * 100.0])
			else:
				itext.append("day %d: absent" % r.day)
		_card_line(col, "Internals — " + "  ·  ".join(itext))

	# Externals
	if not d.externals.is_empty():
		var etext: Array = []
		for r in d.externals:
			if GameBackend.results_phase < 1:
				etext.append("day %d: sealed" % r.day)
			elif r.taken:
				etext.append("day %d: %s (%.0f%%)%s" % [r.day, r.band, r.accuracy * 100.0,
					" [derived]" if r.derived else ""])
			else:
				etext.append("day %d: ABSENT" % r.day)
		_card_line(col, "Externals — " + "  ·  ".join(etext))

	for w in d.why:
		_card_line(col, "· " + str(w), Color(0.72, 0.76, 0.84))
	_card_line(col, "· If you sat it today: %s" % GameBackend.predicted_band(subject),
		Color(0.62, 0.80, 0.95))

	_content.add_child(card)


## A card, cloned from the Card template. Pass an accent to give it the 4px
## left stripe used for the currently-selected accommodation option.
func _make_card(accent: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var card: PanelContainer = _t_card.duplicate()
	card.visible = true
	if accent.a > 0.0:
		var st: StyleBoxFlat = card.get_theme_stylebox("panel").duplicate()
		st.border_width_left = 4
		st.border_color = accent
		card.add_theme_stylebox_override("panel", st)
	return card


func _card_heading(col: VBoxContainer, text: String, colour: Color) -> void:
	var head: Label = _t_card_heading.duplicate()
	head.visible = true
	head.text = text
	head.add_theme_color_override("font_color", colour)
	col.add_child(head)


## An action button, cloned from the ActionButton template so every button on
## every page shares one look you can change in the editor.
func _action(parent: Node, text: String, width: float = 220.0, height: float = 36.0) -> Button:
	var b: Button = _t_action_button.duplicate()
	b.visible = true
	b.text = text
	b.custom_minimum_size = Vector2(width, height)
	parent.add_child(b)
	return b


func _card_line(col: VBoxContainer, text: String, colour: Color = COL_MUTED) -> void:
	var l: Label = _t_card_line.duplicate()
	l.visible = true
	l.text = text
	if colour != COL_MUTED:
		l.add_theme_color_override("font_color", colour)
	col.add_child(l)

# APPLICANT PORTAL

func _page_applicant() -> void:
	_h1("%s" % GameBackend.university_full_name().capitalize())
	_para("Applicant Portal · %s" % GameBackend.player_name, COL_MUTED, 13)
	_rule()

	var degree: String = GameBackend.selected_conjoint if GameBackend.selected_conjoint != "" else GameBackend.selected_major
	_h2("Your application")
	_bullet("Programme: %s" % (degree if degree != "" else "not selected"))
	_bullet("Entry standard: %.0f academic average%s" % [
		GameBackend.required_grade(),
		" (includes conjoint surcharge)" if GameBackend.selected_conjoint != "" else ""])
	_bullet("Current average: %.0f" % GameBackend.get_overall_grade())
	_bullet("Tuition for year one: $%.0f" % GameBackend.universities.get(GameBackend.selected_university, {}).get("money_needed", 0))

	var missing: Array = GameBackend.missing_required_subjects()
	if not missing.is_empty():
		_callout("This programme expects %s, and you aren't taking %s. Entry average raised by %.0f as a result." % [
			_pretty_subjects(GameBackend.programme_required_subjects()),
			_pretty_subjects(missing),
			float(missing.size()) * GameBackend.MISSING_SUBJECT_PENALTY], COL_WARN)

	if GameBackend.can_change_preference():
		_page_change_preference()

	if GameBackend.results_phase < 2:
		_h2("Status")
		if GameBackend.results_phase == 1:
			_callout("Results received from NZQA. Your application is under assessment — a decision is usually made within a day.", COL_ACCENT)
		else:
			_callout("UNDER CONSIDERATION — pending final NCEA results.\n\nAll offers are conditional on University Entrance being achieved.", COL_MUTED)
		_para("Nothing to do here until results day. Which is the worst possible thing for a website to say to someone in your position.", COL_MUTED, 13)
		return

	# --- the decision
	var result: String = GameBackend.pending_ending_result()
	var good: bool = result in ["scholarship", "good", "student_loan", "deferred"]
	var partial: bool = result in ["second_choice", "foundation_year"]
	_h2("Decision")
	_callout(GameBackend.offer_message(), COL_GOOD if good else (COL_WARN if partial else COL_BAD))

	_h2("How this decision was reached")
	for r in GameBackend.offer_reasons():
		_para("· " + str(r), Color(0.78, 0.82, 0.88), 14)

	_h2("What happens now")
	match result:
		"scholarship", "good", "student_loan":
			_para("Accept your offer, sort accommodation, and enrol before the deadline. Congratulations — genuinely.")
		"deferred":
			_para("Your place is held for one year. There is nothing further to do, and nothing further you should be doing.")
		"unfunded":
			_para("The offer stands but cannot be taken up without funding. Reapply to StudyLink for the following year, or work and self-fund.")
		"second_choice":
			_para("You will receive a separate offer from the other institution. Preferences can be re-ranked next year.")
		"foundation_year":
			_para("A foundation programme is a full year of study with guaranteed entry to the degree on completion.")
		"no_ue":
			_para("University Entrance can be completed the following year, either at school or through a tertiary bridging programme. It is not the end of it.")
		_:
			_para("You may reapply next year. Many applicants do, and are admitted.")


# FEES & BUDGET

func _page_fees() -> void:
	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var fees: float = uni.get("money_needed", 0)
	var have: float = GameBackend.money + GameBackend.savings_balance + GameBackend.term_deposit_amount
	var gap: float = fees - have

	_h1("Fees & Budget")
	_rule()

	_h2("Year one at %s" % GameBackend.university_full_name())
	_bullet("Tuition: $%.0f" % fees)
	_bullet("Accommodation: not included — halls run around $18,000, flatting is cheaper")
	_bullet("You need the tuition covered before you can enrol. Nothing else is enforced.")

	_h2("What you've got")
	_bullet("Wallet: $%.2f" % GameBackend.money)
	_bullet("Savings: $%.2f" % GameBackend.savings_balance)
	if GameBackend.term_deposit_amount > 0.0:
		_bullet("Term deposit: $%.2f (matures in %d days)" % [
			GameBackend.term_deposit_amount, GameBackend.term_deposit_days_left])
	_bullet("Total: $%.2f" % have, COL_ACCENT)

	_h2("The gap")
	if gap <= 0.0:
		_callout("You're covered. Tuition is $%.0f and you have $%.2f. You could enrol tomorrow." % [fees, have], COL_GOOD)
	elif GameBackend.loan_covers_fees():
		_callout("Short by $%.2f — but your approved StudyLink loan covers course fees, so the gap doesn't block your enrolment." % gap, COL_GOOD)
	else:
		_callout("Short by $%.2f, with no approved loan covering fees.\n\nAt your current earnings that's roughly %d more shifts." % [
			gap, _shifts_needed(gap)], COL_BAD)

	_h2("Earning rate")
	if GameBackend.stat_shifts > 0:
		var per_shift: float = GameBackend.stat_earned / float(GameBackend.stat_shifts)
		_bullet("%d shifts worked, $%.2f earned — about $%.2f a shift." % [
			GameBackend.stat_shifts, GameBackend.stat_earned, per_shift])
		_bullet("%d days left in the year." % GameBackend.days_remaining)
	else:
		_bullet("You haven't worked a shift yet, so there's nothing to project from.")

	_h2("The honest summary")
	if gap <= 0.0:
		_para("You've done the money part. Spend the remaining days on credits, not shifts.")
	elif GameBackend.loan_status == "approved":
		_para("The loan has this covered. Extra shifts now cost you study time and buy you very little.")
	elif GameBackend.loan_status == "submitted":
		_para("Wait for the StudyLink decision before you panic about the gap. It'll be back in %d days." % GameBackend.loan_days_left)
	elif GameBackend.loan_applications_open():
		_para("You are not going to close a $%.0f gap with shifts. Apply to StudyLink — it's on the sidebar and it takes twenty minutes." % gap)
	else:
		_para("Applications have closed. This is now a savings problem, and $%.0f is a lot of shifts. Consider whether a foundation year or a deferred start is the better plan." % gap)


func _shifts_needed(gap: float) -> int:
	var per_shift: float = 100.0
	if GameBackend.stat_shifts > 0:
		per_shift = max(20.0, GameBackend.stat_earned / float(GameBackend.stat_shifts))
	return int(ceil(gap / per_shift))


func _pretty_subjects(items: Array) -> String:
	var out: Array = []
	for i in items:
		out.append(str(i).capitalize().replace("_", " "))
	return ", ".join(out)


# --- Changing your mind --------------------------------------------------------
# A preference is a preference. You can move it right up until results are
# released, which is how it works in real life and how it should work here.

func _page_change_preference() -> void:
	_h2("Change your preference")
	_para("You can change your university and your programme at any point before results are released. Your SUBJECTS are fixed — you chose those last year — so switching to a programme your subjects don't support raises the average you'll need.", COL_MUTED, 13)

	if _pref_message != "":
		_callout(_pref_message, COL_ACCENT)

	# --- university
	var uni_label := Label.new()
	uni_label.text = "First preference university"
	uni_label.add_theme_font_size_override("font_size", 14)
	_content.add_child(uni_label)

	var uni_row := HBoxContainer.new()
	uni_row.add_theme_constant_override("separation", 8)
	_content.add_child(uni_row)
	for key in GameBackend.universities:
		var data: Dictionary = GameBackend.universities[key]
		var b: Button = _action(uni_row, "%s\n%.0f%% · $%.0f" % [key, data.get("grades_needed", 0), data.get("money_needed", 0)], 180, 52)
		b.add_theme_font_size_override("font_size", 13)
		if key == GameBackend.selected_university:
			b.disabled = true
			b.add_theme_color_override("font_color_disabled", COL_ACCENT)
		b.pressed.connect(func():
			var r: Array = GameBackend.change_university(key)
			_pref_message = str(r[1])
			Audio.play("click" if bool(r[0]) else "error")
			_rebuild())

	# --- programme
	var toggle: Button = _action(_content, "Hide programme list" if _show_programmes else "Change programme...", 240, 34)
	toggle.pressed.connect(func():
		_show_programmes = not _show_programmes
		_rebuild())

	if not _show_programmes:
		return

	_para("Single degrees", COL_MUTED, 13)
	for major in GameBackend.MAJORS:
		_programme_button(major, GameBackend.MAJORS[major], 0.0)

	_para("Conjoint degrees — two at once, higher average required", COL_MUTED, 13)
	for conj in GameBackend.CONJOINTS:
		var d: Dictionary = GameBackend.CONJOINTS[conj]
		_programme_button(conj, d.get("subjects", []), d.get("grade_bonus_required", 0.0))


func _programme_button(programme: String, subjects: Array, bonus: float) -> void:
	# Show up-front how well your actual subjects fit, so the choice is
	# informed rather than a guess.
	var missing: Array = []
	for sub in subjects:
		if not sub in GameBackend.active_subjects:
			missing.append(sub)

	var suffix: String = ""
	if bonus > 0.0:
		suffix += "  (+%.0f)" % bonus
	if missing.is_empty():
		suffix += "   ✓ your subjects cover this"
	else:
		suffix += "   ⚠ missing %s  (+%.0f)" % [
			_pretty_subjects(missing), float(missing.size()) * GameBackend.MISSING_SUBJECT_PENALTY]

	var b: Button = _action(_content, "%s%s" % [programme, suffix], 640, 36)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 13)
	if missing.is_empty():
		b.add_theme_color_override("font_color", COL_GOOD)
	elif missing.size() >= 3:
		b.add_theme_color_override("font_color", COL_BAD)
	else:
		b.add_theme_color_override("font_color", COL_WARN)
	var current: String = GameBackend.selected_conjoint if GameBackend.selected_conjoint != "" else GameBackend.selected_major
	if programme == current:
		b.disabled = true
	b.pressed.connect(func():
		var r: Array = GameBackend.change_programme(programme)
		_pref_message = str(r[1])
		_show_programmes = false
		Audio.play("click" if bool(r[0]) else "error")
		_rebuild())


# ACCOMMODATION

func _page_accommodation() -> void:
	_h1("Accommodation Services")
	_para("Where you're actually going to sleep next year.", COL_MUTED, 13)
	_rule()

	if GameBackend.accommodation_deposit_paid:
		_callout("CONFIRMED — %s. Deposit paid." % str(GameBackend.ACCOMMODATION[GameBackend.accommodation_choice].label), COL_GOOD)
	elif GameBackend.accommodation_choice != "":
		_callout("Preference recorded but NOT confirmed. Until the deposit is paid, nothing is held for you." , COL_WARN)
	elif GameBackend.accommodation_applications_open():
		_callout("No preference recorded. Applications close on day %d — before your offer arrives, which catches people out every year." % GameBackend.ACCOM_APPLY_CLOSES_DAY, COL_WARN)
	else:
		_callout("Applications for next year have closed and you never recorded a preference.", COL_BAD)

	if _accom_message != "":
		_callout(_accom_message, COL_ACCENT)

	_h2("Options")
	for key in GameBackend.ACCOMMODATION:
		_accommodation_card(key)

	# --- confirm
	if GameBackend.accommodation_choice != "" and not GameBackend.accommodation_deposit_paid and GameBackend.accommodation_applications_open():
		_h2("Confirm your place")
		var dep: float = GameBackend.ACCOMMODATION[GameBackend.accommodation_choice].get("deposit", 0.0)
		_para("A deposit of $%.0f confirms it. You have $%.2f." % [dep, GameBackend.money])
		var confirm: Button = _action(_content, "Pay $%.0f deposit" % dep, 240, 38)
		confirm.pressed.connect(func():
			var r: Array = GameBackend.confirm_accommodation()
			_accom_message = str(r[1])
			if bool(r[0]):
				Audio.play("cash")
				Notifier.notify("Accommodation", "Deposit paid — place confirmed", COL_GOOD)
			else:
				Audio.play("error")
			_rebuild())

	_h2("The honest note")
	_para("Accommodation doesn't affect your grades or your offer. It affects whether the offer is one you can physically take up, and it costs money you might otherwise be putting toward fees. That's the whole trade-off.")


func _accommodation_card(key: String) -> void:
	var data: Dictionary = GameBackend.ACCOMMODATION[key]
	var chosen: bool = GameBackend.accommodation_choice == key

	var card: PanelContainer = _make_card(COL_ACCENT if chosen else Color(0, 0, 0, 0))
	var col: VBoxContainer = card.get_node("Column")
	_card_heading(col, "%s — $%.0f deposit, about $%.0f a year" % [
		str(data.label), data.get("deposit", 0.0), data.get("year_cost", 0.0)],
		COL_ACCENT if chosen else Color(0.88, 0.90, 0.94))

	_card_line(col, str(data.blurb))

	if not chosen and GameBackend.accommodation_applications_open():
		var pick: Button = _action(col, "Make this my preference", 220, 32)
		pick.pressed.connect(func():
			var r: Array = GameBackend.choose_accommodation(key)
			_accom_message = str(r[1])
			Audio.play("click" if bool(r[0]) else "error")
			_rebuild())

	_content.add_child(card)
