## school_scene.gd
## Root script for SchoolScene.tscn — an explorable 2D school area.
## Walk up to a desk to study a subject, chat with students to de-stress
## (at the cost of a little time and a little temptation), ask the teacher
## for a high-value bonus question, or top up your water bar at the fountain.
extends Node2D

const MOVE_SPEED: float = 220.0
const QUESTIONS_PER_SESSION: int = 5
const HOURS_PER_QUESTION: float = 0.15
const ENERGY_COST_PER_QUESTION: float = 6.0
const MAX_GRADE_GAIN: float = 8.0

const TEACHER_HOURS: float = 0.2
const TEACHER_ENERGY_COST: float = 5.0
const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const GUI_SCENE := preload("res://Characters/GUI/GUI_Scenes/gui.tscn")
const TEACHER_MAX_GRADE_GAIN: float = 15.0  # bigger reward than a normal study session

@onready var player: CharacterBody2D = $Player
@onready var floor_container: Node2D = $Floor

@onready var english_area: Area2D = $EnglishDesk/InteractArea
@onready var english_prompt: Label = $EnglishDesk/PromptLabel
@onready var english_sprite: Sprite2D = $EnglishDesk/Sprite2D
@onready var maths_area: Area2D = $MathsDesk/InteractArea
@onready var maths_prompt: Label = $MathsDesk/PromptLabel
@onready var maths_sprite: Sprite2D = $MathsDesk/Sprite2D
@onready var physics_area: Area2D = $PhysicsDesk/InteractArea
@onready var physics_prompt: Label = $PhysicsDesk/PromptLabel
@onready var physics_sprite: Sprite2D = $PhysicsDesk/Sprite2D

@onready var student_a_area: Area2D = $StudentA/InteractArea
@onready var student_a_prompt: Label = $StudentA/PromptLabel
@onready var student_b_area: Area2D = $StudentB/InteractArea
@onready var student_b_prompt: Label = $StudentB/PromptLabel

@onready var teacher_area: Area2D = $Teacher/InteractArea
@onready var teacher_prompt: Label = $Teacher/PromptLabel

@onready var fountain_area: Area2D = $Fountain/InteractArea
@onready var fountain_prompt: Label = $Fountain/PromptLabel

@onready var canteen_area: Area2D = $Canteen/InteractArea
@onready var canteen_prompt: Label = $Canteen/PromptLabel

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

@onready var results_panel: Control = $CanvasLayer/ResultsPanel
@onready var results_label: Label = $CanvasLayer/ResultsPanel/CenterContainer/Panel/VBoxContainer/ResultsLabel
@onready var close_button: Button = $CanvasLayer/ResultsPanel/CenterContainer/Panel/VBoxContainer/CloseButton

var current_station: String = ""
var task_active: bool = false
var current_task_type: String = ""  # subject key, or "teacher" / "dialogue" / etc.
var teacher_subject: String = ""

var round_queue: Array = []
var round_index: int = 0
var round_correct: int = 0
var answered_current: bool = false

# Maps a desk's station id ("desk_english" etc — these are just internal
# identifiers now, not necessarily what subject that desk teaches) to the
# actual subject assigned to it based on GameBackend.active_subjects.
var desk_subjects: Dictionary = {}


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_floor()
	_assign_desk_subjects()

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
	canteen_area.body_entered.connect(_on_station_entered.bind("canteen"))
	canteen_area.body_exited.connect(_on_station_exited.bind("canteen"))
	exit_area.body_entered.connect(_on_station_entered.bind("exit"))
	exit_area.body_exited.connect(_on_station_exited.bind("exit"))

	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_results)
	# Note: no Sky3D in this scene — time spent here is queued via
	# GameBackend.advance_time() (called inside complete_study_session /
	# socialize / drink_water) and applied to MainMap's clock when you return.

	GameBackend.game_ended.connect(_on_game_ended)
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())
	get_tree().current_scene.add_child(GUI_SCENE.instantiate())


