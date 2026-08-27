## minimap.gd
## A small always-visible map in the corner, plus a room-name banner.
## Addresses the tester feedback: "Got lost around the map, hard to navigate".
##
## Any 2D scene can use this: instance it, then call setup() with the rooms
## and the player node. Rooms are {name, rect} where rect is a Rect2 in the
## same world coordinates the player moves in.
##
## NOTE: positions/sizes are set explicitly rather than via anchors. Setting
## anchors in code without also fixing offsets leaves controls collapsed at
## zero size — which is exactly why an earlier version of this drew nothing.
extends CanvasLayer

const MAP_SIZE := Vector2(240, 160)
const MAP_MARGIN := 16.0

var rooms: Array = []
var world_bounds: Rect2 = Rect2(0, 0, 1600, 1000)
var player_node: Node2D = null

var _map_panel: Panel
var _map_draw: Control
var _room_label: Label


func setup(p_rooms: Array, p_world_bounds: Rect2, p_player: Node2D) -> void:
	rooms = p_rooms
	world_bounds = p_world_bounds
	player_node = p_player


func _ready() -> void:
	layer = 8

	_room_label = Label.new()
	_room_label.add_theme_font_size_override("font_size", 22)
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_room_label)

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


## Explicit placement against the current viewport, recalculated on resize.
func _reposition() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_map_panel.position = Vector2(vp.x - MAP_SIZE.x - MAP_MARGIN, vp.y - MAP_SIZE.y - MAP_MARGIN)
	_room_label.size = Vector2(420, 30)
	_room_label.position = Vector2((vp.x - 420) * 0.5, 12)


func _process(_delta: float) -> void:
	if player_node == null or not is_instance_valid(player_node):
		return
	_map_draw.queue_redraw()
	_room_label.text = _room_name_at(player_node.global_position)


func _room_name_at(pos: Vector2) -> String:
	for room in rooms:
		if room.rect.has_point(pos):
			return room.name
	return "Corridor"


func _to_map(pos: Vector2) -> Vector2:
	var inner: Vector2 = MAP_SIZE - Vector2(16, 16)
	var nx: float = (pos.x - world_bounds.position.x) / maxf(1.0, world_bounds.size.x)
	var ny: float = (pos.y - world_bounds.position.y) / maxf(1.0, world_bounds.size.y)
	return Vector2(8, 8) + Vector2(clampf(nx, 0, 1) * inner.x, clampf(ny, 0, 1) * inner.y)


func _draw_map() -> void:
	_map_draw.draw_rect(Rect2(Vector2(4, 4), MAP_SIZE - Vector2(8, 8)), Color(0.14, 0.16, 0.21, 0.95), true)

	for room in rooms:
		var tl: Vector2 = _to_map(room.rect.position)
		var br: Vector2 = _to_map(room.rect.position + room.rect.size)
		var r := Rect2(tl, br - tl)
		_map_draw.draw_rect(r, Color(0.34, 0.40, 0.50, 1.0), true)
		_map_draw.draw_rect(r, Color(0.80, 0.86, 0.95, 1.0), false, 1.5)

	if player_node != null and is_instance_valid(player_node):
		var p: Vector2 = _to_map(player_node.global_position)
		_map_draw.draw_circle(p, 5.0, Color(1.0, 0.85, 0.25))
