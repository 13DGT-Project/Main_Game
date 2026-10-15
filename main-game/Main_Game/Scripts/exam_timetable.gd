## A notice board for the external exam timetable. It shows itself
## automatically the day before your first external, and can be opened any
## time after that with T.
extends CanvasLayer

const MAX_SIZE := Vector2(760, 820)

# A printed school notice: white sheet, navy header, coloured exam cards.
const SHEET := Color("fbfaf6")
const NAVY := Color("1f3a68")
const INK := Color("26303f")
const INK_SOFT := Color("6b7586")
const INTERNAL_COL := Color("3a7bd5")
const EXTERNAL_COL := Color("e07a2e")
const TODAY_COL := Color("d2453a")
const TOMORROW_COL := Color("d9962a")
const DONE_COL := Color("9aa2ae")

var _root: Control
var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _rows: VBoxContainer
var _hint: Label
var _close_btn: Button
var _scroll: ScrollContainer
## The first day that hasn't happened yet, so opening the notice jumps
## past the papers you've already sat.
var _next_row: Control

var _is_open: bool = false
## The mouse mode from before opening, restored on close (the 3D map
## captures the mouse for the camera).
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
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
	_dim.color = Color(0.03, 0.04, 0.08, 0.66)
	# Swallow mouse movement so the camera behind doesn't turn while you read.
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dim)

	_panel = PanelContainer.new()
	var sheet := _box(SHEET, 16, 0, 0)
	sheet.shadow_color = Color(0, 0, 0, 0.45)
	sheet.shadow_size = 22
	sheet.shadow_offset = Vector2(0, 8)
	_panel.add_theme_stylebox_override("panel", sheet)
	_panel.theme = _make_theme()
	_root.add_child(_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	_panel.add_child(outer)

	# Navy header strip, like the top of a school notice.
	var header := PanelContainer.new()
	var hs := _box(NAVY, 0, 26, 16)
	hs.corner_radius_top_left = 16
	hs.corner_radius_top_right = 16
	header.add_theme_stylebox_override("panel", hs)
	outer.add_child(header)
	var hrow := HBoxContainer.new()
	header.add_child(hrow)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color.WHITE)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(_title)
	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.focus_mode = Control.FOCUS_NONE
	_close_btn.custom_minimum_size = Vector2(40, 40)
	_close_btn.pressed.connect(close)
	hrow.add_child(_close_btn)

	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 8)
	outer.add_child(margin)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(_scroll)

	# Room on the right so the scrollbar doesn't sit on the cards.
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_right", 14)
	_scroll.add_child(pad)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(_rows)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", INK_SOFT)
	var hint_pad := MarginContainer.new()
	hint_pad.add_theme_constant_override("margin_bottom", 14)
	hint_pad.add_child(_hint)
	outer.add_child(hint_pad)

	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_dim.position = Vector2.ZERO
	_dim.size = vp
	var size := Vector2(minf(MAX_SIZE.x, vp.x - 48), minf(MAX_SIZE.y, vp.y - 48))
	_panel.size = size
	_panel.position = ((vp - size) * 0.5).floor()


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
	if _is_open:
		return
	_refresh()
	_is_open = true
	_root.visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_root.visible = false
	Input.mouse_mode = _mouse_before


func _refresh() -> void:
	# Set here rather than in _build_ui(): this autoload builds at startup,
	# before the player has picked a language in Settings.
	_title.text = tr("TT_TITLE")
	_hint.text = tr("TT_CLOSE_HINT")
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	# Show BOTH kinds, clearly separated. This used to list externals only,
	# so an internal reminder sent you to a timetable the internal wasn't on.
	var rows: Array = GameBackend.get_timetable()
	if rows.is_empty():
		_rows.add_child(_text(tr("TT_NOTHING"), INK_SOFT, 16))
		return

	_add_key()
	_next_row = null

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
		var col := INK_SOFT
		if away < 0:
			when = tr("TT_FINISHED")
			col = DONE_COL
		elif away == 0:
			when = tr("TT_TODAY")
			col = TODAY_COL
		elif away == 1:
			when = tr("TT_TOMORROW")
			col = TOMORROW_COL
		else:
			when = tr("TT_IN_DAYS") % away

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		_rows.add_child(row)
		if away >= 0 and _next_row == null:
			_next_row = row

		# Date block on the left.
		var date := PanelContainer.new()
		var ds := _box(Color(col, 0.12), 10, 10, 8)
		ds.border_color = col
		ds.border_width_left = 4
		date.add_theme_stylebox_override("panel", ds)
		date.custom_minimum_size = Vector2(130, 0)
		var dv := VBoxContainer.new()
		dv.add_theme_constant_override("separation", 0)
		dv.alignment = BoxContainer.ALIGNMENT_CENTER
		date.add_child(dv)
		dv.add_child(_text(tr("COMMON_DAY") % day, INK if away >= 0 else DONE_COL, 19))
		dv.add_child(_text(when, col, 14))
		row.add_child(date)

		# The papers sat that day.
		var papers := VBoxContainer.new()
		papers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		papers.add_theme_constant_override("separation", 6)
		row.add_child(papers)
		for e in entries:
			papers.add_child(_paper_card(e))
		if entries.size() >= GameBackend.MAX_EXAMS_PER_DAY:
			papers.add_child(_text(tr("TT_DOUBLE").strip_edges(), INK_SOFT, 13))

	_scroll_to_next.call_deferred()


