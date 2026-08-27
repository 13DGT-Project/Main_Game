extends Node3D

## Marker shown on the minimap. The sprite sits on visual layer 10, which the
## player's own camera excludes and the MinimapCam includes — so it only ever
## appears on the minimap, never in the world.

@export var map_icon: Texture
## Rotate the icon to match where the player is looking. Leave off for static
## markers like buildings.
@export var follow_head_yaw: bool = true

@onready var icon_sprite: Sprite3D = $IconSprite

var _head: Node3D = null


func _ready() -> void:
	if map_icon:
		icon_sprite.texture = map_icon

	if follow_head_yaw:
		# The player turns by rotating Head, not the body, so an icon parented
		# to the body would never turn. Track the Head's yaw instead.
		var parent := get_parent()
		if parent:
			_head = parent.get_node_or_null("Head")


func _process(_delta: float) -> void:
	if _head == null:
		return
	# Match the head's yaw only — the icon must stay flat for a top-down view.
	global_rotation = Vector3(0.0, _head.global_rotation.y, 0.0)
