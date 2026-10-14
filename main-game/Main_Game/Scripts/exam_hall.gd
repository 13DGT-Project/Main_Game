extends Node2D

const MOVE_SPEED: float = 200.0
const MAIN_MAP_SCENE: String = "res://Main_Game/Scenes/MainMap.tscn"

const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const GUI_SCENE := preload("res://Characters/GUI/GUI_Scenes/gui.tscn")

const PLAY_AREA_MIN := Vector2(60, 60)
const PLAY_AREA_MAX := Vector2(940, 700)

@onready var player: CharacterBody2D = $Player
@onready var floor_layer: TileMapLayer = $Floor
@onready var walls_layer: TileMapLayer = $Walls

@onready var desk_area: Area2D = $ExamDesk/InteractArea
@onready var desk_prompt: Label = $ExamDesk/PromptLabel
@onready var supervisor_area: Area2D = $Supervisor/InteractArea
@onready var supervisor_prompt: Label = $Supervisor/PromptLabel

@onready var hint_panel: PanelContainer = $CanvasLayer/HUD/HintPanel
@onready var hint_label: Label = $CanvasLayer/HUD/HintPanel/HintLabel

@onready var minigame_overlay: Control = $CanvasLayer/MinigameOverlay
@onready var title_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var progress_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/ProgressLabel
@onready var info_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var options_container: VBoxContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/OptionsContainer
@onready var feedback_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/FeedbackLabel
@onready var next_button: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/NextButton

@onready var exit_area: Area2D = $ExitStation/InteractArea
@onready var exit_prompt: Label = $ExitStation/PromptLabel



var current_station: String = ""
var task_active: bool = false
var _hint_time_left: float = 0.0

var round_queue: Array = []
var round_index: int = 0
var round_correct: int = 0
var answered_current: bool = false
var current_subject: String = ""


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Audio.play_ambience("school")
	GameBackend.remember_place("exam_hall")

	desk_area.body_entered.connect(_on_station_entered.bind("desk"))
	desk_area.body_exited.connect(_on_station_exited.bind("desk"))
	supervisor_area.body_entered.connect(_on_station_entered.bind("supervisor"))
	supervisor_area.body_exited.connect(_on_station_exited.bind("supervisor"))
	exit_area.body_entered.connect(_on_station_entered.bind("exit"))
	exit_area.body_exited.connect(_on_station_exited.bind("exit"))
	
	next_button.pressed.connect(_on_next_pressed)

	GameBackend.game_ended.connect(_on_game_ended)
	get_tree().current_scene.add_child.call_deferred(JOURNAL_SCENE.instantiate())
	get_tree().current_scene.add_child.call_deferred(GUI_SCENE.instantiate())

	# EXTERNALS ONLY. Internals are sat in class at school; the exam hall used
	# to accept both...
	var today_exams: Array = GameBackend.exams_due_today_of_kind("external")
	if today_exams.is_empty():
		var days: int = GameBackend.days_until_next_exam()
		if days > 0:
			_set_hint(tr("EXAM_NONE_TODAY"), 0.0)
		else:
			_set_hint(tr("EXAM_ALL_DONE_HALL"), 0.0)
	elif today_exams.size() >= 2:
		_set_hint(tr("EXAM_N_TODAY") % today_exams.size(), 0.0)
	else:
		_set_hint(tr("EXAM_ONE_TODAY") % GameBackend.subject_name(str(today_exams[0].subject)), 0.0)


func _physics_process(_delta: float) -> void:
	if task_active:
		player.velocity = Vector2.ZERO
		return
	var input_vec := Input.get_vector("left", "right", "up", "down")
	player.velocity = input_vec * MOVE_SPEED
	player.move_and_slide()
	player.global_position = player.global_position.clamp(PLAY_AREA_MIN, PLAY_AREA_MAX)


func _process(delta: float) -> void:
	_tick_hint(delta)


func _unhandled_input(event: InputEvent) -> void:
	if task_active:
		return
	if event.is_action_pressed("interact") and current_station != "":
		match current_station:
			"desk":
				_start_external()
			"supervisor":
				_talk_to_supervisor()
			"exit":
				get_tree().change_scene_to_file(MAIN_MAP_SCENE)
	elif event.is_action_pressed("use_item"):
		# Phones in an exam room are an instant fail in real life.
		var item: ItemData = Inventory.hotbar[Inventory.selected_slot]
		if item != null and item.item_name == "Phone":
			_set_hint(tr("EXAM_NO_PHONES"))
		elif item != null and item.item_name == "Water Bottle":
			if GameBackend.use_water_bottle():
				Audio.play("drink")
			else:
				Audio.play("error")
				_set_hint(tr("ITEM_BOTTLE_EMPTY_SHORT"))


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
	desk_prompt.visible = current_station == "desk"
	supervisor_prompt.visible = current_station == "supervisor"
	exit_prompt.visible = current_station == "exit"

