extends CanvasLayer

const TOAST_WIDTH: float = 330.0
const TOAST_HEIGHT: float = 74.0
const TOAST_MARGIN: float = 18.0
const TOAST_GAP: float = 8.0
const TOAST_LIFETIME: float = 4.5
const MAX_TOASTS: int = 4

const COLOUR_BADGE := Color(0.898, 0.282, 0.302)      # notification red
const COLOUR_TOAST_BG := Color(0.10, 0.11, 0.14, 0.96)
const COLOUR_ACCENT_MESSAGE := Color(0.35, 0.66, 1.0)
const COLOUR_ACCENT_IMPORTANT := Color(0.95, 0.72, 0.25)

var _root: Control
var _toast_holder: Control
var _toasts: Array = []

## Every badge ever attached, so a single messages_changed can refresh all of
## them without each caller having to remember to.
var _badges: Array = []


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	_root = Control.new()
	_root.name = "NotifierRoot"
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	_toast_holder = Control.new()
	_toast_holder.name = "Toasts"
	_toast_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_toast_holder)

	GameBackend.message_arrived.connect(_on_message_arrived)
	GameBackend.messages_changed.connect(refresh_badges)
	GameBackend.game_ended.connect(_on_game_ended)



# TOASTS

func _on_message_arrived(sender: String, thread_id: String) -> void:
	var important: bool = thread_id in ["nzqa_results", "university_offer",
		"studylink_approved", "studylink_declined"]
	notify(sender, "New message", COLOUR_ACCENT_IMPORTANT if important else COLOUR_ACCENT_MESSAGE)
	Audio.play("notify")


