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
## Whether the last submit worked — decides the message colour. (It used to
## check whether the message began with "That" or "You have", which only
## works in English.)
var _form_ok: bool = false
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
			_title.text = tr("LAPTOP_STUDYLINK") + " — MyStudy"
			_page_studylink()
		"nzqa":
			_title.text = tr("LAPTOP_NZQA") + " — " + tr("LAPTOP_LEARNER_LOGIN")
			_page_nzqa()
		"applicant":
			_title.text = "%s — %s" % [GameBackend.university_name(GameBackend.selected_university), tr("LAPTOP_APPLICANT")]
			_page_applicant()
		"accommodation":
			_title.text = tr("LAPTOP_ACCOMMODATION")
			_page_accommodation()
		"fees":
			_title.text = tr("LAPTOP_FEES")
			_page_fees()
		_:
			_title.text = tr("LAPTOP_HOME")
			_page_home()
	_scroll.scroll_vertical = 0


func _build_nav() -> void:
	for child in _nav.get_children():
		_nav.remove_child(child)
		child.queue_free()

	_nav_header(tr("LAPTOP_SITES"))
	_nav_button(tr("LAPTOP_HOME"), "home")
	_nav_button(tr("LAPTOP_STUDYLINK"), "studylink", _studylink_badge())
	_nav_button(tr("LAPTOP_NZQA"), "nzqa", tr("BADGE_NEW") if GameBackend.results_phase >= 1 else "")
	_nav_button(tr("LAPTOP_APPLICANT"), "applicant", tr("BADGE_NEW") if GameBackend.results_phase >= 2 else "")
	_nav_button(tr("LAPTOP_ACCOMMODATION"), "accommodation", _accom_badge())
	_nav_button(tr("LAPTOP_FEES"), "fees")

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	_nav.add_child(gap)

	_nav_header(tr("LAPTOP_DO_SOMETHING"))

	var study: Button = _action(_nav, tr("LAPTOP_ONLINE_STUDY"), 0, 34)
	study.pressed.connect(func():
		close()
		study_requested.emit())

	var game: Button = _action(_nav, tr("LAPTOP_PLAY_GAME"), 0, 34)
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
		return tr("BADGE_OK")
	if GameBackend.accommodation_choice != "":
		return tr("BADGE_PAY")
	return tr("BADGE_TODO") if GameBackend.accommodation_applications_open() else tr("BADGE_CLOSED")


func _studylink_badge() -> String:
	match GameBackend.loan_status:
		"none":
			return tr("BADGE_TODO") if GameBackend.loan_applications_open() else tr("BADGE_CLOSED")
		"submitted":
			return tr("BADGE_DAYS") % GameBackend.loan_days_left
		"approved":
			return tr("BADGE_OK")
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
	_h1(tr(_greeting_key()) % GameBackend.player_name)
	_para(tr("HUD_DAY_OF") % [GameBackend.get_elapsed_days(), GameBackend.TOTAL_DAYS] + "  ·  " + tr("HUD_DAYS_LEFT") % GameBackend.days_remaining)

	_h2(tr("LAPTOP_TODO"))
	var todo: Array = []

	match GameBackend.loan_status:
		"none":
			if GameBackend.loan_applications_open():
				todo.append([tr("TODO_LOAN_NONE") % GameBackend.LOAN_APPLY_CLOSES_DAY, COL_WARN])
			else:
				todo.append([tr("TODO_LOAN_CLOSED"), COL_BAD])
		"submitted":
			todo.append([GameBackend.plural("TODO_LOAN_PROCESSING", GameBackend.loan_days_left) % GameBackend.loan_days_left, COL_ACCENT])
		"approved":
			todo.append([tr("TODO_LOAN_APPROVED"), COL_GOOD])
		"declined":
			todo.append([tr("TODO_LOAN_DECLINED"), COL_BAD])

	if GameBackend.allowance_status == "submitted" and not GameBackend.parents_confirmed_income:
		todo.append([tr("TODO_ALLOW_STUCK"), COL_WARN])
	if GameBackend.fired_from_work:
		todo.append([tr("TODO_FIRED"), COL_BAD])
	for c in GameBackend.commitments_today():
		todo.append([tr("TODO_COMMIT_TODAY") % str(c.label), COL_WARN])

	if not GameBackend.has_university_entrance():
		todo.append([tr("TODO_UE_NOT_MET"), COL_WARN])
	else:
		todo.append([tr("TODO_UE_MET"), COL_GOOD])

	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var fees: float = uni.get("money_needed", 0)
	if GameBackend.money < fees and not GameBackend.loan_covers_fees():
		todo.append([tr("TODO_FEES") % [fees, GameBackend.money], COL_WARN])

	var days_exam: int = GameBackend.days_until_next_exam()
	if days_exam == 0:
		todo.append([tr("TODO_EXAM_TODAY"), COL_BAD])
	elif days_exam > 0:
		todo.append([GameBackend.plural("TODO_NEXT_EXAM", days_exam) % days_exam, COL_MUTED])

	for item in todo:
		_bullet(str(item[0]), item[1])

	_h2(tr("LAPTOP_BOOKMARKS"))
	_para(tr("BOOKMARK_STUDYLINK"))
	_para(tr("BOOKMARK_NZQA"))
	_para(tr("BOOKMARK_APPLICANT"))
	_para(tr("BOOKMARK_FEES"))


