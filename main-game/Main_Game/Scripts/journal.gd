extends CanvasLayer

@onready var panel: Control = $Panel
@onready var summary_label: Label = $Panel/CenterContainer/Box/VBoxContainer/SummaryLabel
@onready var entries_container: VBoxContainer = $Panel/CenterContainer/Box/VBoxContainer/ScrollContainer/EntriesContainer
@onready var close_button: Button = $Panel/CenterContainer/Box/VBoxContainer/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	close_button.pressed.connect(_close)
	GameBackend.journal_updated.connect(_refresh_entries)
	GameBackend.stats_changed.connect(_refresh_summary)
	_refresh_entries()
	_refresh_summary()


func _input(event: InputEvent) -> void:
	var pressed_j: bool = event.is_action_pressed("journal")
	if not pressed_j and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_J:
			pressed_j = true
	if pressed_j:
		panel.visible = not panel.visible
		if panel.visible:
			_refresh_entries()
			_refresh_summary()
		get_viewport().set_input_as_handled()


func _close() -> void:
	panel.visible = false


func _refresh_summary() -> void:
	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var money_needed: float = uni.get("money_needed", 0)
	var grades_needed: float = uni.get("grades_needed", 0)
	var major_text: String = GameBackend.major_name(GameBackend.selected_major) if GameBackend.selected_major != "" else tr("JOURNAL_NOT_CHOSEN")
	summary_label.text = (tr("JOURNAL_SUMMARY_HEAD") + "\n\n" + tr("COMMON_MONEY") + ": $%.2f / $%.0f\n" + tr("JOURNAL_OVERALL_GRADE") + "\n\n%s\n\n" + tr("HUD_ENERGY") + ": %.0f   " + tr("HUD_SANITY") + ": %.0f   " + tr("HUD_THIRST") + ": %.0f\n" + tr("HUD_TEMPTATION") + ": %.0f") % [
		GameBackend.university_name(GameBackend.selected_university), GameBackend.city_name(str(uni.get("location", "?"))), major_text, GameBackend.days_remaining,
		GameBackend.money, money_needed,
		GameBackend.get_overall_grade(), grades_needed,
		GameBackend.get_subject_grades_text(),
		GameBackend.energy, GameBackend.sanity, GameBackend.thirst, GameBackend.temptation
	]
	summary_label.text += "\n\n--- %s ---\n" % tr("NCEA_UE") + GameBackend.ue_status_text()
	summary_label.text += "\n" + tr("NCEA_UE_ACHIEVED" if GameBackend.has_university_entrance() else "NCEA_UE_NOT_ACHIEVED")
	# The loan is as much a gate on the ending as the credits are, so it
	# belongs on the same summary rather than only on the laptop.
	summary_label.text += "\n\n--- %s ---\n" % tr("JOURNAL_LOAN") + GameBackend.loan_status_text()

	# What you've agreed to and where to go. Commitments are worthless as a
	# mechanic if the game never tells you how to honour one.
	var briefing: Array = GameBackend.commitment_briefing()
	if not briefing.is_empty():
		summary_label.text += "\n\n--- %s ---" % tr("JOURNAL_TODAY_PROMISED")
		for line in briefing:
			summary_label.text += "\n" + str(line)
	var upcoming: Array = []
	for c in GameBackend.commitments:
		if int(c.day) > GameBackend.get_elapsed_days():
			upcoming.append((tr("COMMON_DAY") + ": %s (%s)") % [
				int(c.day), str(c.label), GameBackend.commitment_place(str(c.kind))])
	if not upcoming.is_empty():
		summary_label.text += "\n\n--- %s ---" % tr("JOURNAL_COMING_UP")
		for line in upcoming:
			summary_label.text += "\n" + str(line)


func _refresh_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()
	var entries: Array = GameBackend.journal.duplicate()
	entries.reverse()  # newest first
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = tr("JOURNAL_NOTHING_YET")
		entries_container.add_child(empty_label)
		return
	for entry in entries:
		var lbl := Label.new()
		lbl.text = (tr("COMMON_DAY") + " — %s") % [entry.day, entry.text]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entries_container.add_child(lbl)
