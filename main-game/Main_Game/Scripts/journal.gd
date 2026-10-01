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
	var major_text: String = GameBackend.selected_major if GameBackend.selected_major != "" else "not chosen yet"
	summary_label.text = "Target: %s (%s)\nMajor: %s\nDays remaining: %d\n\nMoney: $%.2f / $%.0f\nOverall grade: %.0f / %.0f\n\n%s\n\nEnergy: %.0f   Sanity: %.0f   Thirst: %.0f\nTemptation: %.0f" % [
		GameBackend.selected_university, uni.get("location", "?"), major_text, GameBackend.days_remaining,
		GameBackend.money, money_needed,
		GameBackend.get_overall_grade(), grades_needed,
		GameBackend.get_subject_grades_text(),
		GameBackend.energy, GameBackend.sanity, GameBackend.thirst, GameBackend.temptation
	]
	summary_label.text += "\n\n--- University Entrance ---\n" + GameBackend.ue_status_text()
	summary_label.text += "\nUE achieved: %s" % ("YES" if GameBackend.has_university_entrance() else "not yet")
	# The loan is as much a gate on the ending as the credits are, so it
	# belongs on the same summary rather than only on the laptop.
	summary_label.text += "\n\n--- Student loan (StudyLink) ---\n" + GameBackend.loan_status_text()

	# What you've agreed to and where to go. Commitments are worthless as a
	# mechanic if the game never tells you how to honour one.
	var briefing: Array = GameBackend.commitment_briefing()
	if not briefing.is_empty():
		summary_label.text += "\n\n--- TODAY YOU SAID YOU'D ---"
		for line in briefing:
			summary_label.text += "\n" + str(line)
	var upcoming: Array = []
	for c in GameBackend.commitments:
		if int(c.day) > GameBackend.get_elapsed_days():
			upcoming.append("Day %d: %s (%s)" % [
				int(c.day), str(c.label), GameBackend.commitment_place(str(c.kind))])
	if not upcoming.is_empty():
		summary_label.text += "\n\n--- COMING UP ---"
		for line in upcoming:
			summary_label.text += "\n" + str(line)


func _refresh_entries() -> void:
	for child in entries_container.get_children():
		child.queue_free()
	var entries: Array = GameBackend.journal.duplicate()
	entries.reverse()  # newest first
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Nothing logged yet — go study or find a shift."
		entries_container.add_child(empty_label)
		return
	for entry in entries:
		var lbl := Label.new()
		lbl.text = "Day %d — %s" % [entry.day, entry.text]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entries_container.add_child(lbl)
