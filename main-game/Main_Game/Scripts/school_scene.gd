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
## How much readiness a full sit-down desk session is worth. Studying no
## longer moves grades — it moves preparedness. See GameBackend.subject_prep.
const DESK_STUDY_DEPTH: float = 16.0

const TEACHER_HOURS: float = 0.2
const TEACHER_ENERGY_COST: float = 5.0
const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const GUI_SCENE := preload("res://Characters/GUI/GUI_Scenes/gui.tscn")
const MINIMAP_SCRIPT := preload("res://Main_Game/Scripts/minimap.gd")
const TEACHER_MAX_GRADE_GAIN: float = 15.0  # bigger reward than a normal study session

@onready var player: CharacterBody2D = $Player
@onready var floor_layer: TileMapLayer = $Floor
@onready var walls_layer: TileMapLayer = $Walls

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


@onready var exit_area: Area2D = $ExitStation/InteractArea
@onready var exit_prompt: Label = $ExitStation/PromptLabel

@onready var hint_panel: PanelContainer = $CanvasLayer/HUD/HintPanel
@onready var hint_label: Label = $CanvasLayer/HUD/HintPanel/HintLabel

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
var _hint_time_left: float = 0.0
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
	Audio.play_ambience("school")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
	_setup_minimap()


## The school is one open room rather than separate departments, so the map
## mostly serves to show where you are relative to the desks and the exit.
func _setup_minimap() -> void:
	var minimap := CanvasLayer.new()
	minimap.set_script(MINIMAP_SCRIPT)
	get_tree().current_scene.add_child(minimap)
	minimap.setup([
		{"name": "Classroom", "rect": Rect2(0, 100, 1050, 300)},
		{"name": "Common Area", "rect": Rect2(0, 400, 1050, 250)},
	], Rect2(0, 0, 1050, 650), player)


## Assigns each of the 3 desks a subject from GameBackend.active_subjects
## (set by the major you picked at university-select), swapping the desk's
## texture and prompt to match. Falls back to English/Maths/Physics if no
## major has been chosen yet (e.g. testing this scene standalone).
func _assign_desk_subjects() -> void:
	var subjects: Array = GameBackend.active_subjects
	if subjects.is_empty():
		subjects = ["english", "maths", "physics"]

	# Three physical desks but up to five subjects, so each desk simply opens
	# a subject picker. The desk art still shows one subject each purely as
	# visual flavour.
	var station_ids := ["desk_english", "desk_maths", "desk_physics"]
	var sprites := [english_sprite, maths_sprite, physics_sprite]
	var prompts := [english_prompt, maths_prompt, physics_prompt]

	desk_subjects.clear()
	var due: Dictionary = GameBackend.get_internal_due_today()
	for i in station_ids.size():
		desk_subjects[station_ids[i]] = ""   # "" => open the picker
		var flavour: String = subjects[i % subjects.size()]
		var tex_path: String = "res://Backend/Resource/Textures/desk_%s.png" % flavour
		if ResourceLoader.exists(tex_path):
			sprites[i].texture = load(tex_path)
		if not due.is_empty():
			prompts[i].text = "Press E — %s INTERNAL today!" % str(due.subject).capitalize()
		else:
			prompts[i].text = "Press E to study"


## Lists every subject you're taking, so all five are reachable from any desk.
func _start_desk_picker() -> void:
	current_task_type = "desk_select"
	task_active = true
	title_label.text = "Study"
	progress_label.text = ""
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1

	var due: Dictionary = GameBackend.get_internal_due_today()
	var subjects: Array = GameBackend.active_subjects
	if subjects.is_empty():
		subjects = ["english", "maths", "physics"]

	info_label.text = "Which subject?"
	for subject in subjects:
		var btn := Button.new()
		var credits: int = GameBackend.subject_credits.get(subject, 0)
		var is_exam_subject: bool = not due.is_empty() and due.subject == subject
		# Show readiness next to the credit count: credits are what you've
		# banked, revision is what you'd get if you sat it today.
		btn.text = "%s  [%d cr · revision %.0f%%]%s" % [
			str(subject).capitalize().replace("_", " "), credits,
			GameBackend.get_prep(subject),
			"   ← INTERNAL TODAY" if is_exam_subject else ""]
		btn.custom_minimum_size = Vector2(460, 52)
		btn.add_theme_font_size_override("font_size", 18)
		btn.pressed.connect(_start_subject_quiz.bind(subject))
		options_container.add_child(btn)

	var cancel := Button.new()
	cancel.text = "Never mind"
	cancel.custom_minimum_size = Vector2(460, 44)
	cancel.pressed.connect(func():
		minigame_overlay.visible = false
		task_active = false)
	options_container.add_child(cancel)

	_set_hint("")
	minigame_overlay.visible = true


const PLAY_AREA_MIN := Vector2(0, 0)
const PLAY_AREA_MAX := Vector2(1050, 650)


