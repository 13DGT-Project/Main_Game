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
	panel.visible = false
	close_button.pressed.connect(_close)
	GameBackend.journal_updated.connect(_refresh_entries)
	GameBackend.stats_changed.connect(_refresh_summary)
	_refresh_entries()
	_refresh_summary()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		panel.visible = not panel.visible
		if panel.visible:
			_refresh_entries()
			_refresh_summary()


func _close() -> void:
	panel.visible = false


func _refresh_summary() -> void:
	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var money_needed: float = uni.get("money_needed", 0)
	var grades_needed: float = uni.get("grades_needed", 0)
	summary_label.text = "Target: %s (%s)\nDays remaining: %d\n\nMoney: $%.2f / $%.0f\nOverall grade: %.0f / %.0f\n\nEnglish: %.0f   Maths: %.0f   Physics: %.0f\n\nEnergy: %.0f   Sanity: %.0f   Thirst: %.0f" % [
		GameBackend.selected_university, uni.get("location", "?"), GameBackend.days_remaining,
		GameBackend.money, money_needed,
		GameBackend.get_overall_grade(), grades_needed,
		GameBackend.subject_grades.english, GameBackend.subject_grades.maths, GameBackend.subject_grades.physics,
		GameBackend.energy, GameBackend.sanity, GameBackend.thirst
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
