## major_select.gd
## Root script for MajorSelect.tscn. Shown right after picking a university,
## before MainMap loads. Picking a major sets which 3 subjects you'll study
## all year (GameBackend.set_major()).
extends Control

@onready var science_btn: Button = $CenterContainer/VBoxContainer/ScienceButton
@onready var engineering_btn: Button = $CenterContainer/VBoxContainer/EngineeringButton
@onready var health_btn: Button = $CenterContainer/VBoxContainer/HealthButton
@onready var arts_btn: Button = $CenterContainer/VBoxContainer/ArtsButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	science_btn.pressed.connect(_choose.bind("Science"))
	engineering_btn.pressed.connect(_choose.bind("Engineering"))
	health_btn.pressed.connect(_choose.bind("Health Science"))
	arts_btn.pressed.connect(_choose.bind("Arts & Commerce"))


func _choose(major: String) -> void:
	GameBackend.set_major(major)
	MusicManager.pause_music()
	get_tree().change_scene_to_file("res://Main_Game/Scenes/MainMap.tscn")
	Inventory.get_node("UI").show()
