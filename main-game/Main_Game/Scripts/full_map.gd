## full_map.gd
## Press M to open a full-screen map of the world.
##
## Deliberately self-sufficient:
##  * Listens for the "map" action AND the raw M key, so it still works if
##    Godot hasn't picked up the new Input Map entry yet (that needs a project
##    reload after project.godot is edited outside the editor).
##  * Draws a schematic map from door/player positions on its own. If a
##    FullMapViewport exists it also renders the real world behind that, but
##    the map is fully usable either way rather than silently doing nothing.
extends CanvasLayer

const DOOR_COLOURS := {
	"school": Color(0.45, 0.85, 0.55),
	"work": Color(0.45, 0.68, 1.0),
	"home": Color(1.0, 0.78, 0.35),
	"canteen": Color(1.0, 0.55, 0.45),
	"dairy": Color(0.78, 0.58, 1.0),
	"examhall": Color(0.95, 0.95, 0.6),
}

var _root: Control
var _dim: ColorRect
var _map_rect: TextureRect
var _overlay: Control
var _title: Label
var _hint: Label

var _player: Node3D = null
var _doors: Array = []
var _is_open: bool = false

# World bounds the schematic uses. Recomputed from whatever we find.
var _world_min := Vector2(-60, -120)
var _world_max := Vector2(120, 60)


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	print("[FullMap] ready — press M to open the map")
	# As an autoload we outlive scene changes, so re-scan whenever the scene
	# swaps rather than only once at startup.
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_discover")
	GameBackend.game_ended.connect(_on_game_ended)


var _rescan_queued: bool = false

## Cheap trigger: when a new Area3D shows up, the scene has probably changed,
## so queue a single re-scan for the end of the frame.
func _on_node_added(node: Node) -> void:
	if node is Area3D and not _rescan_queued:
		_rescan_queued = true
		call_deferred("_deferred_rescan")


func _deferred_rescan() -> void:
	_rescan_queued = false
	_discover()


func _build_ui() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.78)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dim)

	_map_rect = TextureRect.new()
	_map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_map_rect)

	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_markers)
	_root.add_child(_overlay)

	_title = Label.new()
	_title.text = "MAP"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_root.add_child(_title)

	_hint = Label.new()
	_hint.text = "Press M to close"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 16)
	_root.add_child(_hint)

	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_dim.position = Vector2.ZERO
	_dim.size = vp

	var side: float = max(min(vp.x, vp.y) - 120.0, 240.0)
	var origin := Vector2((vp.x - side) * 0.5, (vp.y - side) * 0.5 + 20.0)

	_map_rect.position = origin
	_map_rect.size = Vector2(side, side)
	_overlay.position = origin
	_overlay.size = Vector2(side, side)

	_title.position = Vector2(0, origin.y - 46.0)
	_title.size = Vector2(vp.x, 34)
	_hint.position = Vector2(0, origin.y + side + 10.0)
	_hint.size = Vector2(vp.x, 24)


func _discover() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	# Optional: real rendered world behind the schematic.
	var viewport := scene.get_node_or_null("FullMapViewport")
	if viewport is SubViewport:
		_map_rect.texture = (viewport as SubViewport).get_texture()
	else:
		push_warning("full_map: no FullMapViewport in this scene — showing the schematic map only.")

	_player = get_tree().get_first_node_in_group("Player")

	_doors.clear()
	var pts: Array[Vector2] = []
	for child in scene.get_children():
		if child is Area3D and "next_scene" in child:
			var path_lower: String = str(child.next_scene).to_lower()
			var label := "?"
			var colour := Color(0.85, 0.85, 0.85)
			for key in DOOR_COLOURS:
				if key in path_lower:
					label = key.capitalize()
					colour = DOOR_COLOURS[key]
					break
			var flat := Vector2(child.global_position.x, child.global_position.z)
			_doors.append({"name": label, "pos": flat, "colour": colour})
			pts.append(flat)

	if _player != null:
		pts.append(Vector2(_player.global_position.x, _player.global_position.z))

	print("[FullMap] scanned '%s' — %d doors, player %s, viewport %s" % [
		scene.name, _doors.size(),
		"found" if _player else "MISSING",
		"found" if _map_rect.texture else "none (schematic only)"])

	# Frame everything we found, with margin, and keep it square so the
	# schematic isn't stretched relative to the rendered view.
	if pts.size() >= 2:
		var mn: Vector2 = pts[0]
		var mx: Vector2 = pts[0]
		for p in pts:
			mn.x = minf(mn.x, p.x); mn.y = minf(mn.y, p.y)
			mx.x = maxf(mx.x, p.x); mx.y = maxf(mx.y, p.y)
		var centre: Vector2 = (mn + mx) * 0.5
		var span: float = maxf(mx.x - mn.x, mx.y - mn.y) * 1.25
		span = maxf(span, 20.0)
		_world_min = centre - Vector2(span, span) * 0.5
		_world_max = centre + Vector2(span, span) * 0.5


