## A notice board for the external exam timetable. It shows itself
## automatically the day before your first external, and can be opened any
## time after that with T.
extends CanvasLayer

const PANEL_SIZE := Vector2(520, 460)

var _root: Control
var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _rows: VBoxContainer
var _hint: Label

var _is_open: bool = false
## So the automatic notice only interrupts you once.
var _auto_shown: bool = false


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	GameBackend.game_ended.connect(_on_game_ended)


func _build_ui() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.7)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)

	_panel = PanelContainer.new()
	_panel.size = PANEL_SIZE
	_root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	_title = Label.new()
	_title.text = tr("TT_TITLE").to_upper()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	box.add_child(_title)

	var rule := HSeparator.new()
	box.add_child(rule)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PANEL_SIZE.x - 40, PANEL_SIZE.y - 150)
	box.add_child(scroll)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)

	_hint = Label.new()
	_hint.text = "Press T to close"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 14)
	box.add_child(_hint)

	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_dim.position = Vector2.ZERO
	_dim.size = vp
	_panel.position = (vp - PANEL_SIZE) * 0.5


func _process(_delta: float) -> void:
	# Post the notice once, automatically, as the exams come into view.
	if not _auto_shown and not _is_open and GameBackend.should_show_timetable():
		if not GameBackend.get_timetable().is_empty():
			_auto_shown = true
			open()


func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if InputMap.has_action("timetable") and event.is_action_pressed("timetable"):
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_T:
		pressed = true
	if pressed:
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func open() -> void:
	_refresh()
	_is_open = true
	_root.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_is_open = false
	_root.visible = false


func _refresh() -> void:
	# Set here rather than in _build_ui(): this autoload builds at startup,
	# before the player has picked a language in Settings.
	_title.text = tr("TT_TITLE").to_upper()
	_hint.text = tr("TT_CLOSE_HINT")
	for child in _rows.get_children():
		child.queue_free()

	# Show BOTH kinds, clearly separated. This used to list externals only,
	# so an internal reminder sent you to a timetable the internal wasn't on.
	var rows: Array = GameBackend.get_timetable()
	if rows.is_empty():
		var none := Label.new()
		none.text = tr("TT_NOTHING")
		_rows.add_child(none)
		return

	_add_key()

	# Group by day so doubles read as a single sitting day.
	var by_day: Dictionary = {}
	for r in rows:
		if not by_day.has(r.day):
			by_day[r.day] = []
		by_day[r.day].append(r)

	var days: Array = by_day.keys()
	days.sort()

	for day in days:
		var entries: Array = by_day[day]
		var away: int = entries[0].days_away

		var when: String
		if away < 0:
			when = tr("TT_FINISHED")
		elif away == 0:
			when = tr("TT_TODAY")
		elif away == 1:
			when = tr("TT_TOMORROW")
		else:
			when = tr("TT_IN_DAYS") % away

		var header := Label.new()
		header.text = (tr("COMMON_DAY") + "  —  %s") % [day, when]
		header.add_theme_font_size_override("font_size", 17)
		var col := Color(0.75, 0.82, 0.95)
		if away == 0:
			col = Color(1.0, 0.5, 0.45)
		elif away == 1:
			col = Color(1.0, 0.82, 0.4)
		header.add_theme_color_override("font_color", col)
		_rows.add_child(header)

		for e in entries:
			var line := Label.new()
			var status: String = "  (%s)" % tr("TT_SAT") if e.taken else ""
			var kind: String = str(e.get("kind", "internal"))
			line.text = tr("TT_ROW") % [
				GameBackend.subject_name(str(e.subject)),
				tr("NCEA_EXTERNAL" if kind == "external" else "NCEA_INTERNAL").to_upper(), GameBackend.place_name(str(e.get("where", "school"))), status]
			line.add_theme_font_size_override("font_size", 15)
			if e.taken:
				line.add_theme_color_override("font_color", Color(0.6, 0.65, 0.6))
			elif kind == "external":
				line.add_theme_color_override("font_color", Color(1.0, 0.72, 0.55))
			else:
				line.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0))
			_rows.add_child(line)

		if entries.size() >= GameBackend.MAX_EXAMS_PER_DAY:
			var note := Label.new()
			note.text = tr("TT_DOUBLE")
			note.add_theme_font_size_override("font_size", 13)
			note.add_theme_color_override("font_color", Color(0.7, 0.7, 0.55))
			_rows.add_child(note)

		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 6)
		_rows.add_child(gap)


## A two-line key at the top, because "internal" and "external" mean nothing
## to someone who hasn't had it explained four times.
func _add_key() -> void:
	var key := Label.new()
	key.text = tr("TT_KEY_INTERNAL") + "\n" + tr("TT_KEY_EXTERNAL")
	key.add_theme_font_size_override("font_size", 13)
	key.add_theme_color_override("font_color", Color(0.70, 0.75, 0.84))
	key.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	key.custom_minimum_size = Vector2(520, 0)
	_rows.add_child(key)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	_rows.add_child(gap)


## Same reason as the map — this survives the scene change.
func _on_game_ended(_result: String) -> void:
	close()