## Pops a banner
func notify(title: String, body: String = "", accent: Color = COLOUR_ACCENT_MESSAGE) -> void:
	if GameBackend.game_over:
		return
	while _toasts.size() >= MAX_TOASTS:
		_dismiss(_toasts[0], true)

	var toast := Panel.new()
	toast.custom_minimum_size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
	toast.size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = COLOUR_TOAST_BG
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	# Coloured stripe down the left edge, so an NZQA result reads differently
	# from your mate asking about the gym.
	style.border_width_left = 4
	style.border_color = accent
	toast.add_theme_stylebox_override("panel", style)

	# --- avatar circle with the sender's initial
	var dot := Panel.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.position = Vector2(16, 18)
	dot.size = Vector2(38, 38)
	var dot_style := StyleBoxFlat.new()
	dot_style.bg_color = accent.darkened(0.25)
	dot_style.corner_radius_top_left = 19
	dot_style.corner_radius_top_right = 19
	dot_style.corner_radius_bottom_left = 19
	dot_style.corner_radius_bottom_right = 19
	dot.add_theme_stylebox_override("panel", dot_style)
	toast.add_child(dot)

	var initial := Label.new()
	initial.text = title.substr(0, 1).to_upper() if title.length() > 0 else "?"
	initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	initial.position = Vector2.ZERO
	initial.size = Vector2(38, 38)
	initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initial.add_theme_font_size_override("font_size", 18)
	dot.add_child(initial)

	# --- text block, given the rest of the width explicitly
	var text_x: float = 64.0
	var text_w: float = TOAST_WIDTH - text_x - 14.0

	var title_label := Label.new()
	title_label.text = title
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.position = Vector2(text_x, 15)
	title_label.size = Vector2(text_w, 22)
	title_label.clip_text = true
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 15)
	toast.add_child(title_label)

	var body_label := Label.new()
	body_label.text = body
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.position = Vector2(text_x, 37)
	body_label.size = Vector2(text_w, 20)
	body_label.clip_text = true
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 12)
	body_label.add_theme_color_override("font_color", Color(0.68, 0.72, 0.80))
	toast.add_child(body_label)

	_toast_holder.add_child(toast)
	_toasts.append(toast)
	_layout_toasts()

	# Slide in from off the right edge.
	var vp: Vector2 = _viewport_size()
	var target_x: float = vp.x - TOAST_WIDTH - TOAST_MARGIN
	toast.position.x = vp.x + 20.0
	var tween := create_tween().bind_node(toast)
	tween.tween_property(toast, "position:x", target_x, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Expiry lives ON the node, swept in _process below. No lambda, no
	# captured node, nothing left holding a pointer to a freed toast.
	toast.set_meta("expires_at", Time.get_ticks_msec() + int(TOAST_LIFETIME * 1000.0))


## _root.size can still be zero on the very first frame, so fall back to the
## viewport rect rather than sliding the toast in from x = 20.
func _viewport_size() -> Vector2:
	var vp: Vector2 = _root.size
	if vp.x <= 1.0:
		vp = get_viewport().get_visible_rect().size
	return vp


## Sweeps expired toasts. Runs on the Notifier itself, so there is nothing to
## capture and nothing to go stale.
func _process(_delta: float) -> void:
	if _toasts.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	for i in range(_toasts.size() - 1, -1, -1):
		var t = _toasts[i]
		if not is_instance_valid(t):
			_toasts.remove_at(i)
			continue
		if t.get_meta("dismissing", false):
			continue
		if now >= int(t.get_meta("expires_at", 0)):
			_dismiss(t, false)


func _dismiss(toast: Control, instant: bool) -> void:
	if not is_instance_valid(toast):
		_toasts.erase(toast)
		return
	_toasts.erase(toast)
	if instant:
		toast.queue_free()
		_layout_toasts()
		return

	toast.set_meta("dismissing", true)
	# bind_node ties the tween's life to the toast: free the toast and the
	# tween is killed with it, instead of firing a callback into nothing.
	# queue_free is a Callable on the node itself, not a lambda closing over it.
	var tween := create_tween().bind_node(toast)
	tween.tween_property(toast, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(toast, "position:x", _viewport_size().x + 20.0, 0.25)
	tween.tween_callback(toast.queue_free)
	tween.tween_callback(_layout_toasts)


func _layout_toasts() -> void:
	var y: float = TOAST_MARGIN
	var right: float = _viewport_size().x - TOAST_WIDTH - TOAST_MARGIN
	for t in _toasts:
		if not is_instance_valid(t):
			continue
		t.size = Vector2(TOAST_WIDTH, TOAST_HEIGHT)
		t.position = Vector2(right, y)
		y += TOAST_HEIGHT + TOAST_GAP


func _on_game_ended(_result: String) -> void:
	for t in _toasts.duplicate():
		if is_instance_valid(t):
			t.queue_free()
	_toasts.clear()


# BADGES

## Sticks a badge on `host`'s top-right corner and returns it. Call
## set_badge_count(badge, n) to update, or just let refresh_badges() do it if
## you registered the badge with a source (see attach_message_badge below).
func attach_badge(host: Control, size: float = 22.0, nudge: Vector2 = Vector2(6, -6)) -> Control:
	if host == null:
		return null

	var badge := Panel.new()
	badge.name = "UnreadBadge"
	badge.custom_minimum_size = Vector2(size, size)
	badge.size = Vector2(size, size)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 50
	badge.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = COLOUR_BADGE
	style.corner_radius_top_left = int(size / 2.0)
	style.corner_radius_top_right = int(size / 2.0)
	style.corner_radius_bottom_left = int(size / 2.0)
	style.corner_radius_bottom_right = int(size / 2.0)
	# Thin dark ring so it reads against a bright icon as well as a dark one.
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.06, 0.07, 0.09, 0.9)
	badge.add_theme_stylebox_override("panel", style)

	var count := Label.new()
	count.name = "Count"
	count.text = "0"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	count.add_theme_font_size_override("font_size", int(size * 0.58))
	count.add_theme_color_override("font_color", Color(1, 1, 1))
	badge.add_child(count)

	host.add_child(badge)

	# Anchor to the host's top-right, then fix the offsets — anchors alone
	# would collapse it.
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.anchor_top = 0.0
	badge.anchor_bottom = 0.0
	badge.offset_left = -size + nudge.x
	badge.offset_right = nudge.x
	badge.offset_top = nudge.y
	badge.offset_bottom = size + nudge.y

	return badge


## Registers a badge to be kept in sync with the unread message count
## automatically. Use this unless you want a badge counting something else.
func attach_message_badge(host: Control, size: float = 22.0, nudge: Vector2 = Vector2(6, -6)) -> Control:
	var badge: Control = attach_badge(host, size, nudge)
	if badge != null:
		_badges.append(badge)
		set_badge_count(badge, GameBackend.unread_count)
	return badge


func set_badge_count(badge: Control, count: int) -> void:
	if badge == null or not is_instance_valid(badge):
		return
	var label := badge.get_node_or_null("Count") as Label
	if label == null:
		return
	var was_visible: bool = badge.visible
	badge.visible = count > 0
	label.text = "9+" if count > 9 else str(count)
	# A little pop the first time it appears or when it goes up, so it
	# catches your eye without being a whole animation system.
	if badge.visible and not was_visible:
		badge.scale = Vector2(0.4, 0.4)
		badge.pivot_offset = badge.size * 0.5
		var tween := create_tween().bind_node(badge)
		tween.tween_property(badge, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Refreshes every registered message badge. Hooked to messages_changed, so
## reading a thread updates the hotbar icon immediately.
func refresh_badges() -> void:
	var stale: Array = []
	for badge in _badges:
		if not is_instance_valid(badge):
			stale.append(badge)
			continue
		set_badge_count(badge, GameBackend.unread_count)
	for s in stale:
		_badges.erase(s)
