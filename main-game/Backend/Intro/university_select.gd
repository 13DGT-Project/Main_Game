extends Node2D

@onready var Auckland = $Auckland
@onready var Canterbury = $Canterbury


func _on_button_pressed() -> void:
	MusicManager.pause_music()
	get_tree().change_scene_to_file("res://Main_Game/Scenes/MainMap.tscn")
	Inventory.get_node("UI").show()


func _on_confirm_pressed() -> void:
	GameBackend.selected_university = "Auckland"
	MusicManager.pause_music()
	get_tree().change_scene_to_file("res://Main_Game/Scenes/MainMap.tscn")
	Inventory.get_node("UI").show()
	


func _on_auckland_pressed() -> void:
	Auckland.show()
	Canterbury.hide()


func _on_confirm_2_pressed() -> void:
	GameBackend.selected_university = "Canterbury"
	MusicManager.pause_music()
	get_tree().change_scene_to_file("res://Main_Game/Scenes/MainMap.tscn")
	Inventory.get_node("UI").show()
	
	
func _on_canterbury_pressed() -> void:
	Auckland.hide()
	Canterbury.show()
