## home_scene.gd
## Root script for HomeScene.tscn — a 2D home base. Bed to sleep, desk to
## study, stove to cook, couch to watch TV, plus where you pick up the Phone
## and Water Bottle for the first time.
extends Node2D

const MOVE_SPEED: float = 220.0
const QUESTIONS_PER_SESSION: int = 5
const HOURS_PER_QUESTION: float = 0.15
const ENERGY_COST_PER_QUESTION: float = 6.0
const MAX_GRADE_GAIN: float = 8.0
const MAIN_MAP_SCENE: String = "res://Main_Game/Scenes/MainMap.tscn"

const PHONE_ITEM := preload("res://Backend/Resource/Items/Phone.tres")
const WATER_BOTTLE_ITEM := preload("res://Backend/Resource/Items/WaterBottle.tres")

const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const GUI_SCENE := preload("res://Characters/GUI/GUI_Scenes/gui.tscn")

const PLAY_AREA_MIN := Vector2(0, 0)
const PLAY_AREA_MAX := Vector2(1050, 650)

@onready var player: CharacterBody2D = $Player
@onready var floor_container: Node2D = $Floor

@onready var bed_area: Area2D = $BedStation/InteractArea
@onready var bed_prompt: Label = $BedStation/PromptLabel
@onready var desk_area: Area2D = $DeskStation/InteractArea
@onready var desk_prompt: Label = $DeskStation/PromptLabel
@onready var stove_area: Area2D = $StoveStation/InteractArea
@onready var stove_prompt: Label = $StoveStation/PromptLabel
@onready var couch_area: Area2D = $CouchStation/InteractArea
@onready var couch_prompt: Label = $CouchStation/PromptLabel

@onready var phone_spot: Node2D = $PhoneSpot
@onready var phone_area: Area2D = $PhoneSpot/InteractArea
@onready var phone_prompt: Label = $PhoneSpot/PromptLabel
@onready var bottle_spot: Node2D = $BottleSpot
@onready var bottle_area: Area2D = $BottleSpot/InteractArea
@onready var bottle_prompt: Label = $BottleSpot/PromptLabel

@onready var dairy_area: Area2D = $DairyStation/InteractArea
@onready var dairy_prompt: Label = $DairyStation/PromptLabel

@onready var exit_area: Area2D = $ExitStation/InteractArea
@onready var exit_prompt: Label = $ExitStation/PromptLabel

@onready var hint_label: Label = $CanvasLayer/HUD/HintLabel

@onready var minigame_overlay: Control = $CanvasLayer/MinigameOverlay
@onready var title_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var progress_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/ProgressLabel
@onready var info_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var options_container: GridContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/OptionsContainer
@onready var feedback_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/FeedbackLabel
@onready var next_button: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/NextButton

var current_station: String = ""
var task_active: bool = false
var current_task_type: String = ""

var round_queue: Array = []
var round_index: int = 0
var round_correct: int = 0
var answered_current: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_floor()

	bed_area.body_entered.connect(_on_station_entered.bind("bed"))
	bed_area.body_exited.connect(_on_station_exited.bind("bed"))
	desk_area.body_entered.connect(_on_station_entered.bind("desk"))
	desk_area.body_exited.connect(_on_station_exited.bind("desk"))
	stove_area.body_entered.connect(_on_station_entered.bind("stove"))
	stove_area.body_exited.connect(_on_station_exited.bind("stove"))
	couch_area.body_entered.connect(_on_station_entered.bind("couch"))
	couch_area.body_exited.connect(_on_station_exited.bind("couch"))
	phone_area.body_entered.connect(_on_station_entered.bind("phone"))
	phone_area.body_exited.connect(_on_station_exited.bind("phone"))
	bottle_area.body_entered.connect(_on_station_entered.bind("bottle"))
	bottle_area.body_exited.connect(_on_station_exited.bind("bottle"))
	dairy_area.body_entered.connect(_on_station_entered.bind("dairy"))
	dairy_area.body_exited.connect(_on_station_exited.bind("dairy"))
	exit_area.body_entered.connect(_on_station_entered.bind("exit"))
	exit_area.body_exited.connect(_on_station_exited.bind("exit"))

	next_button.pressed.connect(_on_next_pressed)

	# Hide pickups you've already collected on an earlier visit.
	if _has_item("Phone"):
		phone_spot.visible = false
		phone_area.set_deferred("monitoring", false)
	if _has_item("Water Bottle"):
		bottle_spot.visible = false
		bottle_area.set_deferred("monitoring", false)

	GameBackend.game_ended.connect(_on_game_ended)
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())
	get_tree().current_scene.add_child(GUI_SCENE.instantiate())


func _has_item(item_name: String) -> bool:
	for item in Inventory.hotbar:
		if item != null and item.item_name == item_name:
			return true
	return false


