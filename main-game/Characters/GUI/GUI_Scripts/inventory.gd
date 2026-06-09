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


func add_item(item: ItemData) -> bool:
	for i in HOTBAR_SIZE:
		if hotbar[i] == null:
			hotbar[i] = item
			inventory_changed.emit()
			slot_selected.emit(i)
			return true
	return false
	
	
func select_slot(index: int):
	selected_slot = clamp(index, 0, HOTBAR_SIZE - 1)
	slot_selected.emit(selected_slot)
	
	
	
	