## Assigns each of the 3 desks a subject from GameBackend.active_subjects
## (set by the major you picked at university-select), swapping the desk's
## texture and prompt to match. Falls back to English/Maths/Physics if no
## major has been chosen yet (e.g. testing this scene standalone).
func _assign_desk_subjects() -> void:
	var subjects: Array = GameBackend.active_subjects
	if subjects.size() < 3:
		subjects = ["english", "maths", "physics"]

	var station_ids := ["desk_english", "desk_maths", "desk_physics"]
	var sprites := [english_sprite, maths_sprite, physics_sprite]
	var prompts := [english_prompt, maths_prompt, physics_prompt]

	desk_subjects.clear()
	for i in station_ids.size():
		var subject: String = subjects[i]
		desk_subjects[station_ids[i]] = subject
		sprites[i].texture = load("res://Backend/Resource/Textures/desk_%s.png" % subject)
		prompts[i].text = "Press E to study %s" % subject.capitalize()


const PLAY_AREA_MIN := Vector2(0, 0)
const PLAY_AREA_MAX := Vector2(1050, 650)


func _build_floor() -> void:
	var floor_tex: Texture2D = load("res://Backend/Resource/Textures/floor_tile_school.png")
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
	english_prompt.visible = current_station == "desk_english"
	maths_prompt.visible = current_station == "desk_maths"
	physics_prompt.visible = current_station == "desk_physics"
	student_a_prompt.visible = current_station == "student"
	student_b_prompt.visible = current_station == "student"
	teacher_prompt.visible = current_station == "teacher"
	fountain_prompt.visible = current_station == "fountain"
	canteen_prompt.visible = current_station == "canteen"
	exit_prompt.visible = current_station == "exit"
	if task_active:
		return
	hint_label.text = "Press E to interact" if current_station != "" else ""


func _start_task(station: String) -> void:
	if desk_subjects.has(station):
		_start_subject_quiz(desk_subjects[station])
		return
	match station:
		"teacher":
			_start_teacher_menu()
		"student":
			_start_conversation(SchoolData.get_random_student_conversation())
		"fountain":
			_use_fountain()
		"canteen":
			_start_canteen()
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


# --- Teacher: chat, or pick a subject and answer one higher-value bonus question

func _start_teacher_menu() -> void:
	current_task_type = "teacher_menu"
	task_active = true
	title_label.text = "The Teacher"
	progress_label.text = ""
	info_label.text = "\"Something I can help with?\""
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1
	var chat_btn := Button.new()
	chat_btn.text = "Have a chat"
	chat_btn.pressed.connect(_start_teacher_chat)
	options_container.add_child(chat_btn)
	var credit_btn := Button.new()
	credit_btn.text = "Ask for extra credit"
	credit_btn.pressed.connect(_start_teacher_select)
	options_container.add_child(credit_btn)
	hint_label.text = ""
	minigame_overlay.visible = true


func _start_teacher_chat() -> void:
	_start_conversation(SchoolData.get_random_teacher_conversation())


func _start_teacher_select() -> void:
	current_task_type = "teacher_select"
	title_label.text = "Ask the Teacher"
	progress_label.text = ""
	info_label.text = SchoolData.get_teacher_intro_line() + "\nWhich subject?"
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1
	var subjects: Array = GameBackend.active_subjects if GameBackend.active_subjects.size() >= 3 else ["english", "maths", "physics"]
	for subject in subjects:
		var sbtn := Button.new()
		sbtn.text = subject.capitalize()
		sbtn.pressed.connect(_start_teacher_question.bind(subject))
		options_container.add_child(sbtn)


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


# --- Conversations: multi-line, stepped through with Continue, then resolves
# with a chat (relieves stress, costs a little time). Used by both students
# and the teacher's "Have a chat" option.

var dialogue_lines: Array = []
var dialogue_index: int = 0