func _build_floor() -> void:
	var floor_tex: Texture2D = load("res://Backend/Resource/Textures/floor_tile.png")
	for x in range(-400, 1500, 64):
		for y in range(-400, 1100, 64):
			var tile := Sprite2D.new()
			tile.texture = floor_tex
			tile.centered = false
			tile.position = Vector2(x, y)
			tile.z_index = -1
			floor_container.add_child(tile)


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
		_start_task(current_station)


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
	bed_prompt.visible = current_station == "bed"
	desk_prompt.visible = current_station == "desk"
	stove_prompt.visible = current_station == "stove"
	couch_prompt.visible = current_station == "couch"
	phone_prompt.visible = current_station == "phone" and phone_spot.visible
	bottle_prompt.visible = current_station == "bottle" and bottle_spot.visible
	dairy_prompt.visible = current_station == "dairy"
	exit_prompt.visible = current_station == "exit"
	if task_active:
		return
	hint_label.text = "Press E to interact" if current_station != "" else ""


func _start_task(station: String) -> void:
	match station:
		"bed":
			_start_bed()
		"desk":
			_start_desk_select()
		"stove":
			_start_stove()
		"couch":
			_start_couch()
		"phone":
			_pickup_item("phone")
		"bottle":
			_pickup_item("bottle")
		"dairy":
			_start_dairy()
		"exit":
			get_tree().change_scene_to_file(MAIN_MAP_SCENE)


# --- Pickups -----------------------------------------------------------------

func _pickup_item(kind: String) -> void:
	var item: ItemData = PHONE_ITEM if kind == "phone" else WATER_BOTTLE_ITEM
	if Inventory.add_item(item):
		if kind == "phone":
			phone_spot.visible = false
			phone_area.set_deferred("monitoring", false)
			hint_label.text = "Picked up your phone."
		else:
			bottle_spot.visible = false
			bottle_area.set_deferred("monitoring", false)
			hint_label.text = "Picked up your water bottle."
		current_station = ""
	else:
		hint_label.text = "Your hotbar is full — drop something first."


# --- Bed: sleep, big energy/sanity restore, costs a big chunk of time ------

func _start_bed() -> void:
	current_task_type = "bed"
	task_active = true
	title_label.text = "Bed"
	progress_label.text = ""
	info_label.text = "Get a proper night's sleep? Fully restores energy and helps you unwind — but it's a big chunk of your day (or night)."
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1
	var sleep_btn := Button.new()
	sleep_btn.text = "Sleep (8 hours)"
	sleep_btn.pressed.connect(_on_sleep_pressed)
	options_container.add_child(sleep_btn)
	hint_label.text = ""
	minigame_overlay.visible = true


func _on_sleep_pressed() -> void:
	GameBackend.sleep(8.0)
	minigame_overlay.visible = false
	task_active = false
	hint_label.text = "You wake up feeling much better."


# --- Desk: pick a subject, study (same shape as the school desks) ----------

func _start_desk_select() -> void:
	current_task_type = "desk_select"
	task_active = true
	title_label.text = "Study at Home"
	progress_label.text = ""
	info_label.text = "Which subject?"
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1
	var subjects: Array = GameBackend.active_subjects if GameBackend.active_subjects.size() >= 3 else ["english", "maths", "physics"]
	for subject in subjects:
		var sbtn := Button.new()
		sbtn.text = subject.capitalize()
		sbtn.pressed.connect(_start_subject_quiz.bind(subject))
		options_container.add_child(sbtn)
	hint_label.text = ""
	minigame_overlay.visible = true


func _start_subject_quiz(subject: String) -> void:
	current_task_type = subject
	round_index = 0
	round_correct = 0
	round_queue = StudyData.get_session_questions(subject, QUESTIONS_PER_SESSION)
	title_label.text = "%s Study" % subject.capitalize()
	_show_quiz_step()


func _show_quiz_step() -> void:
	feedback_label.text = ""
	next_button.visible = false
	answered_current = false
	for child in options_container.get_children():
		child.queue_free()

	var q: Dictionary = round_queue[round_index]
	progress_label.text = "Question %d / %d" % [round_index + 1, round_queue.size()]
	info_label.text = q.question
	options_container.columns = 1
	var opts: Array = q.options
	for i in opts.size():
		var btn := Button.new()
		btn.text = opts[i]
		btn.pressed.connect(_on_quiz_choice.bind(i == q.correct))
		options_container.add_child(btn)


func _on_quiz_choice(is_correct: bool) -> void:
	if answered_current:
		return
	answered_current = true
	if is_correct:
		round_correct += 1
		feedback_label.text = "Correct!"
	else:
		var q: Dictionary = round_queue[round_index]
		feedback_label.text = "Not quite — the answer was: %s" % q.options[q.correct]
	for child in options_container.get_children():
		if child is BaseButton:
			child.disabled = true
	next_button.visible = true


