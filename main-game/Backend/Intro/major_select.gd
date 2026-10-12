## major_select.gd
## Shown after picking a university. Choose a single-degree major or a
## conjoint (two degrees at once — more doors open, but a higher grade
## requirement at the end of the year).
##
## Buttons are built from GameBackend.MAJORS / CONJOINTS at runtime, so adding
## a new option there makes it appear here automatically.
extends Control

@onready var list: VBoxContainer = $Layout/Scroll/List


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_options()


func _pretty(subjects: Array) -> String:
	var parts: Array = []
	for s in subjects:
		parts.append(str(s).capitalize().replace("_", " "))
	return ", ".join(parts)


func _build_options() -> void:
	# Keep the title/subtitle, clear everything we generated last time.
	for child in list.get_children():
		if child is Button or child is HSeparator or child.name.begins_with("@"):
			child.queue_free()

	for major in GameBackend.MAJORS:
		var btn := Button.new()
		btn.text = "%s\n%s" % [major, _pretty(GameBackend.MAJORS[major])]
		btn.custom_minimum_size = Vector2(520, 58)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_choose_major.bind(major))
		list.add_child(btn)

	# Clear visual break so the conjoints don't run straight on from the
	# single degrees.
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 14)
	list.add_child(spacer_top)

	var rule_a := HSeparator.new()
	rule_a.custom_minimum_size = Vector2(520, 0)
	list.add_child(rule_a)

	var sep := Label.new()
	sep.text = "CONJOINT DEGREES  —  two degrees at once, higher grade required"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.add_theme_font_size_override("font_size", 15)
	sep.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	list.add_child(sep)

	var rule_b := HSeparator.new()
	rule_b.custom_minimum_size = Vector2(520, 0)
	list.add_child(rule_b)

	var spacer_bottom := Control.new()
	spacer_bottom.custom_minimum_size = Vector2(0, 8)
	list.add_child(spacer_bottom)

	for conj in GameBackend.CONJOINTS:
		var data: Dictionary = GameBackend.CONJOINTS[conj]
		var btn2 := Button.new()
		btn2.text = "%s  (+%.0f%% grade needed)\n%s" % [
			conj, data.get("grade_bonus_required", 0.0), _pretty(data.get("subjects", []))]
		btn2.custom_minimum_size = Vector2(520, 56)
		btn2.add_theme_font_size_override("font_size", 16)
		btn2.pressed.connect(_choose_conjoint.bind(conj))
		list.add_child(btn2)


func _choose_major(major: String) -> void:
	GameBackend.selected_conjoint = ""
	GameBackend.set_major(major)
	_start_game()


func _choose_conjoint(conjoint: String) -> void:
	var data: Dictionary = GameBackend.CONJOINTS[conjoint]
	GameBackend.selected_conjoint = conjoint
	# Reuse set_major's setup, then override the subject list with the
	# conjoint's own combination.
	GameBackend.set_major(GameBackend.MAJORS.keys()[0])
	GameBackend.selected_major = conjoint
	GameBackend.active_subjects = (data.get("subjects", []) as Array).duplicate()
	GameBackend.subject_grades = {}
	GameBackend.subject_credits = {}
	for s in GameBackend.active_subjects:
		GameBackend.subject_grades[s] = 50.0
		GameBackend.subject_credits[s] = 0
	GameBackend.generate_exam_schedule()
	GameBackend.stats_changed.emit()
	_start_game()


func _start_game() -> void:
	MusicManager.pause_music()
	get_tree().change_scene_to_file("res://Main_Game/Scenes/MainMap.tscn")
	Inventory.get_node("UI").show()
