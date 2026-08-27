extends Camera3D

## Follows the player from directly overhead so the minimap stays centred.

var player: Player


func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")


func _physics_process(_delta: float) -> void:
	# The player may not exist yet (or at all) on the first frames, so re-check
	# rather than hard-crashing in _physics_process.
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		return
	global_position = Vector3(
		player.global_position.x,
		50.0,
		player.global_position.z
	)