## The next external still to be sat, whatever day it's scheduled for
## Only exams timetabled for TODAY can be sat
func _next_external() -> Dictionary:
	var today: int = GameBackend.get_elapsed_days()
	for exam in GameBackend.exam_schedule:
		if exam.get("kind", "") == "external" and not exam.taken and exam.day == today:
			return exam
	return {}


func _start_external() -> void:
	var due: Dictionary = _next_external()
	if due.is_empty():
		_set_hint(tr("EXAM_ALL_SAT"))
		return

	current_subject = due.subject
	task_active = true
	round_index = 0
	round_correct = 0
	round_queue = StudyData.get_session_questions(current_subject, GameBackend.EXAM_QUESTION_COUNT)
	title_label.text = tr("EXAM_TITLE") % GameBackend.subject_name(str(current_subject))
	Audio.play("exam_start")
	minigame_overlay.visible = true
	_show_question()


func _show_question() -> void:
	feedback_label.text = ""
	next_button.visible = false
	answered_current = false
	for child in options_container.get_children():
		child.queue_free()

	var q: Dictionary = round_queue[round_index]
	progress_label.text = tr("EXAM_QUESTION_N") % [round_index + 1, round_queue.size()]
	info_label.text = q.question
	# Preparedness strikes out wrong answers, one per 30% revision, capped at
	# three and never leaving fewer than two options. Revision doesn't add
	# marks to a paper you haven't sat — it makes the paper you DO sit easier.
	var struck: Dictionary = {}
	var hints: int = GameBackend.hints_for(current_subject)
	if hints > 0:
		var wrong: Array = []
		for i in q.options.size():
			if i != int(q.correct):
				wrong.append(i)
		wrong.shuffle()
		for n in mini(hints, maxi(0, wrong.size() - 1)):
			struck[wrong[n]] = true
		if not struck.is_empty():
			progress_label.text += tr("QUIZ_STRUCK_OUT") % struck.size()

	for i in q.options.size():
		var btn := Button.new()
		btn.text = q.options[i]
		btn.custom_minimum_size = Vector2(520, 50)
		btn.add_theme_font_size_override("font_size", 17)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if struck.has(i):
			btn.disabled = true
			btn.text = tr("QUIZ_RULED_OUT") % q.options[i]
			btn.modulate = Color(0.55, 0.55, 0.58)
		else:
			btn.pressed.connect(_on_answer.bind(i == q.correct))
		options_container.add_child(btn)


## No right/wrong feedback
func _on_answer(is_correct: bool) -> void:
	if answered_current:
		return
	answered_current = true
	if is_correct:
		round_correct += 1
	for child in options_container.get_children():
		if child is BaseButton:
			child.disabled = true
	feedback_label.text = tr("EXAM_ANSWER_RECORDED")
	next_button.visible = true


func _on_next_pressed() -> void:
	round_index += 1
	if round_index >= round_queue.size():
		_finish_external()
	else:
		_show_question()


func _finish_external() -> void:
	minigame_overlay.visible = false
	task_active = false
	GameBackend.complete_exam(current_subject, round_correct, round_queue.size())
	var still_due: Array = GameBackend.exams_due_today_of_kind("external")
	if still_due.is_empty():
		_set_hint(tr("EXAM_HANDED_IN"), 6.0)
	else:
		_set_hint(tr("EXAM_HANDED_IN_MORE") % GameBackend.subject_name(str(still_due[0].subject)), 6.0)


## The supervisor handles derived grades — your one fallback if you can't sit
## a paper.
func _talk_to_supervisor() -> void:
	task_active = true
	title_label.text = tr("EXAM_SUPERVISOR")
	progress_label.text = ""
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()

	var remaining: Array = []
	for exam in GameBackend.exam_schedule:
		if exam.get("kind", "") == "external" and not exam.taken:
			remaining.append(exam.subject)

	info_label.text = tr("EXAM_SUPERVISOR_ONE" if GameBackend.derived_grades_left == 1 else "EXAM_SUPERVISOR_MANY") % GameBackend.derived_grades_left

	if GameBackend.derived_grades_left > 0:
		for subject in remaining:
			var btn := Button.new()
			btn.text = tr("EXAM_APPLY_DERIVED") % GameBackend.subject_name(str(subject))
			btn.custom_minimum_size = Vector2(520, 48)
			btn.pressed.connect(_apply_derived.bind(subject))
			options_container.add_child(btn)

	var leave := Button.new()
	leave.text = tr("SHOP_NEVER_MIND")
	leave.custom_minimum_size = Vector2(520, 44)
	leave.pressed.connect(_close_overlay)
	options_container.add_child(leave)
	minigame_overlay.visible = true


func _apply_derived(subject: String) -> void:
	if GameBackend.use_derived_grade(subject):
		_set_hint(tr("EXAM_DERIVED_APPLIED") % GameBackend.subject_name(str(subject)), 5.0)
	else:
		_set_hint(tr("EXAM_DERIVED_NONE"))
	_close_overlay()


func _close_overlay() -> void:
	minigame_overlay.visible = false
	task_active = false


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


func _on_game_ended(_result: String) -> void:
	get_tree().change_scene_to_file("res://Main_Game/Scenes/EndingScene.tscn")
