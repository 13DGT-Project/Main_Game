## scene_door.gd
## Attach to any Area3D with a CollisionShape3D child. Walking into it (as the
## Player) changes to `next_scene`. Same pattern as main_map.gd's existing
## Nblockdoor, just reusable so you don't need a new script per door.
##
## Setup in the editor:
## 1. Add an Area3D node in MainMap.tscn (e.g. "SchoolDoor") with this script.
## 2. Give it a CollisionShape3D child sized/positioned at the school entrance.
## 3. Set `next_scene` in the Inspector to res://Main_Game/Scenes/school_scene.tscn
##    (or WorkScene.tscn / HomeScene.tscn for the other doors).
## 4. IMPORTANT for a correct spawn point: add a Marker3D node somewhere near
##    the door but clearly OUTSIDE it (not overlapping the door's own
##    CollisionShape3D, or walking back out would instantly re-trigger it),
##    and drag it into this door's `spawn_point` field in the Inspector.
##    This is far more reliable than a computed offset, since it doesn't
##    depend on guessing which way the door is rotated — you just place the
##    marker exactly where you want the player to reappear.
## 5. Repeat for the other doors.
extends Area3D

@export var next_scene: String = ""
@export var spawn_point: Node3D  ## Drag a Marker3D here — see notes above.
@export var exit_offset: Vector3 = Vector3(0, 0, 3)  ## Fallback only, used if spawn_point isn't set.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if next_scene == "":
		push_warning("scene_door: next_scene not set on %s" % name)
		return
	if body.is_in_group("Player"):
		if spawn_point:
			GameBackend.return_position = spawn_point.global_position
		else:
			push_warning("scene_door: no spawn_point set on %s, using a guessed offset — this can spawn you inside a wall. Add a Marker3D and assign it for a reliable spawn." % name)
			GameBackend.return_position = global_position + (global_transform.basis * exit_offset)
		GameBackend.has_return_position = true
		get_tree().change_scene_to_file(next_scene)
