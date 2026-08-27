## scene_door.gd
## Attach to an Area3D with a CollisionShape3D child. Walking into it as the
## Player switches to `next_scene`.
##
## RETURNING WITHOUT GETTING STUCK
## Two things stop the "walk out, get yanked straight back in" loop:
##
##  1. PUSH-BACK. When you trigger the door we save your position nudged a
##     couple of metres back along the direction you came from (door -> you),
##     so you reappear just outside the trigger volume rather than inside it.
##
##  2. DISTANCE ARMING. A door will not fire until the player has been at
##     least `arm_distance` away from it at some point since the scene
##     loaded. This deliberately does NOT rely on Area3D overlap state,
##     because a teleported body doesn't register an overlap until the next
##     physics step — which is exactly what made the earlier guard fail.
extends Area3D

@export var next_scene: String = ""
## Optional. If set, you reappear here instead of just outside the door.
@export var spawn_point: Node3D
## How far the player must get from this door before it can fire again.
## Raise it if your doors are large or your map is big.
@export var arm_distance: float = 4.0
## How far back from the door to place you on return.
@export var push_back: float = 2.5

var _armed: bool = false
var _player: Node3D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_player = get_tree().get_first_node_in_group("Player")
	# Nothing to guard against if there's no player yet — arm and let the
	# distance check below correct us once the player appears.
	_armed = false


func _process(_delta: float) -> void:
	if _armed:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("Player")
		return
	if global_position.distance_to(_player.global_position) > arm_distance:
		_armed = true


func _on_body_exited(body: Node3D) -> void:
	# Belt and braces alongside the distance check above.
	if body.is_in_group("Player"):
		_armed = true


func _on_body_entered(body: Node3D) -> void:
	if not _armed:
		return
	if not body.is_in_group("Player"):
		return
	if next_scene == "":
		push_warning("scene_door: next_scene not set on %s" % name)
		return

	if spawn_point:
		GameBackend.return_position = spawn_point.global_position
	else:
		# Nudge back along the direction you approached from, so you land
		# outside the trigger rather than standing in it.
		var away: Vector3 = body.global_position - global_position
		away.y = 0.0
		if away.length() < 0.05:
			away = Vector3(0, 0, 1)  # degenerate case: just pick a direction
		GameBackend.return_position = body.global_position + away.normalized() * push_back
	GameBackend.has_return_position = true
	get_tree().change_scene_to_file(next_scene)