## Wait for the container to lay out, then put the next exam near the top
## (with the previous day just peeking above it).
func _scroll_to_next() -> void:
	await get_tree().process_frame
	if _next_row == null or not is_instance_valid(_next_row):
		_scroll.scroll_vertical = 0
		return
	_scroll.scroll_vertical = int(maxf(0.0, _next_row.position.y - 90.0))


## One exam: a card with a coloured edge for internal/external.
func _paper_card(e: Dictionary) -> Control:
	var kind: String = str(e.get("kind", "internal"))
	var taken: bool = bool(e.taken)
	var edge: Color = DONE_COL if taken else (EXTERNAL_COL if kind == "external" else INTERNAL_COL)
	var card := PanelContainer.new()
	var cs := _box(Color.WHITE, 10, 14, 9)
	cs.border_color = edge
	cs.border_width_left = 5
	cs.shadow_color = Color(0, 0, 0, 0.08)
	cs.shadow_size = 4
	cs.shadow_offset = Vector2(0, 1)
	card.add_theme_stylebox_override("panel", cs)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	card.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 1)
	h.add_child(v)
	v.add_child(_text(GameBackend.subject_name(str(e.subject)), DONE_COL if taken else INK, 18))
	var place: String = GameBackend.place_name(str(e.get("where", "school")))
	if place != "":
		place = place.substr(0, 1).to_upper() + place.substr(1)
	var kind_text: String = tr("NCEA_EXTERNAL" if kind == "external" else "NCEA_INTERNAL").to_upper()
	v.add_child(_text("%s  ·  %s" % [kind_text, place], DONE_COL if taken else edge, 13))
	if taken:
		h.add_child(_pill("✓ " + tr("TT_SAT"), DONE_COL))
	return card


## The key at the top, because "internal" and "external" mean nothing to
## someone who hasn't had it explained four times.
func _add_key() -> void:
	var key := PanelContainer.new()
	key.add_theme_stylebox_override("panel", _box(Color(NAVY, 0.06), 10, 14, 10))
	var kv := VBoxContainer.new()
	kv.add_theme_constant_override("separation", 6)
	key.add_child(kv)
	for pair in [[INTERNAL_COL, "NCEA_INTERNAL", "TT_KEY_INTERNAL"], [EXTERNAL_COL, "NCEA_EXTERNAL", "TT_KEY_EXTERNAL"]]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		var p := _pill(tr(pair[1]).to_upper(), pair[0])
		p.custom_minimum_size.x = 104
		line.add_child(p)
		var t := _text(_after_dash(tr(pair[2])), INK, 14)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(t)
		kv.add_child(line)
	_rows.add_child(key)


## The key strings read "INTERNAL — sat in class…"; the pill already says
## the first part, so show just the explanation beside it.
func _after_dash(text: String) -> String:
	for dash in [" — ", " —— ", " — "]:
		var i := text.find(dash)
		if i != -1:
			return text.substr(i + dash.length()).strip_edges()
	return text


func _pill(text: String, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_stylebox_override("normal", _box(colour, 9, 9, 2))
	return l


func _text(text: String, colour: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	return l


func _box(colour: Color, radius: int, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = colour
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	var flat := _box(Color(1, 1, 1, 0.12), 20, 0, 0)
	var hover := _box(Color(1, 1, 1, 0.28), 20, 0, 0)
	t.set_stylebox("normal", "Button", flat)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	var track := _box(Color(INK, 0.06), 4, 3, 0)
	var grab := _box(Color(INK, 0.3), 4, 0, 0)
	t.set_stylebox("scroll", "VScrollBar", track)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	return t


## Same reason as the map — this survives the scene change.
func _on_game_ended(_result: String) -> void:
	close()