func _start_conversation(lines: Array) -> void:
	current_task_type = "dialogue"
	task_active = true
	title_label.text = "Chat"
	dialogue_lines = lines
	dialogue_index = 0
	feedback_label.text = ""
	next_button.visible = false
	hint_label.text = ""
	minigame_overlay.visible = true
	_show_dialogue_line()


func _show_dialogue_line() -> void:
	info_label.text = dialogue_lines[dialogue_index]
	progress_label.text = "%d / %d" % [dialogue_index + 1, dialogue_lines.size()]
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1
	if dialogue_index < dialogue_lines.size() - 1:
		var continue_btn := Button.new()
		continue_btn.text = "Continue"
		continue_btn.pressed.connect(_on_dialogue_next)
		options_container.add_child(continue_btn)
	else:
		var end_btn := Button.new()
		end_btn.text = "Wrap up the chat"
		end_btn.pressed.connect(_on_dialogue_close)
		options_container.add_child(end_btn)


func _on_dialogue_next() -> void:
	dialogue_index += 1
	_show_dialogue_line()


func _on_dialogue_close() -> void:
	GameBackend.socialize()
	minigame_overlay.visible = false
	task_active = false
	hint_label.text = "Chatted for a bit — stress down a little."


# --- Fountain: instant, no overlay needed -----------------------------------

func _use_fountain() -> void:
	GameBackend.drink_water()
	if _has_water_bottle() and not GameBackend.water_bottle_full:
		GameBackend.refill_water_bottle()
		hint_label.text = "You have a drink and refill your water bottle."
	else:
		hint_label.text = "You have a drink. Water topped up!"


# --- Canteen: buy food during the school day --------------------------------

func _start_canteen() -> void:
	current_task_type = "canteen"
	task_active = true
	title_label.text = "Canteen"
	progress_label.text = ""
	info_label.text = "What'll you get?"
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1

	var items := [
		{"label": "Meat Pie — $4", "cost": 4.0, "energy": 10.0, "thirst": 5.0, "sanity": 3.0},
		{"label": "Sandwich — $6", "cost": 6.0, "energy": 15.0, "thirst": 8.0, "sanity": 4.0},
		{"label": "Hot Meal — $9", "cost": 9.0, "energy": 22.0, "thirst": 10.0, "sanity": 6.0},
	]
	for item in items:
		var ibtn := Button.new()
		ibtn.text = item.label
		ibtn.pressed.connect(_on_canteen_buy.bind(item))
		options_container.add_child(ibtn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Never mind"
	cancel_btn.pressed.connect(_close_canteen)
	options_container.add_child(cancel_btn)

	hint_label.text = ""
	minigame_overlay.visible = true


func _on_canteen_buy(item: Dictionary) -> void:
	var success: bool = GameBackend.cook_meal(item.cost, item.energy, item.thirst, item.sanity, 0.1)
	minigame_overlay.visible = false
	task_active = false
	if success:
		hint_label.text = "Bought %s." % item.label.split(" — ")[0]
	else:
		hint_label.text = "Not enough money for that."


func _close_canteen() -> void:
	minigame_overlay.visible = false
	task_active = false


func _has_water_bottle() -> bool:
	for item in Inventory.hotbar:
		if item != null and item.item_name == "Water Bottle":
			return true
	return false


# --- Leaving school -----------------------------------------------------------

const MAIN_MAP_SCENE: String = "res://Main_Game/Scenes/MainMap.tscn"

func _end_school_day() -> void:
	if task_active:
		return
	results_label.text = "Heading home.\n%s\nSanity: %.0f   Thirst: %.0f" % [
		GameBackend.get_subject_grades_text(), GameBackend.sanity, GameBackend.thirst
	]
	results_panel.visible = true


func _on_close_results() -> void:
	get_tree().change_scene_to_file(MAIN_MAP_SCENE)


func _on_game_ended(_result: String) -> void:
	get_tree().change_scene_to_file("res://Main_Game/Scenes/EndingScene.tscn")
