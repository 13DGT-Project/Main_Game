## Reads GameBackend.ending_result (set by GameBackend._end_game()) to decide which text/music to show.
extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

const COL_GOOD := Color(0.42, 0.82, 0.55)
const COL_WARN := Color(0.95, 0.74, 0.32)
const COL_BAD := Color(0.90, 0.42, 0.42)

var _epilogue_label: RichTextLabel


func _ready() -> void:
	Inventory.get_node("UI").hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_button.pressed.connect(_on_menu_pressed)

	var degree: String = GameBackend.selected_conjoint if GameBackend.selected_conjoint != "" else GameBackend.selected_major

	#Headline -----------------------------------------------------------
	var accent: Color = COL_BAD
	match GameBackend.ending_result:
		"scholarship":
			title_label.text = tr("END_SCHOLARSHIP")
			subtitle_label.text = tr("END_SUB_SCHOLARSHIP") % GameBackend.university_full_name()
			accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"good":
			title_label.text = tr("END_ACCEPTED")
			subtitle_label.text = tr("END_SUB_GOOD") % GameBackend.university_full_name()
			accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"student_loan":
			title_label.text = tr("END_ACCEPTED_LOAN")
			subtitle_label.text = tr("END_SUB_STUDENT_LOAN") % GameBackend.university_full_name()
			accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"unfunded":
			title_label.text = tr("END_UNFUNDED")
			subtitle_label.text = tr("END_SUB_UNFUNDED") % GameBackend.university_full_name()
			accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"deferred":
			title_label.text = tr("END_DEFERRED")
			subtitle_label.text = tr("END_SUB_DEFERRED")
			accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"foundation_year":
			title_label.text = tr("END_FOUNDATION")
			subtitle_label.text = tr("END_SUB_FOUNDATION") % GameBackend.university_full_name()
			accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"second_choice":
			title_label.text = tr("END_SECOND_CHOICE")
			subtitle_label.text = tr("END_SUB_SECOND_CHOICE") % GameBackend.university_full_name()
			accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"no_ue":
			title_label.text = tr("END_NO_UE")
			subtitle_label.text = tr("END_SUB_NO_UE")
			accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"bad_sanity":
			title_label.text = tr("END_BURNOUT")
			subtitle_label.text = tr("END_SUB_BURNOUT")
			accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"bad_deadline":
			title_label.text = tr("END_REJECTION")
			subtitle_label.text = tr("END_SUB_REJECTION") % GameBackend.university_full_name()
			accent = COL_BAD
			MusicManager.play_track("bad_ending")
		_:
			title_label.text = tr("END_YEAR_OVER")
			subtitle_label.text = tr("END_SUB_DEFAULT")
			MusicManager.play_track("bad_ending")

	# Upper-case the first letter: "the University of Auckland offered you..." can open a sentence.
	subtitle_label.text = subtitle_label.text.substr(0, 1).to_upper() + subtitle_label.text.substr(1)
	title_label.add_theme_color_override("font_color", accent)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.custom_minimum_size = Vector2(700, 0)

	_build_epilogue_panel(degree, accent)


## Everything below the headline: the epilogue/recap,
## and the handful of moments from the journal that actually mattered.
func _build_epilogue_panel(degree: String, accent: Color) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(760, 0)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 330)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_epilogue_label = RichTextLabel.new()
	_epilogue_label.bbcode_enabled = true
	_epilogue_label.fit_content = true
	_epilogue_label.scroll_active = false
	_epilogue_label.custom_minimum_size = Vector2(740, 0)
	_epilogue_label.add_theme_font_size_override("normal_font_size", 15)
	_epilogue_label.text = _compose_text(degree, accent)
	scroll.add_child(_epilogue_label)
	box.add_child(scroll)

	# Insert above the menu button so the button stays on the bottom.
	var parent := menu_button.get_parent()
	parent.add_child(box)
	parent.move_child(box, menu_button.get_index())


func _compose_text(degree: String, accent: Color) -> String:
	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var money_needed: float = uni.get("money_needed", 0)
	var hex: String = "#" + accent.to_html(false)
	var out: Array = []

	#THe epilogue
	out.append("[color=%s][b]%s[/b][/color]" % [hex, tr("END_YOUR_YEAR")])
	out.append(GameBackend.build_epilogue())
	out.append("")

	#Why it went this way
	out.append("[color=%s][b]%s[/b][/color]" % [hex, tr("END_WHY")])
	for reason in GameBackend.offer_reasons():
		out.append("  •  " + str(reason))
	out.append("")

	#Info
	out.append("[color=%s][b]%s[/b][/color]" % [hex, tr("END_NUMBERS")])
	out.append("%s  —  %s" % [GameBackend.university_full_name(), GameBackend.major_name(degree) if degree != "" else tr("END_NO_PROGRAMME")])
	out.append(tr("END_OVERALL") % [GameBackend.get_overall_grade(), GameBackend.required_grade()])
	out.append(tr("END_MONEY") % [GameBackend.money, money_needed])
	if GameBackend.loan_debt > 0.0:
		out.append(tr("END_BORROWED") % GameBackend.loan_debt)
	out.append(tr("END_WELLBEING") % [GameBackend.sanity, GameBackend.stat_lowest_sanity])
	out.append("")
	out.append(GameBackend.ue_status_text())
	var cert_e: String = GameBackend.certificate_endorsement()
	if cert_e != "":
		out.append(tr("END_CERT_ENDORSED") % GameBackend.band_name(cert_e).to_upper())
	var courses: Dictionary = GameBackend.endorsed_courses()
	if not courses.is_empty():
		var bits: Array = []
		for subj in courses:
			bits.append("%s (%s)" % [GameBackend.subject_name(str(subj)), GameBackend.band_name(str(courses[subj]))])
		out.append(tr("END_COURSE_ENDORSEMENTS") % ", ".join(bits))
	out.append("")

	out.append("[color=%s][b]%s[/b][/color]" % [hex, tr("END_HOW_SPENT")])
	out.append((tr("END_STUDY_SESSIONS") + ": %d   ·   " + tr("END_HOURS_STUDYING") + ": %.0f") % [
		GameBackend.stat_study_sessions, GameBackend.stat_study_hours])
	out.append((tr("END_SHIFTS_WORKED") + ": %d   ·   " + tr("END_EARNED") + ": $%.0f") % [
		GameBackend.stat_shifts, GameBackend.stat_earned])
	out.append((tr("END_ASSESSMENTS_SAT") + ": %d   ·   " + tr("END_MISSED") + ": %d") % [
		GameBackend.stat_exams_sat, GameBackend.stat_exams_missed])
	out.append((tr("END_NIGHTS_SLEPT") + ": %d   ·   " + tr("END_MEALS_COOKED") + ": %d") % [
		GameBackend.stat_nights_slept, GameBackend.stat_meals_cooked])
	out.append((tr("END_CONVERSATIONS") + ": %d   ·   " + tr("END_TEXTS_REPLIED") + ": %d") % [
		GameBackend.stat_conversations, GameBackend.stat_messages_replied])
	out.append("")

	#Key moments
	var notable: Array = GameBackend.notable_events(10)
	if not notable.is_empty():
		out.append("[color=%s][b]%s[/b][/color]" % [hex, tr("END_MOMENTS")])
		for entry in notable:
			out.append(("  " + tr("COMMON_DAY") + " — %s") % [entry.day, entry.text])

	return "\n".join(out)


func _on_menu_pressed() -> void:
	GameBackend.reset_run()
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")
