## scene_door.gd
## Attach to any Area3D with a CollisionShape3D child. Walking into it (as the
## Player) changes to `next_scene`. Same pattern as main_map.gd's existing
## Nblockdoor, just reusable so you don't need a new script per door.
##
## Setup in the editor:
## 1. Add an Area3D node in MainMap.tscn (e.g. "SchoolDoor") with this script.
## 2. Give it a CollisionShape3D child sized/positioned at the school entrance.
## 3. Set `next_scene` in the Inspector to res://Main_Game/Scenes/school_scene.tscn
##    (or WorkScene.tscn for the work entrance).
## 4. Repeat for a second door pointing at WorkScene.tscn.
extends Area3D

@export var next_scene: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if next_scene == "":
		push_warning("scene_door: next_scene not set on %s" % name)
		return
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file(next_scene)
