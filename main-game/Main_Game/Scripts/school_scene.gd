## school_scene.gd
## Root script for SchoolScene.tscn — an explorable 2D school area.
## Walk up to a desk to study a subject, chat with students to de-stress
## (at the cost of a little time and a little temptation), ask the teacher
## for a high-value bonus question, or top up your water bar at the fountain.
extends Node2D

const MOVE_SPEED: float = 220.0
const QUESTIONS_PER_SESSION: int = 5
const HOURS_PER_QUESTION: float = 0.4
const ENERGY_COST_PER_QUESTION: float = 6.0
const MAX_GRADE_GAIN: float = 8.0

const TEACHER_HOURS: float = 0.5
const TEACHER_ENERGY_COST: float = 5.0
const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const TEACHER_MAX_GRADE_GAIN: float = 15.0  # bigger reward than a normal study session

@onready var player: CharacterBody2D = $Player
@onready var floor_container: Node2D = $Floor

@onready var english_area: Area2D = $EnglishDesk/InteractArea
@onready var english_prompt: Label = $EnglishDesk/PromptLabel
@onready var maths_area: Area2D = $MathsDesk/InteractArea
@onready var maths_prompt: Label = $MathsDesk/PromptLabel
@onready var physics_area: Area2D = $PhysicsDesk/InteractArea
@onready var physics_prompt: Label = $PhysicsDesk/PromptLabel

@onready var student_a_area: Area2D = $StudentA/InteractArea
@onready var student_a_prompt: Label = $StudentA/PromptLabel
@onready var student_b_area: Area2D = $StudentB/InteractArea
@onready var student_b_prompt: Label = $StudentB/PromptLabel

@onready var teacher_area: Area2D = $Teacher/InteractArea
@onready var teacher_prompt: Label = $Teacher/PromptLabel

@onready var fountain_area: Area2D = $Fountain/InteractArea
@onready var fountain_prompt: Label = $Fountain/PromptLabel

@onready var exit_area: Area2D = $ExitStation/InteractArea
@onready var exit_prompt: Label = $ExitStation/PromptLabel

@onready var hint_label: Label = $CanvasLayer/HUD/HintLabel

@onready var minigame_overlay: Control = $CanvasLayer/MinigameOverlay
@onready var title_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var progress_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/ProgressLabel
@onready var info_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var options_container: GridContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsContainer
@onready var feedback_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/FeedbackLabel
@onready var next_button: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/NextButton

@onready var results_panel: Control = $CanvasLayer/ResultsPanel
@onready var results_label: Label = $CanvasLayer/ResultsPanel/CenterContainer/Panel/VBoxContainer/ResultsLabel
@onready var close_button: Button = $CanvasLayer/ResultsPanel/CenterContainer/Panel/VBoxContainer/CloseButton

var current_station: String = ""
var task_active: bool = false
var current_task_type: String = ""  # "english" / "maths" / "physics" / "teacher" / "dialogue"
var teacher_subject: String = ""

var round_queue: Array = []
var round_index: int = 0
var round_correct: int = 0
var answered_current: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_floor()

	english_area.body_entered.connect(_on_station_entered.bind("desk_english"))
	english_area.body_exited.connect(_on_station_exited.bind("desk_english"))
	maths_area.body_entered.connect(_on_station_entered.bind("desk_maths"))
	maths_area.body_exited.connect(_on_station_exited.bind("desk_maths"))
	physics_area.body_entered.connect(_on_station_entered.bind("desk_physics"))
	physics_area.body_exited.connect(_on_station_exited.bind("desk_physics"))
	student_a_area.body_entered.connect(_on_station_entered.bind("student"))
	student_a_area.body_exited.connect(_on_station_exited.bind("student"))
	student_b_area.body_entered.connect(_on_station_entered.bind("student"))
	student_b_area.body_exited.connect(_on_station_exited.bind("student"))
	teacher_area.body_entered.connect(_on_station_entered.bind("teacher"))
	teacher_area.body_exited.connect(_on_station_exited.bind("teacher"))
	fountain_area.body_entered.connect(_on_station_entered.bind("fountain"))
	fountain_area.body_exited.connect(_on_station_exited.bind("fountain"))
	exit_area.body_entered.connect(_on_station_entered.bind("exit"))
	exit_area.body_exited.connect(_on_station_exited.bind("exit"))

	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_results)
	# Note: no Sky3D in this scene — time spent here is queued via
	# GameBackend.advance_time() (called inside complete_study_session /
	# socialize / drink_water) and applied to MainMap's clock when you return.

	GameBackend.game_ended.connect(_on_game_ended)
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())


