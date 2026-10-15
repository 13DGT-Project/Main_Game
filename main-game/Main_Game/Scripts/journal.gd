## The J journal: a notebook with your progress on the left page and
## everything that's happened on the right. The layout lives in Journal.tscn;
## the cards and bars are built here because they depend on the run.
extends CanvasLayer

# Notebook palette — warm paper, dark ink, red-pen accents.
const PAPER := Color("f4eedf")
const CARD := Color("ebe2cb")
const INK := Color("2f2a24")
const INK_SOFT := Color("6f6556")
const RED_PEN := Color("a1412f")
const RULE := Color("c3d3e6")
const SPINE := Color("5b3a29")
const STICKY := Color("ffe48a")

const GOOD := Color("3f9a5b")
const OKAY := Color("d69a2a")
const BAD := Color("c8513e")

const MAX_SIZE := Vector2(1180, 760)

## The 3D map captures the mouse for the camera, so free it while the journal
## is open and hand back whatever mode it was in when we close.
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE

@onready var panel: Control = $Panel
@onready var book: PanelContainer = $Panel/Book
@onready var title_label: Label = $Panel/Book/Margin/VBox/Header/TitleLabel
@onready var day_chip: Label = $Panel/Book/Margin/VBox/Header/DayChip
@onready var close_button: Button = $Panel/Book/Margin/VBox/Header/CloseButton
@onready var summary_list: VBoxContainer = $Panel/Book/Margin/VBox/Columns/SummaryColumn/SummaryScroll/SummaryPad/SummaryList
@onready var entries_container: VBoxContainer = $Panel/Book/Margin/VBox/Columns/EventsColumn/EventsScroll/EventsPad/EntriesContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	book.theme = _make_theme()
	book.add_theme_stylebox_override("panel", _paper_style())
	title_label.add_theme_color_override("font_color", INK)
	day_chip.add_theme_stylebox_override("normal", _box(RED_PEN, 12, 12, 4))
	day_chip.add_theme_color_override("font_color", Color.WHITE)
	close_button.pressed.connect(_close)
	GameBackend.journal_updated.connect(_refresh_entries)
	GameBackend.stats_changed.connect(_refresh_summary)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh_entries()
	_refresh_summary()


func _input(event: InputEvent) -> void:
	var pressed_j: bool = event.is_action_pressed("journal")
	if not pressed_j and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_J:
			pressed_j = true
	if pressed_j:
		if panel.visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	_layout()
	_refresh_entries()
	_refresh_summary()
	panel.visible = true
	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close() -> void:
	if not panel.visible:
		return
	panel.visible = false
	Input.mouse_mode = _mouse_before


## Leaving the scene with the journal open shouldn't leave the mouse stuck.
func _exit_tree() -> void:
	if panel != null and panel.visible:
		Input.mouse_mode = _mouse_before


## Centre the book and shrink it on small windows.
func _layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var size := Vector2(minf(MAX_SIZE.x, vp.x - 48), minf(MAX_SIZE.y, vp.y - 48))
	book.size = size
	book.position = ((vp - size) * 0.5).floor()


# ---------------------------------------------------------------- summary

