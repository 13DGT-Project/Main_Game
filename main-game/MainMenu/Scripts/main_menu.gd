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
	get_tree().change_scene_to_file("res://Backend/Intro/NameEntry.tscn")

	#Inventory.get_node("UI").show()

func _on_quit_pressed() -> void:
	get_tree().quit()

const SETTINGS_SCENE := preload("res://Backend/Settings/Scenes/settings.tscn")
var _settings: Node = null

## Settings opens on top of the main menu instead of replacing it, so closing
## it just takes you straight back here (the pause menu does the same in-game).
func _on_settings_pressed() -> void:
	if _settings != null and is_instance_valid(_settings):
		return
	_settings = SETTINGS_SCENE.instantiate()
	_settings.embedded = true
	_settings.closed.connect(func(): _settings = null)
	add_child(_settings)
	for c in _settings.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).layer = 10

func _on_instructions_pressed() -> void:
	get_tree().change_scene_to_file("res://Backend/Instructions/instruction.tscn")

	
	
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Backend/Credits/credits.tscn")