func _greeting_key() -> String:
	var h: float = GameBackend.game_hour
	if h < 12.0:
		return "LAPTOP_GOOD_MORNING"
	if h < 17.0:
		return "LAPTOP_GOOD_AFTERNOON"
	return "LAPTOP_GOOD_EVENING"

# STUDYLINK

func _page_studylink() -> void:
	_h1(tr("LAPTOP_STUDYLINK"))
	_para(tr("SL_PAGE_SUB"), COL_MUTED, 13)
	_rule()

	# --- the bit everyone gets wrong, said plainly and once
	_callout(tr("SL_EXPLAINER"), COL_ACCENT)

	_h2(tr("SL_LOAN_HEAD"))
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
	_h2(tr("SL_ALLOW_HEAD"))

	match GameBackend.allowance_status:
		"approved":
			_callout(tr("SL_PAGE_ALLOW_APPROVED") % [
				GameBackend.allowance_weekly,
				tr("SL_PAGE_RATE_REDUCED") if GameBackend.allowance_weekly < GameBackend.ALLOWANCE_FULL_WEEKLY else tr("SL_PAGE_RATE_FULL"),
				GameBackend.allowance_received], COL_GOOD)
			_para(tr("SL_PAGE_ALLOW_GOOD"))
			return
		"declined":
			_callout(tr("SL_DECLINED") + ".\n\n%s" % GameBackend.allowance_decline_reason, COL_BAD)
			_para(tr("SL_PAGE_ALLOW_DECLINED"))
			return
		"submitted":
			if not GameBackend.parents_confirmed_income:
				_callout(GameBackend.plural("SL_PAGE_WAITING", GameBackend.allowance_waiting_days) % GameBackend.allowance_waiting_days, COL_WARN)
				_para(tr("SL_PAGE_WAITING_NOTE"))
				return
			_callout(GameBackend.plural("SL_ASSESSING", GameBackend.allowance_days_left) % GameBackend.allowance_days_left, COL_ACCENT)
			_para(tr("SL_PAGE_PARENTS_SENT"))
			return

	_para(tr("SL_PAGE_ALLOW_INFO") % GameBackend.ALLOWANCE_FULL_WEEKLY)
	_para(tr("SL_PAGE_ALLOW_MEANS"), COL_MUTED, 13)

	if not GameBackend.loan_applications_open():
		_callout(tr("SL_PAGE_CLOSED"), COL_BAD)

	var apply: Button = _action(_content, tr("SL_APPLY_ALLOWANCE"), 280, 38)
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
		Notifier.notify(tr("LAPTOP_STUDYLINK"), tr("NOTIF_ALLOW_SUBMITTED"), COL_ACCENT)
	else:
		Audio.play("error")
	_rebuild()