func _on_next_pressed() -> void:
	round_index += 1
	if round_index >= round_queue.size():
		_finish_subject_quiz()
	else:
		_show_quiz_step()


func _finish_subject_quiz() -> void:
	minigame_overlay.visible = false
	task_active = false
	var hours: float = HOURS_PER_QUESTION * round_queue.size()
	GameBackend.complete_study_session(
		current_task_type, round_correct, round_queue.size(), hours, ENERGY_COST_PER_QUESTION, MAX_GRADE_GAIN
	)
	hint_label.text = "%s: %d / %d correct" % [current_task_type.capitalize(), round_correct, round_queue.size()]


# --- Stove: cook a meal, costs money, restores energy/thirst/sanity --------

func _start_stove() -> void:
	current_task_type = "stove"
	task_active = true
	title_label.text = "Kitchen"
	progress_label.text = ""
	info_label.text = "What do you want to make?"
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1

	var meals := [
		{"label": "Quick Snack — $3", "cost": 3.0, "energy": 8.0, "thirst": 5.0, "sanity": 2.0},
		{"label": "Proper Meal — $10", "cost": 10.0, "energy": 25.0, "thirst": 15.0, "sanity": 6.0},
		{"label": "Big Feed — $22", "cost": 22.0, "energy": 45.0, "thirst": 25.0, "sanity": 12.0},
	]
	for meal in meals:
		var mbtn := Button.new()
		mbtn.text = meal.label
		mbtn.pressed.connect(_on_cook_pressed.bind(meal))
		options_container.add_child(mbtn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Never mind"
	cancel_btn.pressed.connect(_close_overlay)
	options_container.add_child(cancel_btn)

	hint_label.text = ""
	minigame_overlay.visible = true


func _on_cook_pressed(meal: Dictionary) -> void:
	var success: bool = GameBackend.cook_meal(meal.cost, meal.energy, meal.thirst, meal.sanity)
	minigame_overlay.visible = false
	task_active = false
	if success:
		hint_label.text = "Made yourself %s." % meal.label.split(" — ")[0]
	else:
		hint_label.text = "Not enough money for that."


# --- Couch: watch TV, a bigger single sitting than doomscrolling -----------

func _start_couch() -> void:
	current_task_type = "couch"
	task_active = true
	title_label.text = "Couch"
	progress_label.text = ""
	info_label.text = "Something's on. Might as well sit down for a bit."
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1
	var watch_btn := Button.new()
	watch_btn.text = "Watch TV"
	watch_btn.pressed.connect(_on_watch_tv_pressed)
	options_container.add_child(watch_btn)
	hint_label.text = ""
	minigame_overlay.visible = true


func _on_watch_tv_pressed() -> void:
	GameBackend.watch_tv()
	minigame_overlay.visible = false
	task_active = false
	hint_label.text = "That was a decent watch. Feeling a bit more relaxed."


func _close_overlay() -> void:
	minigame_overlay.visible = false
	task_active = false


# --- Dairy: small corner shop, only open after school (or early morning) --

func _is_dairy_open() -> bool:
	var hour: int = GameBackend.current_hour
	return hour >= 15 or hour < 7


func _start_dairy() -> void:
	if not _is_dairy_open():
		hint_label.text = "The dairy's closed right now — try after 3pm."
		return

	current_task_type = "dairy"
	task_active = true
	title_label.text = "The Dairy"
	progress_label.text = ""
	info_label.text = "What are you after?"
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1

	var items := [
		{"label": "Chips — $3", "cost": 3.0, "energy": 5.0, "thirst": 2.0, "sanity": 5.0},
		{"label": "Energy Drink — $5", "cost": 5.0, "energy": 20.0, "thirst": 10.0, "sanity": -2.0},
		{"label": "Ice Cream — $4", "cost": 4.0, "energy": 8.0, "thirst": 5.0, "sanity": 8.0},
	]
	for item in items:
		var ibtn := Button.new()
		ibtn.text = item.label
		ibtn.pressed.connect(_on_dairy_buy.bind(item))
		options_container.add_child(ibtn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Never mind"
	cancel_btn.pressed.connect(_close_overlay)
	options_container.add_child(cancel_btn)

	hint_label.text = ""
	minigame_overlay.visible = true


func _on_dairy_buy(item: Dictionary) -> void:
	var success: bool = GameBackend.cook_meal(item.cost, item.energy, item.thirst, item.sanity, 0.1)
	minigame_overlay.visible = false
	task_active = false
	if success:
		hint_label.text = "Bought %s." % item.label.split(" — ")[0]
	else:
		hint_label.text = "Not enough money for that."


func _on_game_ended(_result: String) -> void:
	get_tree().change_scene_to_file("res://Main_Game/Scenes/EndingScene.tscn")
