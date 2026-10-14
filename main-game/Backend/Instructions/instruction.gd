extends Node2D

## Set by the pause menu when this screen is opened on top of a game in
## progress: the Back button then closes it instead of going to the main menu.
var embedded: bool = false
signal closed



func _on_exit_settings_pressed() -> void:
	if embedded:
		closed.emit()
		queue_free()
		return
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")