func _page_studylink_form() -> void:
	if not GameBackend.loan_applications_open():
		_callout(tr("SL_FORM_CLOSED") % GameBackend.LOAN_APPLY_CLOSES_DAY, COL_BAD)
	else:
		_callout(tr("SL_FORM_OPEN") % [
			GameBackend.LOAN_APPLY_CLOSES_DAY, GameBackend.LOAN_PROCESSING_DAYS], COL_WARN)

	_h2(tr("SL_APPLY_LOAN"))
	_para(tr("SL_FORM_INTRO"))

	_h2("1. " + tr("SL_IRD_LABEL"))
	_para(tr("SL_IRD_HINT"), COL_MUTED, 13)

	var ird := LineEdit.new()
	ird.placeholder_text = tr("SL_IRD_PLACEHOLDER")
	ird.text = _form_ird
	ird.custom_minimum_size = Vector2(280, 34)
	ird.text_changed.connect(func(t: String): _form_ird = t)
	_content.add_child(ird)

	var fill_row := HBoxContainer.new()
	fill_row.add_theme_constant_override("separation", 8)
	_content.add_child(fill_row)

	var fill: Button = _action(fill_row, tr("SL_LOOK_UP"), 180, 30)
	fill.pressed.connect(func():
		_form_ird = GameBackend.ird_number
		Audio.play("click")
		_rebuild())

	var hint := Label.new()
	hint.text = tr("SL_IRD_BANK_HINT")
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", COL_MUTED)
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fill_row.add_child(hint)

	_h2(tr("SL_FORM_STEP2"))

	var fees_box := CheckBox.new()
	fees_box.text = tr("SL_FORM_FEES_BOX")
	fees_box.button_pressed = _form_fees
	fees_box.toggled.connect(func(on: bool): _form_fees = on)
	_content.add_child(fees_box)

	var living_box := CheckBox.new()
	living_box.text = tr("SL_FORM_LIVING_BOX") % GameBackend.LOAN_LIVING_COSTS_WEEKLY
	living_box.button_pressed = _form_living
	living_box.toggled.connect(func(on: bool): _form_living = on)
	_content.add_child(living_box)

	_para(tr("SL_FORM_NOTE"), COL_MUTED, 13)

	_h2(tr("SL_FORM_STEP3"))
	var submit: Button = _action(_content, tr("SL_SUBMIT"), 220, 40)
	submit.pressed.connect(_on_submit_loan)

	if _form_message != "":
		_callout(_form_message, COL_GOOD if _form_ok else COL_BAD)


func _on_submit_loan() -> void:
	var result: Array = GameBackend.apply_for_student_loan(_form_ird, _form_fees, _form_living)
	_form_message = str(result[1])
	_form_ok = bool(result[0])
	if bool(result[0]):
		Audio.play("correct")
		Notifier.notify(tr("LAPTOP_STUDYLINK"), tr("NOTIF_SUBMITTED"), COL_ACCENT)
	else:
		Audio.play("error")
	_rebuild()


func _page_studylink_submitted() -> void:
	_callout(tr("SL_SUBMITTED_INFO") % [
		GameBackend.LOAN_PROCESSING_DAYS, GameBackend.loan_days_left], COL_ACCENT)
	_h2(tr("SL_YOUR_APPLICATION"))
	var ird_tail: String = GameBackend.loan_ird_number
	if ird_tail.length() > 3:
		ird_tail = ird_tail.substr(ird_tail.length() - 3)
	_bullet(tr("SL_IRD_ENDING") % ird_tail)
	_bullet(tr("SL_COURSE_FEES") + ": " + tr("COMMON_YES" if GameBackend.loan_wants_fees else "COMMON_NO"))
	_bullet(tr("SL_LIVING_COSTS") + ": " + tr("COMMON_YES" if GameBackend.loan_wants_living_costs else "COMMON_NO"))
	_para(tr("SL_NOTHING_ELSE"), COL_MUTED, 13)


