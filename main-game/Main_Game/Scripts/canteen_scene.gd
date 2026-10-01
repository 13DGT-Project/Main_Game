extends Node2D

const MOVE_SPEED: float = 220.0
const MAIN_MAP_SCENE: String = "res://Main_Game/Scenes/MainMap.tscn"

const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const GUI_SCENE := preload("res://Characters/GUI/GUI_Scenes/gui.tscn")
const PAUSE_MENU_SCENE := preload("res://Main_Game/Scenes/PauseMenu.tscn")

const PLAY_AREA_MIN := Vector2(0, 0)
const PLAY_AREA_MAX := Vector2(800, 500)

@onready var player: CharacterBody2D = $Player
@onready var floor_layer: TileMapLayer = $Floor
@onready var walls_layer: TileMapLayer = $Walls

@onready var counter_area: Area2D = $CounterStation/InteractArea
@onready var counter_prompt: Label = $CounterStation/PromptLabel
@onready var exit_area: Area2D = $ExitStation/InteractArea
@onready var exit_prompt: Label = $ExitStation/PromptLabel

@onready var hint_panel: PanelContainer = $CanvasLayer/HUD/HintPanel
@onready var hint_label: Label = $CanvasLayer/HUD/HintPanel/HintLabel
@onready var minigame_overlay: Control = $CanvasLayer/MinigameOverlay
@onready var info_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var options_container: VBoxContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/OptionsContainer
@onready var feedback_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/FeedbackLabel

var current_station: String = ""
var _hint_time_left: float = 0.0
var task_active: bool = false


func _ready() -> void:
	Audio.play_ambience("school")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	counter_area.body_entered.connect(_on_station_entered.bind("counter"))
	counter_area.body_exited.connect(_on_station_exited.bind("counter"))
	exit_area.body_entered.connect(_on_station_entered.bind("exit"))
	exit_area.body_exited.connect(_on_station_exited.bind("exit"))

	GameBackend.game_ended.connect(_on_game_ended)
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())
	get_tree().current_scene.add_child(GUI_SCENE.instantiate())
	get_tree().current_scene.add_child(PAUSE_MENU_SCENE.instantiate())


func _physics_process(_delta: float) -> void:
	if task_active:
		player.velocity = Vector2.ZERO
		return
	var input_vec := Input.get_vector("left", "right", "up", "down")
	player.velocity = input_vec * MOVE_SPEED
	player.move_and_slide()
	player.global_position = player.global_position.clamp(PLAY_AREA_MIN, PLAY_AREA_MAX)


func _unhandled_input(event: InputEvent) -> void:
	if task_active or current_station == "":
		return
	if event.is_action_pressed("interact"):
		if current_station == "exit":
			get_tree().change_scene_to_file(MAIN_MAP_SCENE)
		else:
			_open_menu()


func _on_station_entered(body: Node, station: String) -> void:
	if body != player:
		return
	current_station = station
	_update_prompts()


func _on_station_exited(body: Node, station: String) -> void:
	if body != player:
		return
	if current_station == station:
		current_station = ""
	_update_prompts()


func _update_prompts() -> void:
	counter_prompt.visible = current_station == "counter"
	exit_prompt.visible = current_station == "exit"
	if not task_active:
		_set_hint("Press E to interact" if current_station != "" else "", 0.0)


func _open_menu() -> void:
	task_active = true
	feedback_label.text = ""
	for child in options_container.get_children():
		child.queue_free()

	var items: Array = WorkData.pick_menu(WorkData.CANTEEN_MENU, 8)
	for item in items:
		var ibtn := Button.new()
		ibtn.text = item.label
		ibtn.pressed.connect(_on_buy.bind(item))
		options_container.add_child(ibtn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Never mind"
	cancel_btn.pressed.connect(_close_menu)
	options_container.add_child(cancel_btn)

	_set_hint("")
	minigame_overlay.visible = true


func _on_buy(item: Dictionary) -> void:
	var success: bool = GameBackend.cook_meal(item.cost, item.energy, item.thirst, item.sanity, 0.1)
	minigame_overlay.visible = false
	task_active = false
	if success:
		_set_hint("Bought %s." % item.label.split(" — ")[0])
	else:
		_set_hint("Not enough money for that.")


func _close_menu() -> void:
	minigame_overlay.visible = false
	task_active = false


func _on_game_ended(_result: String) -> void:
	get_tree().change_scene_to_file("res://Main_Game/Scenes/EndingScene.tscn")

func _set_hint(text_value: String, hold_seconds: float = 3.5) -> void:
	hint_label.text = text_value
	hint_panel.visible = text_value != ""
	_hint_time_left = hold_seconds if text_value != "" else 0.0


func _tick_hint(delta: float) -> void:
	if _hint_time_left <= 0.0:
		return
	_hint_time_left -= delta
	if _hint_time_left <= 0.0:
		hint_label.text = ""
		hint_panel.visible = false


func _process(delta: float) -> void:
	_tick_hint(delta)
