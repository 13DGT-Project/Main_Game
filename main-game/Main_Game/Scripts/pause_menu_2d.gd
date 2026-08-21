## pause_menu_2d.gd
## Standalone pause menu for the 2D scenes (school/work/home) — MainMap has
## its own embedded PauseMenu already; this is a separate instance with the
## same buttons, but never force-captures the mouse on resume (these scenes
## are point-and-click, not an FPS camera).
extends Control

@onready var main_buttons = $VBoxContainer

@onready var resume_button: Button = $VBoxContainer/Resume
@onready var main_menu_button: Button = $VBoxContainer/MainMenu
@onready var quit_button: Button = $VBoxContainer/Quit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		get_tree().paused = not get_tree().paused
		visible = get_tree().paused
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")
	MusicManager.resume_music()


func _on_quit_pressed() -> void:
	get_tree().quit()