func _page_studylink_approved() -> void:
	_callout(tr("SL_PAGE_APPROVED"), COL_GOOD)
	_h2(tr("SL_APPROVED_FOR"))
	_bullet(tr("SL_COURSE_FEES") + ": " + (tr("SL_APPROVED_FEES_YES") % GameBackend.university_full_name() if GameBackend.loan_wants_fees else tr("COMMON_NO")),
		COL_GOOD if GameBackend.loan_wants_fees else COL_WARN)
	_bullet(tr("SL_LIVING_COSTS") + ": " + (tr("SL_APPROVED_LIVING_YES") % GameBackend.LOAN_LIVING_COSTS_WEEKLY if GameBackend.loan_wants_living_costs else tr("COMMON_NO")))
	_bullet(tr("SL_BORROWED_SO_FAR") % GameBackend.loan_debt, COL_WARN if GameBackend.loan_debt > 0.0 else COL_MUTED)

	if not GameBackend.loan_wants_fees:
		_callout(tr("SL_WARN_LIVING_ONLY"), COL_BAD)

	_h2(tr("SL_WEEKLY_LIVING"))
	var toggle: Button = _action(_content, tr("SL_LIVING_OFF") if GameBackend.loan_wants_living_costs else tr("SL_LIVING_ON"), 260, 36)
	toggle.pressed.connect(func():
		GameBackend.set_living_costs(not GameBackend.loan_wants_living_costs)
		Audio.play("click")
		_rebuild())
	_para(tr("SL_LIVING_NOTE"), COL_MUTED, 13)


func _page_studylink_declined() -> void:
	_callout(tr("SL_DECLINED") + ".\n\n%s" % GameBackend.loan_decline_reason, COL_BAD)
	_para(tr("SL_DECLINED_NOTE"))


## One-off emergency grant. Not a loan
func _page_hardship_section() -> void:
	_h2(tr("SL_HARDSHIP"))
	if _hardship_claimed:
		_para(tr("SL_HARDSHIP_CLAIMED"), COL_MUTED, 13)
		return
	if GameBackend.money > HARDSHIP_MONEY_CEILING:
		_para(tr("SL_HARDSHIP_RICH") % [
			HARDSHIP_MONEY_CEILING, GameBackend.money], COL_MUTED, 13)
		return
	_para(tr("SL_HARDSHIP_INFO") % HARDSHIP_GRANT)
	var claim: Button = _action(_content, tr("SL_CLAIM_GRANT"), 220, 36)
	claim.pressed.connect(func():
		_hardship_claimed = true
		GameBackend.add_money(HARDSHIP_GRANT)
		GameBackend.log_event(tr("LOG_HARDSHIP") % HARDSHIP_GRANT)
		Audio.play("cash")
		Notifier.notify(tr("LAPTOP_STUDYLINK"), tr("NOTIF_HARDSHIP") % HARDSHIP_GRANT, COL_GOOD)
		_rebuild())

# NZQA

