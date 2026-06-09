extends HBoxContainer

 
var slots : Array

func _ready():
	get_slots()
	Inventory.inventory_changed.connect(_update_hotbar)
	Inventory.slot_selected.connect(_highlight_slot)
	_update_hotbar()
 
 
func get_slots():
	slots = get_children()
	for slot : TextureButton in slots:
		slot.pressed.connect(Inventory.select_slot.bind(slot.get_index()))


func _update_hotbar():
	for slot : TextureButton in slots:
		var item = Inventory.hotbar[slot.get_index()]
		slot.texture_normal = item.icon   if item else null
		
func _highlight_slot(slot_index: int):
	for i in range(4):
		slots[i].modulate = Color(1,1,1)
	slots[slot_index].modulate = Color(1.5, 1.5, 1.5)
