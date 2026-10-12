## minimap_3d.gd
## Corner minimap for the 3D MainMap. Projects world X/Z onto a flat 2D map,
## showing the player plus every scene_door in the level, so you can see where
## School / Work / Home / Canteen / Dairy are relative to you.
##
## Doors are auto-discovered (any Area3D with a `next_scene` property), so a
## door added in the editor appears here with no code change.
##
## NOTE: sizes/positions are explicit rather than anchor-based — setting
## anchors in code without fixing offsets collapses controls to zero size,
## which is why an earlier version of this drew nothing at all.
extends CanvasLayer

const MAP_SIZE := Vector2(230, 230)
const MAP_MARGIN := 16.0
const DOOR_COLORS := {
	"school": Color(0.45, 0.85, 0.55),
	"work": Color(0.45, 0.68, 1.0),
	"home": Color(1.0, 0.78, 0.35),
	"canteen": Color(1.0, 0.55, 0.45),
	"dairy": Color(0.78, 0.58, 1.0),
	"examhall": Color(0.95, 0.95, 0.6),
}

var world_min := Vector2(-150, -150)
var world_max := Vector2(150, 150)

var player_node: Node3D = null
var doors: Array = []

var _map_panel: Panel
var _map_draw: Control
var _legend: Label


func _ready() -> void:
	layer = 8

	_legend = Label.new()
	_legend.add_theme_font_size_override("font_size", 15)
	_legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_legend)

	_map_panel = Panel.new()
	_map_panel.size = MAP_SIZE
	add_child(_map_panel)

	_map_draw = Control.new()
	_map_draw.position = Vector2.ZERO
	_map_draw.size = MAP_SIZE
	_map_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_draw.draw.connect(_draw_map)
	_map_panel.add_child(_map_draw)

	_reposition()
	get_viewport().size_changed.connect(_reposition)
	call_deferred("_discover")


func _reposition() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_map_panel.position = Vector2(vp.x - MAP_SIZE.x - MAP_MARGIN, vp.y - MAP_SIZE.y - MAP_MARGIN)
	_legend.size = Vector2(MAP_SIZE.x, 24)
	_legend.position = Vector2(vp.x - MAP_SIZE.x - MAP_MARGIN, vp.y - MAP_SIZE.y - MAP_MARGIN - 26)


func _discover() -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return

	var players: Array = get_tree().get_nodes_in_group("Player")
	if players.size() > 0 and players[0] is Node3D:
		player_node = players[0]
	else:
		var p: Node = root.get_node_or_null("Player")
		if p is Node3D:
			player_node = p

	doors.clear()
	var points: Array[Vector2] = []
	for child in root.get_children():
		if child is Area3D and "next_scene" in child:
			var scene_path: String = str(child.next_scene).to_lower()
			var label := "?"
			var col := Color(0.85, 0.85, 0.85)
			for key in DOOR_COLORS:
				if key in scene_path:
					label = key.capitalize()
					col = DOOR_COLORS[key]
					break
			var flat := Vector2(child.global_position.x, child.global_position.z)
			doors.append({"name": label, "pos": flat, "color": col})
			points.append(flat)

	if player_node != null:
		points.append(Vector2(player_node.global_position.x, player_node.global_position.z))

	if points.size() >= 2:
		var mn: Vector2 = points[0]
		var mx: Vector2 = points[0]
		for pt in points:
			mn.x = minf(mn.x, pt.x); mn.y = minf(mn.y, pt.y)
			mx.x = maxf(mx.x, pt.x); mx.y = maxf(mx.y, pt.y)
		var pad: float = maxf(20.0, (mx - mn).length() * 0.15)
		world_min = mn - Vector2(pad, pad)
		world_max = mx + Vector2(pad, pad)


func _process(_delta: float) -> void:
	_map_draw.queue_redraw()
	if player_node != null and is_instance_valid(player_node) and doors.size() > 0:
		var nearest := ""
		var nearest_dist := INF
		var ppos := Vector2(player_node.global_position.x, player_node.global_position.z)
		for d in doors:
			var dist: float = ppos.distance_to(d.pos)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = d.name
		_legend.text = "Nearest: %s" % nearest
	else:
		_legend.text = "Map"


func _to_map(world_xz: Vector2) -> Vector2:
	var inner: Vector2 = MAP_SIZE - Vector2(16, 16)
	var span: Vector2 = world_max - world_min
	var nx: float = (world_xz.x - world_min.x) / maxf(1.0, span.x)
	var ny: float = (world_xz.y - world_min.y) / maxf(1.0, span.y)
	return Vector2(8, 8) + Vector2(clampf(nx, 0, 1) * inner.x, clampf(ny, 0, 1) * inner.y)


func _draw_map() -> void:
	_map_draw.draw_rect(Rect2(Vector2(4, 4), MAP_SIZE - Vector2(8, 8)), Color(0.14, 0.16, 0.22, 0.95), true)

	var f: Font = ThemeDB.fallback_font
	for d in doors:
		var p: Vector2 = _to_map(d.pos)
		_map_draw.draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), d.color, true)
		if f != null:
			_map_draw.draw_string(f, p + Vector2(9, 4), d.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, d.color)

	if player_node != null and is_instance_valid(player_node):
		var pp: Vector2 = _to_map(Vector2(player_node.global_position.x, player_node.global_position.z))
		_map_draw.draw_circle(pp, 5.0, Color(1.0, 0.9, 0.3))
		var fwd: Vector3 = -player_node.global_transform.basis.z
		var fwd2 := Vector2(fwd.x, fwd.z)
		if fwd2.length() > 0.01:
			_map_draw.draw_line(pp, pp + fwd2.normalized() * 14.0, Color(1.0, 0.9, 0.3), 2.0)