func _page_nzqa() -> void:
	_h1(tr("LAPTOP_NZQA") + " — " + tr("LAPTOP_LEARNER_LOGIN"))
	_para(tr("NZQA_NSN") % [
		GameBackend.player_name, str(abs(hash(GameBackend.player_name)) % 100000000).lpad(8, "0")], COL_MUTED, 13)
	_rule()

	if GameBackend.results_phase < 1:
		_h2(tr("NZQA_ROA_PROVISIONAL"))
		_para(tr("NZQA_EXTERNALS_PENDING"))
	else:
		_h2(tr("NZQA_ROA_FINAL"))

	# --- UE status, front and centre, because it's the thing that decides it
	if GameBackend.has_university_entrance():
		_callout(tr("NCEA_UE_ACHIEVED"), COL_GOOD)
	elif GameBackend.results_phase >= 1:
		_callout(tr("NCEA_UE_NOT_ACHIEVED"), COL_BAD)
	else:
		_callout(tr("NZQA_UE_NOT_YET"), COL_WARN)

	# Endorsements, right under UE, because this is the line people actually
	# quote about their NCEA for the rest of their lives.
	var cert: String = GameBackend.certificate_endorsement()
	if cert == "Excellence":
		_callout((tr("NCEA_ENDORSED_EXCELLENCE") + " — %d " + tr("COMMON_CREDITS")) % GameBackend.total_credits_at("Excellence"), COL_GOOD)
	elif cert == "Merit":
		_callout((tr("NCEA_ENDORSED_MERIT") + " — %d " + tr("COMMON_CREDITS")) % GameBackend.total_credits_at("Merit"), COL_GOOD)
	else:
		_callout(GameBackend.certificate_endorsement_progress(), COL_MUTED)

	_h2(tr("NCEA_ENDORSEMENT"))
	_para(tr("NZQA_CERT_EXPLAIN") % [
		GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS, GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS,
		GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS], COL_MUTED, 13)
	_bullet(tr("NZQA_AT_MERIT") % [
		GameBackend.total_credits_at("Merit"), GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS],
		COL_GOOD if GameBackend.total_credits_at("Merit") >= GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS else COL_WARN)
	_bullet(tr("NZQA_AT_EXCELLENCE") % [
		GameBackend.total_credits_at("Excellence"), GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS],
		COL_GOOD if GameBackend.total_credits_at("Excellence") >= GameBackend.CERTIFICATE_ENDORSEMENT_CREDITS else COL_WARN)

	var endorsed: Dictionary = GameBackend.endorsed_courses()
	if endorsed.is_empty():
		_para(tr("NZQA_NO_COURSE_ENDORSE") % [
			GameBackend.COURSE_ENDORSEMENT_CREDITS,
			GameBackend.COURSE_ENDORSEMENT_MIN_PER_SOURCE,
			GameBackend.COURSE_ENDORSEMENT_MIN_PER_SOURCE], COL_MUTED, 13)
	else:
		for subj in endorsed:
			_bullet(tr("NZQA_COURSE_ENDORSED") % [
				GameBackend.subject_name(str(subj)), GameBackend.band_name(str(endorsed[subj]))], COL_GOOD)

	_h2(tr("NZQA_REQUIREMENTS"))
	_bullet(tr("NZQA_SUBJECTS_AT") % [
		GameBackend.subjects_meeting_credit_threshold(), GameBackend.UE_SUBJECTS_REQUIRED,
		GameBackend.UE_CREDITS_PER_SUBJECT],
		COL_GOOD if GameBackend.subjects_meeting_credit_threshold() >= GameBackend.UE_SUBJECTS_REQUIRED else COL_WARN)
	_bullet(tr("NCEA_LITERACY") + tr("NZQA_CARRIED") % [
		GameBackend.literacy_credits, GameBackend.UE_LITERACY_REQUIRED], COL_GOOD)
	_bullet(tr("NCEA_NUMERACY") + tr("NZQA_CARRIED") % [
		GameBackend.numeracy_credits, GameBackend.UE_NUMERACY_REQUIRED], COL_GOOD)
	_bullet(tr("NZQA_TOTAL_L3") % GameBackend.total_credits())
	_para(tr("NZQA_BANKED") % [
		GameBackend.UE_CREDITS_PER_SUBJECT, GameBackend.UE_SUBJECTS_REQUIRED], COL_MUTED, 13)

	var shortfalls: Array = GameBackend.ue_shortfall_reasons()
	if not shortfalls.is_empty():
		_h2(tr("NZQA_WHATS_MISSING"))
		for r in shortfalls:
			_para(str(r), Color(0.90, 0.66, 0.45), 14)

	# --- per subject
	_h2(tr("NZQA_BY_SUBJECT"))
	for subject in GameBackend.active_subjects:
		_subject_card(subject)


