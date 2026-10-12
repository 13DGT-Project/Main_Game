extends Node2D

@onready var Auckland = $Auckland
@onready var Canterbury = $Canterbury
@onready var Waikato = $Waikato

const MAJOR_SELECT_SCENE := "res://Backend/Intro/MajorSelect.tscn"

func _on_button_pressed() -> void:
	MusicManager.pause_music()
	get_tree().change_scene_to_file("res://Main_Game/Scenes/MainMap.tscn")
	Inventory.get_node("UI").show()


func _on_confirm_pressed() -> void:
	GameBackend.selected_university = "Auckland"
	get_tree().change_scene_to_file(MAJOR_SELECT_SCENE)


func _on_auckland_pressed() -> void:
	Auckland.show()
	Canterbury.hide()
	Waikato.hide()

func _on_confirm_2_pressed() -> void:
	GameBackend.selected_university = "Canterbury"
	get_tree().change_scene_to_file(MAJOR_SELECT_SCENE)
	
	
func _on_canterbury_pressed() -> void:
	Auckland.hide()
	Canterbury.show()
	Waikato.hide()
	

func _on_waikato_pressed() -> void:
	Waikato.show()
	Auckland.hide()
	Canterbury.hide()




func _on_confirm_3_pressed() -> void:
	GameBackend.selected_university = "Waikato"
	get_tree().change_scene_to_file(MAJOR_SELECT_SCENE)
