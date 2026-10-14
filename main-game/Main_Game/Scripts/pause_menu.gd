extends Control

## Pause menu. One copy lives in each gameplay scene.
##
## Things it has to get right (each of these used to soft-lock the game):
##  * It must draw ABOVE everything else, including a scene's own minigame
##    overlay (which sits on a CanvasLayer). So on start-up it moves itself
##    onto its own high CanvasLayer.
##  * Resuming must put the mouse back how it was BEFORE pausing. The 2D
##    scenes and every task panel need a visible cursor; only the 3D map
##    wants it captured. Always capturing hid the cursor while a task panel
##    was still open, so nothing could be clicked.
##  * Esc while the laptop or dev panel is open belongs to them (it closes
##    them), not to the pause menu.

## Kept so existing scenes still load; resuming now restores the previous mouse mode instead.
@export var capture_mouse_on_resume: bool = true

const LAYER := 120
const SETTINGS_SCENE := "res://Backend/Settings/Scenes/settings.tscn"
const HELP_SCENE := "res://Backend/Instructions/instruction.tscn"

@onready var main_buttons = $VBoxContainer
@onready var pause_menu = $"."

var _mouse_before_pause: int = Input.MOUSE_MODE_VISIBLE
var _sub_screen: Node = null


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_move_to_top_layer.call_deferred()


func _move_to_top_layer() -> void:
	var parent := get_parent()
	if parent is CanvasLayer and (parent as CanvasLayer).layer >= LAYER:
		return
	var layer := CanvasLayer.new()
	layer.name = "PauseLayer"
	layer.layer = LAYER
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	# Add next to the scene root, so it doesn't follow a Camera2D around.
	var root: Node = get_tree().current_scene if get_tree().current_scene != null else parent
	root.add_child(layer)
	reparent(layer, false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_pause_menu() -> void:
	pause()


func back_to_pause_menu() -> void:
	_close_sub_screen()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("Escape"):
		return
	if _another_overlay_owns_escape():
		return
	get_viewport().set_input_as_handled()
	if _sub_screen != null:
		_close_sub_screen()
	elif get_tree().paused and visible:
		resume()
	elif not get_tree().paused:
		pause()


## The laptop and dev panel close themselves on Esc.
func _another_overlay_owns_escape() -> bool:
	if get_tree().paused:
		return false
	var laptop := get_node_or_null("/root/Laptop")
	if laptop != null and laptop.has_method("is_open") and laptop.is_open():
		return true
	var dev := get_node_or_null("/root/DevPanel")
	if dev != null and bool(dev.get("_is_open")):
		return true
	return false


func pause() -> void:
	if get_tree().paused:
		return
	_mouse_before_pause = Input.mouse_mode
	# The phone keeps running while paused (it has to, to work at all), so
	# put it away rather than leave it live underneath the menu.
	var phone := get_node_or_null("/root/PhoneApp")
	if phone != null and phone.get("panel") != null and phone.panel.visible:
		phone.close()
	get_tree().paused = true
	show()
	main_buttons.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume() -> void:
	_close_sub_screen()
	get_tree().paused = false
	visible = false
	Input.mouse_mode = _mouse_before_pause


func _on_resume_pressed() -> void:
	resume()


func _on_main_menu_pressed() -> void:
	_close_sub_screen()
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")
	MusicManager.resume_music()


func _on_settings_pressed() -> void:
	_open_sub_screen(SETTINGS_SCENE)


func _on_help_pressed() -> void:
	_open_sub_screen(HELP_SCENE)


## Settings and How to Play open on top of the pause menu instead of
## switching scene, so you go straight back to your game afterwards.
func _open_sub_screen(path: String) -> void:
	_close_sub_screen()
	var scene: PackedScene = load(path)
	if scene == null:
		return
	_sub_screen = scene.instantiate()
	_sub_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	if "embedded" in _sub_screen:
		_sub_screen.embedded = true
	if _sub_screen.has_signal("closed"):
		_sub_screen.closed.connect(_on_sub_screen_closed)
	get_parent().add_child(_sub_screen)
	for c in _sub_screen.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).layer = LAYER + 1
	main_buttons.hide()


func _on_sub_screen_closed() -> void:
	_sub_screen = null
	main_buttons.show()


func _close_sub_screen() -> void:
	if _sub_screen != null and is_instance_valid(_sub_screen):
		_sub_screen.queue_free()
	_sub_screen = null
	main_buttons.show()


func _on_quit_pressed() -> void:
	get_tree().quit()
