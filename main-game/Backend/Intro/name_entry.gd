## name_entry.gd
## First thing the player sees after starting a new game. Sets
## GameBackend.player_name, which NPCs and the HUD use.
extends Control

@onready var name_input: LineEdit = $CenterContainer/VBoxContainer/NameInput
@onready var confirm_button: Button = $CenterContainer/VBoxContainer/ConfirmButton

const NEXT_SCENE := "res://Backend/Intro/university_select.tscn"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	confirm_button.pressed.connect(_confirm)
	name_input.text_submitted.connect(func(_t): _confirm())
	name_input.grab_focus()


func _confirm() -> void:
	var entered: String = name_input.text.strip_edges()
	# Fall back to a default rather than letting an empty name through.
	if entered == "":
		entered = "Alex"
	# Keep it sane for UI width and dialogue insertion.
	if entered.length() > 16:
		entered = entered.substr(0, 16)
	GameBackend.player_name = entered
	get_tree().change_scene_to_file(NEXT_SCENE)
