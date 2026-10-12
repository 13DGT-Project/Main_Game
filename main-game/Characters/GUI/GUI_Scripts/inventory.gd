extends Node

signal inventory_changed
signal slot_selected(slot_index: int)
signal item_drop(item)

const HOTBAR_SIZE := 4
var hotbar: Array[ItemData]
var selected_slot: int = 0
 
func _init():
	for i in HOTBAR_SIZE:
		hotbar.append( null )


func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_Q:
			drop_item(selected_slot)
		elif event.keycode == KEY_1:
			select_slot(0)
		elif event.keycode == KEY_2:
			select_slot(1)
		elif event.keycode == KEY_3:
			select_slot(2)
		elif event.keycode == KEY_4:
			select_slot(3)


func add_item(item: ItemData) -> bool:
	for i in HOTBAR_SIZE:
		if hotbar[i] == null:
			hotbar[i] = item
			inventory_changed.emit()
			select_slot(i)  # was just emitting slot_selected directly, which only
							# updated the UI highlight without actually moving
							# selected_slot — a picked-up item could highlight as
							# "selected" while use_item was still checking a
							# different slot entirely.
			return true
	return false
	
	
func select_slot(index: int):
	selected_slot = clamp(index, 0, HOTBAR_SIZE - 1)
	slot_selected.emit(selected_slot)
	

func spawn_item(item : ItemData):
	var interactable = item.interactable_scene.instantiate()
	interactable.item_data = item
	get_tree().current_scene.add_child(interactable)
	item_drop.emit(interactable)
	
	
func drop_item(slot_index: int):
	if hotbar[slot_index]:
		var dropped_item = hotbar[slot_index]
		spawn_item(dropped_item)
		hotbar[slot_index] = null
		inventory_changed.emit()
		if slot_index == selected_slot:
			slot_selected.emit(selected_slot)