func _subject_card(subject: String) -> void:
	var d: Dictionary = GameBackend.subject_result_detail(subject)

	var card: PanelContainer = _make_card()
	var col: VBoxContainer = card.get_node("Column")
	var endorsement: String = GameBackend.course_endorsement(subject)
	_card_heading(col, tr("NZQA_CARD_HEADING") % [
		GameBackend.subject_name(str(subject)), d.credits, d.grade,
		GameBackend.get_prep(subject),
		"   ★ %s" % GameBackend.band_name(endorsement).to_upper() if endorsement != "" else ""],
		COL_GOOD if d.credits >= GameBackend.UE_CREDITS_PER_SUBJECT else COL_WARN)

	# Internals
	if not d.internals.is_empty():
		var itext: Array = []
		for r in d.internals:
			if r.taken:
				itext.append((tr("COMMON_DAY") + ": %s (%.0f%%)") % [r.day, GameBackend.band_name(str(r.band)), r.accuracy * 100.0])
			else:
				itext.append((tr("COMMON_DAY") + ": %s") % [r.day, tr("NCEA_ABSENT")])
		_card_line(col, tr("NCEA_INTERNAL") + " — " + "  ·  ".join(itext))

	# Externals
	if not d.externals.is_empty():
		var etext: Array = []
		for r in d.externals:
			if GameBackend.results_phase < 1:
				etext.append((tr("COMMON_DAY") + ": %s") % [r.day, tr("NCEA_SEALED")])
			elif r.taken:
				etext.append((tr("COMMON_DAY") + ": %s (%.0f%%)%s") % [r.day, GameBackend.band_name(str(r.band)), r.accuracy * 100.0,
					tr("NZQA_DERIVED_TAG") if r.derived else ""])
			else:
				etext.append((tr("COMMON_DAY") + ": %s") % [r.day, tr("NCEA_ABSENT")])
		_card_line(col, tr("NCEA_EXTERNAL") + " — " + "  ·  ".join(etext))

	for w in d.why:
		_card_line(col, "· " + str(w), Color(0.72, 0.76, 0.84))
	_card_line(col, tr("NZQA_IF_TODAY") % GameBackend.predicted_band(subject),
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
	_para(tr("APP_PORTAL_LINE") % GameBackend.player_name, COL_MUTED, 13)
	_rule()

	var degree: String = GameBackend.selected_conjoint if GameBackend.selected_conjoint != "" else GameBackend.selected_major
	_h2(tr("SL_YOUR_APPLICATION"))
	_bullet(tr("APP_PROGRAMME") % (GameBackend.major_name(degree) if degree != "" else tr("APP_NOT_SELECTED")))
	_bullet(tr("APP_ENTRY_STANDARD") % [
		GameBackend.required_grade(),
		tr("APP_CONJOINT_INCL") if GameBackend.selected_conjoint != "" else ""])
	_bullet(tr("APP_CURRENT_AVG") % GameBackend.get_overall_grade())
	_bullet(tr("APP_TUITION_Y1") % GameBackend.universities.get(GameBackend.selected_university, {}).get("money_needed", 0))

	var missing: Array = GameBackend.missing_required_subjects()
	if not missing.is_empty():
		_callout(tr("APP_EXPECTS") % [
			_pretty_subjects(GameBackend.programme_required_subjects()),
			_pretty_subjects(missing),
			float(missing.size()) * GameBackend.MISSING_SUBJECT_PENALTY], COL_WARN)

	if GameBackend.can_change_preference():
		_page_change_preference()

	if GameBackend.results_phase < 2:
		_h2(tr("APP_STATUS"))
		if GameBackend.results_phase == 1:
			_callout(tr("APP_RESULTS_RECEIVED"), COL_ACCENT)
		else:
			_callout(tr("APP_UNDER_CONSIDERATION"), COL_MUTED)
		_para(tr("APP_NOTHING_TO_DO"), COL_MUTED, 13)
		return

	# --- the decision
	var result: String = GameBackend.pending_ending_result()
	var good: bool = result in ["scholarship", "good", "student_loan", "deferred"]
	var partial: bool = result in ["second_choice", "foundation_year"]
	_h2(tr("APP_DECISION"))
	_callout(GameBackend.offer_message(), COL_GOOD if good else (COL_WARN if partial else COL_BAD))

	_h2(tr("APP_HOW_DECIDED"))
	for r in GameBackend.offer_reasons():
		_para("· " + str(r), Color(0.78, 0.82, 0.88), 14)

	_h2(tr("APP_WHAT_NOW"))
	match result:
		"scholarship", "good", "student_loan":
			_para(tr("APP_NOW_ACCEPT"))
		"deferred":
			_para(tr("APP_NOW_DEFERRED"))
		"unfunded":
			_para(tr("APP_NOW_UNFUNDED"))
		"second_choice":
			_para(tr("APP_NOW_SECOND"))
		"foundation_year":
			_para(tr("APP_NOW_FOUNDATION"))
		"no_ue":
			_para(tr("APP_NOW_NO_UE"))
		_:
			_para(tr("APP_NOW_REAPPLY"))


# FEES & BUDGET

func _page_fees() -> void:
	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var fees: float = uni.get("money_needed", 0)
	var have: float = GameBackend.money + GameBackend.savings_balance + GameBackend.term_deposit_amount
	var gap: float = fees - have

	_h1(tr("LAPTOP_FEES"))
	_rule()

	_h2(tr("FEES_YEAR_ONE") % GameBackend.university_full_name())
	_bullet(tr("FEES_TUITION") % fees)
	_bullet(tr("FEES_ACCOM_NOTE"))
	_bullet(tr("FEES_TUITION_ONLY"))

	_h2(tr("FEES_WHAT_YOU_HAVE"))
	_bullet(tr("FEES_WALLET") % GameBackend.money)
	_bullet(tr("FEES_SAVINGS") % GameBackend.savings_balance)
	if GameBackend.term_deposit_amount > 0.0:
		_bullet(tr("FEES_TERM_DEPOSIT") % [
			GameBackend.term_deposit_amount, GameBackend.term_deposit_days_left])
	_bullet(tr("FEES_TOTAL") % have, COL_ACCENT)

	_h2(tr("FEES_THE_GAP"))
	if gap <= 0.0:
		_callout(tr("FEES_COVERED") % [fees, have], COL_GOOD)
	elif GameBackend.loan_covers_fees():
		_callout(tr("FEES_SHORT_LOAN") % gap, COL_GOOD)
	else:
		_callout(tr("FEES_SHORT") % [
			gap, _shifts_needed(gap)], COL_BAD)

	_h2(tr("FEES_EARNING_RATE"))
	if GameBackend.stat_shifts > 0:
		var per_shift: float = GameBackend.stat_earned / float(GameBackend.stat_shifts)
		_bullet(tr("FEES_PER_SHIFT") % [
			GameBackend.stat_shifts, GameBackend.stat_earned, per_shift])
		_bullet(tr("FEES_DAYS_LEFT") % GameBackend.days_remaining)
	else:
		_bullet(tr("FEES_NO_SHIFTS"))

	_h2(tr("FEES_HONEST"))
	if gap <= 0.0:
		_para(tr("FEES_DONE"))
	elif GameBackend.loan_status == "approved":
		_para(tr("FEES_LOAN_COVERS"))
	elif GameBackend.loan_status == "submitted":
		_para(tr("FEES_WAIT_LOAN") % GameBackend.loan_days_left)
	elif GameBackend.loan_applications_open():
		_para(tr("FEES_APPLY_NOW") % gap)
	else:
		_para(tr("FEES_TOO_LATE") % gap)


func _shifts_needed(gap: float) -> int:
	var per_shift: float = 100.0
	if GameBackend.stat_shifts > 0:
		per_shift = max(20.0, GameBackend.stat_earned / float(GameBackend.stat_shifts))
	return int(ceil(gap / per_shift))


func _pretty_subjects(items: Array) -> String:
	var out: Array = []
	for i in items:
		out.append(GameBackend.subject_name(str(i)))
	return tr("LIST_SEPARATOR").join(out)


# --- Changing your mind --------------------------------------------------------
# A preference is a preference. You can move it right up until results are
# released, which is how it works in real life and how it should work here.

func _page_change_preference() -> void:
	_h2(tr("PREF_CHANGE_HEAD"))
	_para(tr("PREF_CHANGE_INFO"), COL_MUTED, 13)

	if _pref_message != "":
		_callout(_pref_message, COL_ACCENT)

	# --- university
	var uni_label := Label.new()
	uni_label.text = tr("PREF_FIRST_UNI")
	uni_label.add_theme_font_size_override("font_size", 14)
	_content.add_child(uni_label)

	var uni_row := HBoxContainer.new()
	uni_row.add_theme_constant_override("separation", 8)
	_content.add_child(uni_row)
	for key in GameBackend.universities:
		var data: Dictionary = GameBackend.universities[key]
		var b: Button = _action(uni_row, "%s\n%.0f%% · $%.0f" % [GameBackend.university_name(key), data.get("grades_needed", 0), data.get("money_needed", 0)], 180, 52)
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
	var toggle: Button = _action(_content, tr("PREF_HIDE_PROGRAMMES") if _show_programmes else tr("PREF_CHANGE_PROGRAMME"), 240, 34)
	toggle.pressed.connect(func():
		_show_programmes = not _show_programmes
		_rebuild())

	if not _show_programmes:
		return

	_para(tr("PREF_SINGLE"), COL_MUTED, 13)
	for major in GameBackend.MAJORS:
		_programme_button(major, GameBackend.MAJORS[major], 0.0)

	_para(tr("PREF_CONJOINT"), COL_MUTED, 13)
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
		suffix += tr("PREF_COVERED")
	else:
		suffix += tr("PREF_MISSING") % [
			_pretty_subjects(missing), float(missing.size()) * GameBackend.MISSING_SUBJECT_PENALTY]

	var b: Button = _action(_content, "%s%s" % [GameBackend.major_name(programme), suffix], 640, 36)
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
	_h1(tr("LAPTOP_ACCOMMODATION"))
	_para(tr("ACC_PAGE_SUB"), COL_MUTED, 13)
	_rule()

	if GameBackend.accommodation_deposit_paid:
		_callout("%s — %s" % [tr("ACC_CONFIRMED"), tr(str(GameBackend.ACCOMMODATION[GameBackend.accommodation_choice].label))], COL_GOOD)
	elif GameBackend.accommodation_choice != "":
		_callout(tr("ACC_PAGE_PENDING"), COL_WARN)
	elif GameBackend.accommodation_applications_open():
		_callout(tr("ACC_PAGE_NONE") % GameBackend.ACCOM_APPLY_CLOSES_DAY, COL_WARN)
	else:
		_callout(tr("ACC_PAGE_CLOSED"), COL_BAD)

	if _accom_message != "":
		_callout(_accom_message, COL_ACCENT)

	_h2(tr("ACC_OPTIONS"))
	for key in GameBackend.ACCOMMODATION:
		_accommodation_card(key)

	# --- confirm
	if GameBackend.accommodation_choice != "" and not GameBackend.accommodation_deposit_paid and GameBackend.accommodation_applications_open():
		_h2(tr("ACC_CONFIRM_PLACE"))
		var dep: float = GameBackend.ACCOMMODATION[GameBackend.accommodation_choice].get("deposit", 0.0)
		_para(tr("ACC_DEPOSIT_INFO") % [dep, GameBackend.money])
		var confirm: Button = _action(_content, "%s ($%.0f)" % [tr("ACC_PAY_DEPOSIT"), dep], 240, 38)
		confirm.pressed.connect(func():
			var r: Array = GameBackend.confirm_accommodation()
			_accom_message = str(r[1])
			if bool(r[0]):
				Audio.play("cash")
				Notifier.notify(tr("LAPTOP_ACCOMMODATION"), tr("NOTIF_DEPOSIT_PAID"), COL_GOOD)
			else:
				Audio.play("error")
			_rebuild())

	_h2(tr("ACC_HONEST_NOTE"))
	_para(tr("ACC_HONEST_TEXT"))


func _accommodation_card(key: String) -> void:
	var data: Dictionary = GameBackend.ACCOMMODATION[key]
	var chosen: bool = GameBackend.accommodation_choice == key

	var card: PanelContainer = _make_card(COL_ACCENT if chosen else Color(0, 0, 0, 0))
	var col: VBoxContainer = card.get_node("Column")
	_card_heading(col, tr("ACC_CARD_HEADING") % [
		tr(str(data.label)), data.get("deposit", 0.0), data.get("year_cost", 0.0)],
		COL_ACCENT if chosen else Color(0.88, 0.90, 0.94))

	_card_line(col, tr(str(data.blurb)))

	if not chosen and GameBackend.accommodation_applications_open():
		var pick: Button = _action(col, tr("ACC_PREFERENCE"), 220, 32)
		pick.pressed.connect(func():
			var r: Array = GameBackend.choose_accommodation(key)
			_accom_message = str(r[1])
			Audio.play("click" if bool(r[0]) else "error")
			_rebuild())

	_content.add_child(card)
