## ending_scene.gd
## Root script for EndingScene.tscn. Reads GameBackend.ending_result (set by
## GameBackend._end_game()) to decide which text/music to show. Doesn't need
## anything passed to it directly since GameBackend is an autoload.
##
## The thing you were trying to name is the EPILOGUE — the closing passage
## after the result that describes what your year actually looked like. It's
## built in GameBackend.build_epilogue() from the run statistics, so it's
## different every playthrough rather than one fixed paragraph per ending.
extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

const COL_GOOD := Color(0.42, 0.82, 0.55)
const COL_WARN := Color(0.95, 0.74, 0.32)
const COL_BAD := Color(0.90, 0.42, 0.42)

## Extra panel built in code and inserted above the button, so EndingScene.tscn
## doesn't have to change.
var _epilogue_label: RichTextLabel


func _ready() -> void:
	Inventory.get_node("UI").hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_button.pressed.connect(_on_menu_pressed)

	var degree: String = GameBackend.selected_conjoint if GameBackend.selected_conjoint != "" else GameBackend.selected_major

	# --- headline -----------------------------------------------------------
	var accent: Color = COL_BAD
	match GameBackend.ending_result:
		"scholarship":
			title_label.text = "Scholarship"
			subtitle_label.text = "Top of the year. %s covered your fees outright — the money you saved is yours to keep." % GameBackend.university_full_name()
			accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"good":
			title_label.text = "Accepted"
			subtitle_label.text = "You got into %s, fees paid out of your own savings, no debt hanging over you." % GameBackend.university_full_name()
			accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"student_loan":
			title_label.text = "Accepted — On a Loan"
			subtitle_label.text = "You got in. Your savings didn't cover it, so you're going to %s on a StudyLink loan with a long repayment ahead — but you're going." % GameBackend.university_full_name()
			accent = COL_GOOD
			MusicManager.play_track("good_ending")
		"unfunded":
			title_label.text = "An Offer You Can't Take"
			subtitle_label.text = "%s offered you a place. You earned it. There was no approved loan and not enough saved, so the offer sits there unaccepted." % GameBackend.university_full_name()
			accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"deferred":
			title_label.text = "Taking a Year Out"
			subtitle_label.text = "You made the grade — and finished the year completely spent. Fees were never really the barrier; you just can't walk into first year like this. You defer, get yourself right, and start next year."
			accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"foundation_year":
			title_label.text = "Foundation Year"
			subtitle_label.text = "Not enough for direct entry, but %s offered you a place on a foundation programme. Pass it and you transfer into the degree proper next year." % GameBackend.university_full_name()
			accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"second_choice":
			title_label.text = "A Different Door"
			subtitle_label.text = "%s said no — but you came close enough that another university offered you a place. Not the plan, but it's a start." % GameBackend.university_full_name()
			accent = COL_WARN
			MusicManager.play_track("bad_ending")
		"no_ue":
			title_label.text = "No University Entrance"
			subtitle_label.text = "You didn't meet the NCEA requirements for University Entrance, so no university can take you this year — whatever your grades or savings say."
			accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"bad_sanity":
			title_label.text = "Burnout"
			subtitle_label.text = "The pressure got to you before the year was even over."
			accent = COL_BAD
			MusicManager.play_track("bad_ending")
		"bad_deadline":
			title_label.text = "Rejection Letter"
			subtitle_label.text = "It wasn't enough to get into %s this time." % GameBackend.university_full_name()
			accent = COL_BAD
			MusicManager.play_track("bad_ending")
		_:
			title_label.text = "The Year Is Over"
			subtitle_label.text = "However it went, it went."
			MusicManager.play_track("bad_ending")

	title_label.add_theme_color_override("font_color", accent)
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.custom_minimum_size = Vector2(700, 0)

	_build_epilogue_panel(degree, accent)


## Everything below the headline: the epilogue prose, a hard-numbers recap,
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

	# --- the epilogue proper
	out.append("[color=%s][b]YOUR YEAR[/b][/color]" % hex)
	out.append(GameBackend.build_epilogue())
	out.append("")

	# --- why the result was what it was
	out.append("[color=%s][b]WHY IT ENDED THIS WAY[/b][/color]" % hex)
	for reason in GameBackend.offer_reasons():
		out.append("  •  " + str(reason))
	out.append("")

	# --- the numbers
	out.append("[color=%s][b]THE NUMBERS[/b][/color]" % hex)
	out.append("%s  —  %s" % [GameBackend.university_full_name(), degree if degree != "" else "no programme chosen"])
	out.append("Overall grade: %.0f  (needed %.0f)" % [GameBackend.get_overall_grade(), GameBackend.required_grade()])
	out.append("Money: $%.2f  (fees $%.0f)" % [GameBackend.money, money_needed])
	if GameBackend.loan_debt > 0.0:
		out.append("Borrowed from StudyLink: $%.2f" % GameBackend.loan_debt)
	out.append("Wellbeing at the end: %.0f  (lowest point: %.0f)" % [GameBackend.sanity, GameBackend.stat_lowest_sanity])
	out.append("")
	out.append(GameBackend.ue_status_text())
	out.append("")

	out.append("[color=%s][b]HOW YOU SPENT IT[/b][/color]" % hex)
	out.append("Study sessions: %d   ·   Hours studying: %.0f" % [
		GameBackend.stat_study_sessions, GameBackend.stat_study_hours])
	out.append("Shifts worked: %d   ·   Earned: $%.0f" % [
		GameBackend.stat_shifts, GameBackend.stat_earned])
	out.append("Assessments sat: %d   ·   Missed: %d" % [
		GameBackend.stat_exams_sat, GameBackend.stat_exams_missed])
	out.append("Nights slept: %d   ·   Meals cooked: %d" % [
		GameBackend.stat_nights_slept, GameBackend.stat_meals_cooked])
	out.append("Conversations: %d   ·   Texts replied to: %d" % [
		GameBackend.stat_conversations, GameBackend.stat_messages_replied])
	out.append("")

	# --- moments
	var notable: Array = GameBackend.notable_events(10)
	if not notable.is_empty():
		out.append("[color=%s][b]MOMENTS[/b][/color]" % hex)
		for entry in notable:
			out.append("  Day %d — %s" % [entry.day, entry.text])

	return "\n".join(out)


func _on_menu_pressed() -> void:
	GameBackend.reset_run()
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")
