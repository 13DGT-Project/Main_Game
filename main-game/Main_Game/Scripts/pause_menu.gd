extends Control


@onready var main_buttons = $VBoxContainer
@onready var pause_menu = $PauseMenu

func _ready():
	visible = false

func show_pause_menu():
	show()
	main_buttons.show()


func back_to_pause_menu():
	pass
		
func _process(_delta):
	if Input.is_action_just_pressed("Escape"):
		pause_menu.show()
		get_tree().paused = !get_tree().paused
		visible = get_tree().paused
		
		if get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED



func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
