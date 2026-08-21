extends Node3D

@export var next_scene = "res://Main_Game/Scenes/n_block.tscn"
const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")

func _ready() -> void:
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file(next_scene)