func _refresh_summary() -> void:
	if summary_list == null:
		return
	_clear(summary_list)
	day_chip.text = tr("COMMON_DAY") % GameBackend.get_elapsed_days()

	# Promises first: they are the thing you can still act on today.
	var briefing: Array = GameBackend.commitment_briefing()
	var upcoming: Array = []
	for c in GameBackend.commitments:
		if int(c.day) > GameBackend.get_elapsed_days():
			upcoming.append((tr("COMMON_DAY") + ": %s (%s)") % [
				int(c.day), str(c.label), GameBackend.commitment_place(str(c.kind))])
	if not briefing.is_empty() or not upcoming.is_empty():
		var sticky := _card(STICKY)
		if not briefing.is_empty():
			sticky.add_child(_heading(tr("JOURNAL_TODAY_PROMISED"), RED_PEN))
			for line in briefing:
				sticky.add_child(_text("•  " + str(line)))
		if not upcoming.is_empty():
			sticky.add_child(_heading(tr("JOURNAL_COMING_UP"), INK_SOFT))
			for line in upcoming:
				sticky.add_child(_text("•  " + str(line), INK_SOFT))

	# Where you're aiming.
	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var money_needed: float = uni.get("money_needed", 0)
	var grades_needed: float = uni.get("grades_needed", 0)
	var major_text: String = GameBackend.major_name(GameBackend.selected_major) if GameBackend.selected_major != "" else tr("JOURNAL_NOT_CHOSEN")
	var goal := _card(CARD)
	goal.add_child(_text(tr("JOURNAL_SUMMARY_HEAD") % [
		GameBackend.university_name(GameBackend.selected_university),
		GameBackend.city_name(str(uni.get("location", "?"))), major_text, GameBackend.days_remaining]))

	# Money and grades, as bars against what the university wants.
	var progress := _card(CARD)
	progress.add_child(_text((tr("COMMON_MONEY") + ": $%.2f / $%.0f") % [GameBackend.money, money_needed]))
	progress.add_child(_bar(GameBackend.money, money_needed, GOOD))
	var overall: float = GameBackend.get_overall_grade()
	progress.add_child(_text(tr("JOURNAL_OVERALL_GRADE") % [overall, grades_needed]))
	progress.add_child(_bar(overall, 100.0, _grade_colour(overall, grades_needed), grades_needed))

	if not GameBackend.active_subjects.is_empty():
		var subjects := _card(CARD)
		subjects.add_child(_heading(tr("JOURNAL_SUBJECTS"), INK_SOFT))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 4)
		subjects.add_child(grid)
		for s in GameBackend.active_subjects:
			var g: float = GameBackend.subject_grades.get(s, 0.0)
			var name_lbl := _text(GameBackend.subject_name(str(s)), INK, 15)
			name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
			name_lbl.clip_text = true
			name_lbl.custom_minimum_size.x = 130
			grid.add_child(name_lbl)
			var b := _bar(g, 100.0, _grade_colour(g, grades_needed), grades_needed)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			grid.add_child(b)
			var n := _text("%.0f" % g, INK, 15)
			n.autowrap_mode = TextServer.AUTOWRAP_OFF
			n.custom_minimum_size.x = 30
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			grid.add_child(n)

	# How you're holding up. Temptation is the one where high is bad.
	var wellbeing := _card(CARD)
	wellbeing.add_child(_heading(tr("JOURNAL_WELLBEING"), INK_SOFT))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 16)
	stats.add_theme_constant_override("v_separation", 6)
	wellbeing.add_child(stats)
	for row in [["HUD_ENERGY", GameBackend.energy, Color("e0a030")],
			["HUD_SANITY", GameBackend.sanity, Color("8a63c9")],
			["HUD_THIRST", GameBackend.thirst, Color("3d9ad6")],
			["HUD_TEMPTATION", GameBackend.temptation, BAD]]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 2)
		cell.add_child(_text("%s  %.0f" % [tr(row[0]), row[1]], INK, 15))
		cell.add_child(_bar(row[1], 100.0, row[2]))
		stats.add_child(cell)

	# University Entrance — the actual gate.
	var ue := _card(CARD)
	var ue_ok: bool = GameBackend.has_university_entrance()
	var ue_head := HBoxContainer.new()
	ue_head.add_child(_heading(tr("NCEA_UE"), INK_SOFT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ue_head.add_child(spacer)
	var pill := Label.new()
	pill.visible = ue_ok
	pill.text = "✓"
	pill.add_theme_font_size_override("font_size", 14)
	pill.add_theme_color_override("font_color", Color.WHITE)
	pill.add_theme_stylebox_override("normal", _box(GOOD if ue_ok else OKAY, 10, 9, 1))
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ue_head.add_child(pill)
	ue.add_child(ue_head)
	ue.add_child(_text(tr("NCEA_UE_ACHIEVED" if ue_ok else "NCEA_UE_NOT_ACHIEVED"), GOOD if ue_ok else RED_PEN, 15))
	ue.add_child(_text(GameBackend.ue_status_text(), INK_SOFT, 14))

	# The loan gates the ending as much as credits do.
	var loan := _card(CARD)
	loan.add_child(_heading(tr("JOURNAL_LOAN"), INK_SOFT))
	loan.add_child(_text(GameBackend.loan_status_text(), INK, 15))


func _grade_colour(value: float, needed: float) -> Color:
	if value >= needed:
		return GOOD
	if value >= needed - 10.0:
		return OKAY
	return BAD


# ---------------------------------------------------------------- entries

## Newest day first, each day's lines under a red-pen date, on ruled paper.
func _refresh_entries() -> void:
	if entries_container == null:
		return
	_clear(entries_container)
	var entries: Array = GameBackend.journal.duplicate()
	entries.reverse()
	if entries.is_empty():
		entries_container.add_child(_ruled(_text(tr("JOURNAL_NOTHING_YET"), INK_SOFT)))
		return
	var last_day: int = -1
	for entry in entries:
		var day: int = int(entry.day)
		if day != last_day:
			last_day = day
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(0, 8)
			entries_container.add_child(gap)
			var head := _text(tr("COMMON_DAY") % day, RED_PEN, 17)
			entries_container.add_child(_ruled(head))
		var mark: String = "★  " if bool(entry.get("notable", false)) else "•  "
		entries_container.add_child(_ruled(_text(mark + str(entry.text), INK, 16)))


# ---------------------------------------------------------------- helpers

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


## A rounded card added to the summary column; returns its inner VBox.
func _card(colour: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _box(colour, 10, 14, 10))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	pc.add_child(vb)
	summary_list.add_child(pc)
	return vb


func _heading(text: String, colour: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", colour)
	return l


func _text(text: String, colour: Color = INK, size: int = 16) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	return l


## A line of the notebook: the content with a faint blue rule underneath.
func _ruled(content: Control) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = RULE
	sb.border_width_bottom = 1
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(content)
	return pc


## A thin rounded bar. `marker` draws a tick where the target sits.
func _bar(value: float, max_value: float, colour: Color, marker: float = -1.0) -> Control:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = maxf(max_value, 1.0)
	bar.value = clampf(value, 0.0, bar.max_value)
	bar.custom_minimum_size = Vector2(60, 10)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(INK, 0.12)
	bg.set_corner_radius_all(5)
	var fg := StyleBoxFlat.new()
	fg.bg_color = colour
	fg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	if marker > 0.0 and marker < bar.max_value:
		var tick := ColorRect.new()
		tick.color = INK
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.anchor_left = marker / bar.max_value
		tick.anchor_right = tick.anchor_left
		tick.anchor_bottom = 1.0
		tick.offset_left = -1
		tick.offset_right = 1
		tick.offset_top = -3
		tick.offset_bottom = 3
		bar.add_child(tick)
	return bar


func _box(colour: Color, radius: int, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = colour
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb


## Cream paper with a leather spine down the left edge.
func _paper_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.set_corner_radius_all(16)
	sb.border_color = SPINE
	sb.border_width_left = 16
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 24
	sb.shadow_offset = Vector2(0, 8)
	return sb


func _make_theme() -> Theme:
	var t := Theme.new()
	t.set_color("font_color", "Label", INK)
	# Close button: ink outline that fills in on hover.
	var normal := _box(Color(0, 0, 0, 0), 10, 16, 6)
	normal.border_color = INK
	normal.set_border_width_all(2)
	var hover := normal.duplicate()
	hover.bg_color = INK
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", PAPER)
	t.set_color("font_pressed_color", "Button", PAPER)
	# Slim scrollbars that suit the paper.
	var track := StyleBoxFlat.new()
	track.bg_color = Color(INK, 0.06)
	track.set_corner_radius_all(4)
	track.content_margin_left = 3
	track.content_margin_right = 3
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(INK, 0.35)
	grab.set_corner_radius_all(4)
	t.set_stylebox("scroll", "VScrollBar", track)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	return t
