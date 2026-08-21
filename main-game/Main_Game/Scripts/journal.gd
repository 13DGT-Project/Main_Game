## journal.gd
## Root script for Journal.tscn. A toggleable (press J) progress log + stats
## summary. Instanced at runtime by game_manager.gd / school_scene.gd /
## work_scene.gd — not placed by hand in any scene file, so it works
## everywhere without editing your hand-built scenes.
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
	# Fallback: check the raw key directly too, in case the "journal" action
	# in Input Map hasn't been picked up yet (Godot needs a project reload
	# after project.godot's [input] section is edited outside the editor).
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
