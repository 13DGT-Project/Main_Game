extends Node2D




func _on_exit_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")