func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if InputMap.has_action("map") and event.is_action_pressed("map"):
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		# Fallback: works even before Godot reloads the Input Map.
		pressed = true
	if pressed:
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	# Re-scan on demand so we always reflect the scene we're actually in.
	_discover()
	if _doors.is_empty() and _player == null:
		print("[FullMap] nothing to map in this scene (no doors or player found)")
		return
	_is_open = not _is_open
	_root.visible = _is_open
	if _is_open:
		if _doors.is_empty():
			_discover()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		# Only the 3D map captures the mouse; 2D scenes keep it visible.
		if _player != null and is_instance_valid(_player):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if _is_open:
		_overlay.queue_redraw()


func _world_to_rect(world_xz: Vector2) -> Vector2:
	var span: Vector2 = _world_max - _world_min
	var nx: float = (world_xz.x - _world_min.x) / maxf(1.0, span.x)
	var ny: float = (world_xz.y - _world_min.y) / maxf(1.0, span.y)
	return Vector2(clampf(nx, 0.0, 1.0) * _overlay.size.x,
				   clampf(ny, 0.0, 1.0) * _overlay.size.y)


func _draw_markers() -> void:
	var font: Font = ThemeDB.fallback_font

	# Backing panel — also means the map is legible with no rendered texture.
	if _map_rect.texture == null:
		_overlay.draw_rect(Rect2(Vector2.ZERO, _overlay.size), Color(0.16, 0.18, 0.24, 1.0), true)
	_overlay.draw_rect(Rect2(Vector2.ZERO, _overlay.size), Color(1, 1, 1, 0.28), false, 2.0)

	for door in _doors:
		var p: Vector2 = _world_to_rect(door.pos)
		_overlay.draw_rect(Rect2(p - Vector2(8, 8), Vector2(16, 16)), door.colour, true)
		_overlay.draw_rect(Rect2(p - Vector2(8, 8), Vector2(16, 16)), Color(0, 0, 0, 0.75), false, 2.0)
		if font:
			_overlay.draw_string(font, p + Vector2(14, 6), door.name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, door.colour)

	#if _player != null and is_instance_valid(_player):
		#var pp: Vector2 = _world_to_rect(Vector2(_player.global_position.x, _player.global_position.z))
		#_overlay.draw_circle(pp, 8.0, Color(1.0, 0.9, 0.3))
		#_overlay.draw_arc(pp, 12.0, 0, TAU, 20, Color(1.0, 0.9, 0.3, 0.85), 2.0)
		#var head := _player.get_node_or_null("Head")
		#var src: Node3D = head if head else _player
		#var fwd: Vector3 = -src.global_transform.basis.z
		#var fwd2 := Vector2(fwd.x, fwd.z)
		#if fwd2.length() > 0.01:
			#_overlay.draw_line(pp, pp + fwd2.normalized() * 22.0, Color(1.0, 0.9, 0.3), 3.0)
		#if font:
			#_overlay.draw_string(font, pp + Vector2(14, -10), "You",
				#HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.9, 0.3))


## Autoload overlay: it outlives the scene change, so it has to hide itself
## when the run ends or it sits on top of the ending screen.
func _on_game_ended(_result: String) -> void:
	_is_open = false
	if _root:
		_root.visible = false
