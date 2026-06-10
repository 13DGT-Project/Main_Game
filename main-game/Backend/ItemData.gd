extends Resource
class_name ItemData
 
@export var item_name: String
@export var icon: Texture2D = preload("res://icon.svg")
@export var mesh_scene: PackedScene
@export var interactable_scene : PackedScene = preload("res://Backend/Resource/Scenes_Interactables/interactables.tscn")

 
