extends RigidBody3D

@onready var mesh_instance_node = $MeshInstance3D
@export var item_data: ItemData



func _ready():
	name = item_data.item_name
	spawn_item_with_collision(item_data.mesh_scene)


func interact():
	if Inventory.add_item(item_data):
		call_deferred("queue_free")	
	else:
		print("Full Inventory")

func find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = find_first_mesh_instance(child)
		if result:
			return result
	return null
	
 
func spawn_item_with_collision(scene) -> Node3D:
	var inst = scene.instantiate()
 
	var mesh_instance = find_first_mesh_instance(inst)
	if mesh_instance and mesh_instance.mesh:
		var shape = mesh_instance.mesh.create_convex_shape()
		var col_shape = CollisionShape3D.new()
		col_shape.shape = shape
 
		self.add_child(inst)
		self.add_child(col_shape)
 
	return inst
