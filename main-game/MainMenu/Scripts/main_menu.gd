extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Inventory.get_node("UI").hide()
	MusicManager.play_track("menu")

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	#get_tree().change_scene_to_file("res://Main_Game/Scenes/MainMap.tscn")
	get_tree().change_scene_to_file("res://Backend/Intro/university_select.tscn")

	#Inventory.get_node("UI").show()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://Backend/Settings/Scenes/settings.tscn")

func _on_instructions_pressed() -> void:
	get_tree().change_scene_to_file("res://Backend/Instructions/instruction.tscn")

	
	
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Backend/Credits/credits.tscn")