func _add_decoration(path: String, pos: Vector2) -> void:
	var deco := Sprite2D.new()
	deco.texture = load(path)
	deco.position = pos
	deco.z_index = 2
	$Decorations.add_child(deco)


func _physics_process(_delta: float) -> void:
	if task_active:
		player.velocity = Vector2.ZERO
		return
	var input_vec := Input.get_vector("left", "right", "up", "down")
	player.velocity = input_vec * MOVE_SPEED
	player.move_and_slide()
	player.global_position = player.global_position.clamp(PLAY_AREA_MIN, PLAY_AREA_MAX)


func _unhandled_input(event: InputEvent) -> void:
	if task_active:
		return
	if event.is_action_pressed("interact") and current_station != "":
		_start_task(current_station)
	elif event.is_action_pressed("use_item"):
		_use_selected_item()


func _use_selected_item() -> void:
	var item: ItemData = Inventory.hotbar[Inventory.selected_slot]
	if item == null:
		return
	match item.item_name:
		"Phone":
			_set_hint("Phones aren't allowed at school!")
		"Water Bottle":
			if GameBackend.use_water_bottle():
				Audio.play("drink")
			else:
				Audio.play("error")
				_set_hint("Your water bottle is empty — find a tap to refill it.")


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
	_set_hint("Press E to interact" if current_station != "" else "", 0.0)


func _start_task(station: String) -> void:
	if desk_subjects.has(station):
		_start_desk_picker()
		return
	match station:
		"teacher":
			_start_teacher_menu()
		"student":
			_start_conversation(SchoolData.get_student_conversation(GameBackend.player_name))
		"fountain":
			_use_fountain()
		"exit":
			_end_school_day()


# --- Subject study desks (same shape as the original study minigame) -------

var is_exam: bool = false


## Sitting at a desk. If today's scheduled exam is for this subject, this
## becomes the exam instead of an ordinary study session — longer, and it
## swings your grade much harder either way.
func _start_subject_quiz(subject: String) -> void:
	var due: Dictionary = GameBackend.get_internal_due_today()
	is_exam = not due.is_empty() and due.subject == subject

	current_task_type = subject
	task_active = true
	round_index = 0
	round_correct = 0

	if is_exam:
		round_queue = StudyData.get_session_questions(subject, GameBackend.EXAM_QUESTION_COUNT)
		title_label.text = "%s INTERNAL" % subject.capitalize()
	else:
		round_queue = StudyData.get_session_questions(subject, QUESTIONS_PER_SESSION)
		title_label.text = "%s Study" % subject.capitalize()

	_set_hint("")
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

	# THIS is what revision buys you. In an assessment (not a study session),
	# preparedness strikes out wrong answers — one per 30% revision, capped at
	# three. Turn up prepared and the paper is genuinely easier; turn up cold
	# and you're guessing between four.
	var struck: Dictionary = {}
	if is_exam:
		var hints: int = GameBackend.hints_for(current_task_type)
		if hints > 0:
			var wrong: Array = []
			for i in opts.size():
				if i != int(q.correct):
					wrong.append(i)
			wrong.shuffle()
			# Never strike out everything — always leave a real choice.
			for n in mini(hints, maxi(0, wrong.size() - 1)):
				struck[wrong[n]] = true
			if not struck.is_empty():
				progress_label.text += "   ·   revision struck out %d" % struck.size()

	for i in opts.size():
		var btn := Button.new()
		btn.text = opts[i]
		btn.custom_minimum_size = Vector2(460, 52)
		btn.add_theme_font_size_override("font_size", 18)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if struck.has(i):
			btn.disabled = true
			btn.text = "%s   (ruled out)" % opts[i]
			btn.modulate = Color(0.55, 0.55, 0.58)
		else:
			btn.pressed.connect(_on_quiz_choice.bind(i == q.correct))
		options_container.add_child(btn)


func _on_quiz_choice(is_correct: bool) -> void:
	if answered_current:
		return
	answered_current = true
	Audio.play("correct" if is_correct else "wrong")
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

	if is_exam:
		var passed: bool = GameBackend.complete_exam(current_task_type, round_correct, round_queue.size())
		Audio.play("exam_pass" if passed else "exam_fail")
		var pct: int = int(round(100.0 * round_correct / max(1, round_queue.size())))
		_set_hint("%s exam: %d%% — %s" % [
			current_task_type.capitalize(), pct, "PASSED!" if passed else "failed."])
		is_exam = false
		return

	var hours: float = HOURS_PER_QUESTION * round_queue.size()
	GameBackend.complete_study_session(
		current_task_type, round_correct, round_queue.size(), hours, ENERGY_COST_PER_QUESTION, DESK_STUDY_DEPTH
	)
	# Studying at school counts as turning up to the study group, if you'd
	# said you would.
	GameBackend.fulfil_commitment("study_group")
	_set_hint("%s: %d / %d correct" % [current_task_type.capitalize(), round_correct, round_queue.size()])


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
	_set_hint("")
	minigame_overlay.visible = true