func _build_floor() -> void:
	var floor_tex: Texture2D = load("res://Backend/Resource/Textures/floor_tile_school.png")
	for x in range(0, 1100, 64):
		for y in range(0, 620, 64):
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
	english_prompt.visible = current_station == "desk_english"
	maths_prompt.visible = current_station == "desk_maths"
	physics_prompt.visible = current_station == "desk_physics"
	student_a_prompt.visible = current_station == "student"
	student_b_prompt.visible = current_station == "student"
	teacher_prompt.visible = current_station == "teacher"
	fountain_prompt.visible = current_station == "fountain"
	exit_prompt.visible = current_station == "exit"
	if task_active:
		return
	hint_label.text = "Press E to interact" if current_station != "" else ""


func _start_task(station: String) -> void:
	match station:
		"desk_english":
			_start_subject_quiz("english")
		"desk_maths":
			_start_subject_quiz("maths")
		"desk_physics":
			_start_subject_quiz("physics")
		"teacher":
			_start_teacher_select()
		"student":
			_start_dialogue()
		"fountain":
			_use_fountain()
		"exit":
			_end_school_day()


# --- Subject study desks (same shape as the original study minigame) -------

func _start_subject_quiz(subject: String) -> void:
	current_task_type = subject
	task_active = true
	round_index = 0
	round_correct = 0
	round_queue = StudyData.get_session_questions(subject, QUESTIONS_PER_SESSION)
	title_label.text = "%s Study" % subject.capitalize()
	hint_label.text = ""
	minigame_overlay.visible = true
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
	if current_task_type == "teacher":
		_finish_teacher_question()
		return
	# Otherwise this is a normal subject quiz.
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


# --- Teacher: pick a subject, answer one higher-value bonus question -------

func _start_teacher_select() -> void:
	current_task_type = "teacher_select"
	task_active = true
	title_label.text = "Ask the Teacher"
	progress_label.text = ""
	info_label.text = SchoolData.get_teacher_intro_line() + "\nWhich subject?"
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1
	for subject in ["english", "maths", "physics"]:
		var sbtn := Button.new()
		sbtn.text = subject.capitalize()
		sbtn.pressed.connect(_start_teacher_question.bind(subject))
		options_container.add_child(sbtn)
	hint_label.text = ""
	minigame_overlay.visible = true


func _start_teacher_question(subject: String) -> void:
	teacher_subject = subject
	current_task_type = "teacher"
	round_queue = StudyData.get_session_questions(subject, 1)
	round_index = 0
	round_correct = 0
	title_label.text = "Extra Credit: %s" % subject.capitalize()
	_show_quiz_step()


func _finish_teacher_question() -> void:
	minigame_overlay.visible = false
	task_active = false
	var is_correct: bool = round_correct > 0
	GameBackend.complete_study_session(
		teacher_subject, round_correct, 1, TEACHER_HOURS, TEACHER_ENERGY_COST, TEACHER_MAX_GRADE_GAIN
	)
	hint_label.text = SchoolData.get_teacher_result_line(is_correct)


# --- Students: quick chat, relieves stress, costs a little time ------------

func _start_dialogue() -> void:
	current_task_type = "dialogue"
	task_active = true
	title_label.text = "Chat"
	progress_label.text = ""
	info_label.text = SchoolData.get_random_student_line()
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1
	var ok_btn := Button.new()
	ok_btn.text = "Have a chat (take a short break)"
	ok_btn.pressed.connect(_on_dialogue_close)
	options_container.add_child(ok_btn)
	hint_label.text = ""
	minigame_overlay.visible = true


func _on_dialogue_close() -> void:
	GameBackend.socialize()
	minigame_overlay.visible = false
	task_active = false
	hint_label.text = "Chatted for a bit — stress down a little."


# --- Fountain: instant, no overlay needed -----------------------------------

func _use_fountain() -> void:
	GameBackend.drink_water()
	hint_label.text = "You have a drink. Water topped up!"


# --- Leaving school -----------------------------------------------------------

const MAIN_MAP_SCENE: String = "res://Main_Game/Scenes/MainMap.tscn"

func _end_school_day() -> void:
	if task_active:
		return
	results_label.text = "Heading home.\nEnglish: %.0f   Maths: %.0f   Physics: %.0f\nSanity: %.0f   Thirst: %.0f" % [
		GameBackend.subject_grades.english, GameBackend.subject_grades.maths, GameBackend.subject_grades.physics,
		GameBackend.sanity, GameBackend.thirst
	]
	results_panel.visible = true


func _on_close_results() -> void:
	get_tree().change_scene_to_file(MAIN_MAP_SCENE)


func _on_game_ended(_result: String) -> void:
	get_tree().change_scene_to_file("res://Main_Game/Scenes/EndingScene.tscn")