func _start_teacher_chat() -> void:
	_start_conversation(SchoolData.get_teacher_conversation(GameBackend.player_name))


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
	var subjects: Array = GameBackend.active_subjects if not GameBackend.active_subjects.is_empty() else ["english", "maths", "physics"]
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
	# Extra credit with Halloway is one of only two things that moves a grade
	# (the other being an assessment). A desk on your own never does.
	GameBackend.teacher_extra_credit(
		teacher_subject, round_correct, 1, TEACHER_HOURS, TEACHER_ENERGY_COST, TEACHER_MAX_GRADE_GAIN
	)
	_set_hint(SchoolData.get_teacher_result_line(is_correct))


# --- Conversations ------------------------------------------------------------
# One generic runner for every face-to-face chat in the school. Conversations
# are the same shape as the phone threads (a list of steps; each reply can
# "goto" any other step), so a chat is a real back-and-forth that branches on
# what you said rather than opener -> reply -> canned follow-up.
#
# The stress relief and temptation from every reply you picked are banked as
# you go and applied once, at the end, in a single socialize() call — so a
# long conversation is worth more than a short one, and a kind one is worth
# more than a dismissive one.

var current_convo: Dictionary = {}
var convo_step: int = 0
var pending_sanity: float = 0.0
var pending_temptation: float = 0.0


func _start_conversation(convo: Dictionary) -> void:
	if convo.is_empty() or not convo.has("steps"):
		return
	current_task_type = "dialogue"
	task_active = true
	current_convo = convo
	convo_step = 0
	pending_sanity = 0.0
	pending_temptation = 0.0
	title_label.text = str(convo.get("speaker", "Chat"))
	progress_label.text = ""
	feedback_label.text = ""
	next_button.visible = false
	_set_hint("")
	minigame_overlay.visible = true
	_show_convo_step()


func _show_convo_step() -> void:
	var steps: Array = current_convo.steps
	if convo_step < 0 or convo_step >= steps.size():
		_finish_conversation()
		return

	var step: Dictionary = steps[convo_step]
	info_label.text = str(step.them)

	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1

	for reply in step.replies:
		var btn := Button.new()
		btn.text = str(reply.text)
		btn.custom_minimum_size = Vector2(460, 48)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_convo_reply.bind(reply))
		options_container.add_child(btn)


func _on_convo_reply(reply: Dictionary) -> void:
	Audio.play("click")
	pending_sanity += float(reply.get("sanity", 0.0))
	pending_temptation += float(reply.get("temptation", 0.0))

	# Agreeing to something face to face books it, same as over text.
	if reply.has("commit"):
		var c: Dictionary = reply["commit"]
		GameBackend.add_commitment(
			str(c.get("kind", "other")),
			str(c.get("label", "Something you agreed to")),
			GameBackend.get_elapsed_days() + int(c.get("in", 1)))

	var next: int = SchoolData.next_step_for(reply, convo_step)
	# A reply that runs off the end of the steps list is how a branch ends.
	if next >= current_convo.steps.size() or bool(reply.get("ends", false)):
		_finish_conversation()
		return
	convo_step = next
	_show_convo_step()


func _finish_conversation() -> void:
	# A proper conversation costs about twenty minutes; the relief scales
	# with how you actually handled it.
	GameBackend.socialize(max(0.0, pending_sanity), 0.35, max(0.0, pending_temptation))
	minigame_overlay.visible = false
	task_active = false
	if pending_sanity >= 25.0:
		_set_hint("That actually helped. A lot.")
	elif pending_sanity >= 10.0:
		_set_hint("Chatted for a bit — feeling steadier.")
	else:
		_set_hint("Well. That was a conversation.")


# --- Fountain: instant, no overlay needed -----------------------------------

func _use_fountain() -> void:
	GameBackend.drink_water()
	if _has_water_bottle() and not GameBackend.water_bottle_full:
		GameBackend.refill_water_bottle()
		_set_hint("You have a drink and refill your water bottle.")
	else:
		_set_hint("You have a drink. Water topped up!")


 


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


## Shows a message in the bottom banner. Pass "" to hide it.
## `hold_seconds` of 0 (or less) means "leave it up until something replaces
## it" — used for the standing 'Press E' prompt. Anything else auto-clears.
##
## Deliberately NOT async: an earlier version awaited a timer here, which made
## every call site an implicit coroutine and produced "trying to call an async
## function without await" warnings all over the place.
func _set_hint(text_value: String, hold_seconds: float = 3.5) -> void:
	hint_label.text = text_value
	hint_panel.visible = text_value != ""
	_hint_time_left = hold_seconds if text_value != "" else 0.0


## Counts down any temporary hint and hides the banner when it expires.
func _tick_hint(delta: float) -> void:
	if _hint_time_left <= 0.0:
		return
	_hint_time_left -= delta
	if _hint_time_left <= 0.0:
		hint_label.text = ""
		hint_panel.visible = false


func _process(delta: float) -> void:
	_tick_hint(delta)
