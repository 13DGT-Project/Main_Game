## home_scene.gd
## Root script for HomeScene.tscn — a 2D home base. Bed to sleep, desk to
## study, stove to cook, couch to watch TV, plus where you pick up the Phone
## and Water Bottle for the first time.
extends Node2D

const MOVE_SPEED: float = 220.0
const QUESTIONS_PER_SESSION: int = 5
const HOURS_PER_QUESTION: float = 0.15
const ENERGY_COST_PER_QUESTION: float = 6.0
## Readiness gained from a full desk session at home. Studying does not move
## grades or award credits any more — see GameBackend.subject_prep.
const DESK_STUDY_DEPTH: float = 16.0
const MAIN_MAP_SCENE: String = "res://Main_Game/Scenes/MainMap.tscn"

const PHONE_ITEM := preload("res://Backend/Resource/Items/Phone.tres")
const WATER_BOTTLE_ITEM := preload("res://Backend/Resource/Items/WaterBottle.tres")

const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const GUI_SCENE := preload("res://Characters/GUI/GUI_Scenes/gui.tscn")

const PLAY_AREA_MIN := Vector2(0, 0)
const PLAY_AREA_MAX := Vector2(1050, 650)

@onready var player: CharacterBody2D = $Player
@onready var floor_layer: TileMapLayer = $Floor
@onready var walls_layer: TileMapLayer = $Walls

@onready var bed_area: Area2D = $BedStation/InteractArea
@onready var bed_prompt: Label = $BedStation/PromptLabel
@onready var desk_area: Area2D = $DeskStation/InteractArea
@onready var desk_prompt: Label = $DeskStation/PromptLabel
@onready var stove_area: Area2D = $StoveStation/InteractArea
@onready var stove_prompt: Label = $StoveStation/PromptLabel
@onready var couch_area: Area2D = $CouchStation/InteractArea
@onready var couch_prompt: Label = $CouchStation/PromptLabel

@onready var laptop_area: Area2D = $LaptopStation/InteractArea
@onready var laptop_prompt: Label = $LaptopStation/PromptLabel

@onready var phone_spot: Node2D = $PhoneSpot
@onready var phone_area: Area2D = $PhoneSpot/InteractArea
@onready var phone_prompt: Label = $PhoneSpot/PromptLabel
@onready var bottle_spot: Node2D = $BottleSpot
@onready var bottle_area: Area2D = $BottleSpot/InteractArea
@onready var bottle_prompt: Label = $BottleSpot/PromptLabel

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

var current_station: String = ""
var _hint_time_left: float = 0.0
var task_active: bool = false
var current_task_type: String = ""

var round_queue: Array = []
var round_index: int = 0
var round_correct: int = 0
var answered_current: bool = false


func _ready() -> void:
	Audio.play_ambience("home")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	bed_area.body_entered.connect(_on_station_entered.bind("bed"))
	bed_area.body_exited.connect(_on_station_exited.bind("bed"))
	desk_area.body_entered.connect(_on_station_entered.bind("desk"))
	desk_area.body_exited.connect(_on_station_exited.bind("desk"))
	stove_area.body_entered.connect(_on_station_entered.bind("stove"))
	stove_area.body_exited.connect(_on_station_exited.bind("stove"))
	couch_area.body_entered.connect(_on_station_entered.bind("couch"))
	couch_area.body_exited.connect(_on_station_exited.bind("couch"))
	laptop_area.body_entered.connect(_on_station_entered.bind("laptop"))
	laptop_area.body_exited.connect(_on_station_exited.bind("laptop"))
	phone_area.body_entered.connect(_on_station_entered.bind("phone"))
	phone_area.body_exited.connect(_on_station_exited.bind("phone"))
	bottle_area.body_entered.connect(_on_station_entered.bind("bottle"))
	bottle_area.body_exited.connect(_on_station_exited.bind("bottle"))
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
	# The laptop is an autoload built in code (see laptop.gd) so it can grow
	# without touching this scene. It hands control back here for the two
	# things that belong to the room rather than the website.
	if not Laptop.study_requested.is_connected(_start_online_study):
		Laptop.study_requested.connect(_start_online_study)
	if not Laptop.game_requested.is_connected(_start_memory_game_standalone):
		Laptop.game_requested.connect(_start_memory_game_standalone)
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())
	get_tree().current_scene.add_child(GUI_SCENE.instantiate())


func _has_item(item_name: String) -> bool:
	for item in Inventory.hotbar:
		if item != null and item.item_name == item_name:
			return true
	return false


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
			PhoneApp.toggle()
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
	bed_prompt.visible = current_station == "bed"
	desk_prompt.visible = current_station == "desk"
	stove_prompt.visible = current_station == "stove"
	couch_prompt.visible = current_station == "couch"
	laptop_prompt.visible = current_station == "laptop"
	phone_prompt.visible = current_station == "phone" and phone_spot.visible
	bottle_prompt.visible = current_station == "bottle" and bottle_spot.visible
	exit_prompt.visible = current_station == "exit"
	if task_active:
		return
	_set_hint("Press E to interact" if current_station != "" else "", 0.0)


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
		"laptop":
			_start_laptop()
		"phone":
			_pickup_item("phone")
		"bottle":
			_pickup_item("bottle")
		"exit":
			get_tree().change_scene_to_file(MAIN_MAP_SCENE)


# --- Pickups -----------------------------------------------------------------

func _pickup_item(kind: String) -> void:
	var item: ItemData = PHONE_ITEM if kind == "phone" else WATER_BOTTLE_ITEM
	if Inventory.add_item(item):
		if kind == "phone":
			phone_spot.visible = false
			phone_area.set_deferred("monitoring", false)
			_set_hint("Picked up your phone.")
		else:
			bottle_spot.visible = false
			bottle_area.set_deferred("monitoring", false)
			_set_hint("Picked up your water bottle.")
		current_station = ""
	else:
		_set_hint("Your hotbar is full — drop something first.")


# --- Bed ---------------------------------------------------------------------
# Sleeping used to be a flat "sleep 8 hours" from wherever the clock happened
# to be, which is why you could go to bed at 8pm and get up at 4am with
# nothing open and nowhere to go. You now sleep THROUGH TO THE MORNING, so
# whatever time you turn in, you wake at GameBackend.WAKE_HOUR ready for a
# school day — and going to bed stupidly late costs you the quality of the
# night rather than shifting your whole schedule.

func _start_bed() -> void:
	current_task_type = "bed"
	task_active = true
	title_label.text = "Bed"
	progress_label.text = "%s — %s" % [_clock_text(), _bed_mood_text()]

	var hours: float = GameBackend.hours_until_morning()
	info_label.text = "Sleep through to %d:00? That's %.0f hours from now.\n\n%s" % [
		int(GameBackend.WAKE_HOUR), hours, _sleep_quality_warning(hours)]

	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1

	var sleep_btn := Button.new()
	sleep_btn.text = "Sleep until morning  (%.0f hours)" % hours
	sleep_btn.custom_minimum_size = Vector2(420, 48)
	sleep_btn.pressed.connect(_on_sleep_pressed)
	options_container.add_child(sleep_btn)

	# A nap is the answer to "it's 4pm, I'm wrecked, but I'm not throwing
	# away the whole evening".
	if GameBackend.game_hour < 20.0 and GameBackend.game_hour > 10.0:
		var nap_btn := Button.new()
		nap_btn.text = "Just a nap  (2 hours)"
		nap_btn.custom_minimum_size = Vector2(420, 44)
		nap_btn.pressed.connect(_on_nap_pressed)
		options_container.add_child(nap_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Not yet"
	cancel_btn.custom_minimum_size = Vector2(420, 40)
	cancel_btn.pressed.connect(_close_overlay)
	options_container.add_child(cancel_btn)

	_set_hint("")
	minigame_overlay.visible = true


func _clock_text() -> String:
	var h: int = int(GameBackend.game_hour)
	var m: int = int((GameBackend.game_hour - float(h)) * 60.0)
	return "%02d:%02d" % [h, m]


func _bed_mood_text() -> String:
	if GameBackend.energy < 25.0:
		return "you are completely done in"
	if GameBackend.energy < 55.0:
		return "you're flagging"
	return "you're not especially tired"


func _sleep_quality_warning(hours: float) -> String:
	if hours <= 4.0:
		return "It's very late. You'll get up on time, but you won't get up rested."
	if hours >= 11.0:
		return "It's early. You'll sleep badly and you'll have thrown away an evening you could have used."
	return "A proper night. You'll wake up in decent shape."


func _on_sleep_pressed() -> void:
	var result: Dictionary = GameBackend.sleep_until_morning()
	minigame_overlay.visible = false
	task_active = false
	_set_hint(str(result.get("text", "You wake up.")))


func _on_nap_pressed() -> void:
	GameBackend.nap(2.0)
	minigame_overlay.visible = false
	task_active = false
	_set_hint("A couple of hours out cold. Better than nothing.")


# --- Desk: pick a subject, study (same shape as the school desks) ----------

func _start_desk_select() -> void:
	_is_online_session = false
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
	_set_hint("")
	minigame_overlay.visible = true


func _start_subject_quiz(subject: String) -> void:
	current_task_type = subject
	round_index = 0
	round_correct = 0
	var count: int = ONLINE_QUESTIONS if _is_online_session else QUESTIONS_PER_SESSION
	round_queue = StudyData.get_session_questions(subject, count)
	title_label.text = ("%s — revision videos" if _is_online_session else "%s Study") % subject.capitalize()
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
		btn.custom_minimum_size = Vector2(460, 52)
		btn.add_theme_font_size_override("font_size", 18)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	round_index += 1
	if round_index >= round_queue.size():
		_finish_subject_quiz()
	else:
		_show_quiz_step()


func _finish_subject_quiz() -> void:
	minigame_overlay.visible = false
	task_active = false

	if _is_online_session:
		var online_hours: float = ONLINE_HOURS_PER_QUESTION * round_queue.size()
		GameBackend.complete_study_session(
			current_task_type, round_correct, round_queue.size(),
			online_hours, ONLINE_ENERGY_COST, ONLINE_STUDY_DEPTH
		)
		# The tabs you didn't close. Online revision always costs you a bit of
		# focus, which sitting at the desk doesn't.
		GameBackend.temptation = clamp(GameBackend.temptation + ONLINE_TEMPTATION, 0.0, 100.0)
		GameBackend.stats_changed.emit()
		_is_online_session = false
		_set_hint(GameBackend.prep_report(current_task_type))
		return

	var hours: float = HOURS_PER_QUESTION * round_queue.size()
	GameBackend.complete_study_session(
		current_task_type, round_correct, round_queue.size(), hours, ENERGY_COST_PER_QUESTION, DESK_STUDY_DEPTH
	)
	_set_hint(GameBackend.prep_report(current_task_type))


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

	_set_hint("")
	minigame_overlay.visible = true


func _on_cook_pressed(meal: Dictionary) -> void:
	var success: bool = GameBackend.cook_meal(meal.cost, meal.energy, meal.thirst, meal.sanity)
	minigame_overlay.visible = false
	task_active = false
	if success:
		_set_hint("Made yourself %s." % meal.label.split(" — ")[0])
	else:
		_set_hint("Not enough money for that.")


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
	_set_hint("")
	minigame_overlay.visible = true


func _on_watch_tv_pressed() -> void:
	GameBackend.watch_tv()
	minigame_overlay.visible = false
	task_active = false
	_set_hint("That was a decent watch. Feeling a bit more relaxed.")


func _close_overlay() -> void:
	minigame_overlay.visible = false
	task_active = false


# --- Laptop: study online, or play a quick memory game ---------------------

var _memory_sequence: Array = []
var _memory_input_index: int = 0
var _memory_showing: bool = false


func _start_laptop() -> void:
	# Everything that used to be a two-button menu here now lives in
	# laptop.gd — StudyLink, the NZQA portal, the applicant portal and the
	# fees planner. Opening it doesn't cost time; the individual actions do.
	Laptop.open("home")


## Entry point for the laptop's "Play Sequence" link, which closes the laptop
## and hands back to this scene.
# --- Online study --------------------------------------------------------
# Deliberately NOT the same as sitting at the desk. Online revision is a
# shorter, shallower session: three questions instead of five, less energy
# spent, less grade gained per session, and it nudges temptation UP because
# there are always other tabs open. It's the thing you do when you can't face
# a proper session — useful, but not a substitute for one.

const ONLINE_QUESTIONS: int = 3
const ONLINE_HOURS_PER_QUESTION: float = 0.12
const ONLINE_ENERGY_COST: float = 3.0
## Revision videos are shallower than a real sit-down session.
const ONLINE_STUDY_DEPTH: float = 7.0
const ONLINE_TEMPTATION: float = 5.0

var _is_online_session: bool = false


func _start_online_study() -> void:
	_is_online_session = true
	current_task_type = "online_select"
	task_active = true
	title_label.text = "Revision videos"
	progress_label.text = "Shorter than a real session. Easier to start, worth less."
	info_label.text = "Which subject?"
	feedback_label.text = ""
	next_button.visible = false
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 1

	var subjects: Array = GameBackend.active_subjects if GameBackend.active_subjects.size() >= 3 else ["english", "maths", "physics"]
	for subject in subjects:
		var sbtn := Button.new()
		sbtn.text = "%s  —  revision %.0f%% (%s)" % [
			str(subject).capitalize().replace("_", " "),
			GameBackend.get_prep(subject), GameBackend.predicted_band(subject)]
		sbtn.custom_minimum_size = Vector2(420, 44)
		sbtn.pressed.connect(_start_subject_quiz.bind(subject))
		options_container.add_child(sbtn)

	var cancel := Button.new()
	cancel.text = "Close the tab"
	cancel.custom_minimum_size = Vector2(420, 40)
	cancel.pressed.connect(func():
		_is_online_session = false
		_close_overlay())
	options_container.add_child(cancel)

	_set_hint("")
	minigame_overlay.visible = true


func _start_memory_game_standalone() -> void:
	task_active = true
	title_label.text = "Sequence"
	progress_label.text = ""
	feedback_label.text = ""
	next_button.visible = false
	minigame_overlay.visible = true
	_start_memory_game()


## "Sequence": watch a pattern of coloured buttons light up, then repeat it.
## Gets one step longer each round you get right.
func _start_memory_game() -> void:
	current_task_type = "memory_game"
	title_label.text = "Sequence"
	_memory_sequence.clear()
	_memory_extend()


func _memory_extend() -> void:
	_memory_sequence.append(randi() % 4)
	_memory_input_index = 0
	_show_memory_sequence()


func _show_memory_sequence() -> void:
	_memory_showing = true
	info_label.text = "Watch the sequence... (length %d)" % _memory_sequence.size()
	_build_memory_buttons(false)
	await get_tree().create_timer(0.5).timeout
	for idx in _memory_sequence:
		if not is_inside_tree():
			return
		_flash_memory_button(idx)
		await get_tree().create_timer(0.55).timeout
	_memory_showing = false
	info_label.text = "Your turn — repeat it!"
	_build_memory_buttons(true)


const MEMORY_COLOURS := [
	Color(0.85, 0.20, 0.25),  # red
	Color(0.20, 0.70, 0.35),  # green
	Color(0.20, 0.45, 0.90),  # blue
	Color(0.95, 0.78, 0.15),  # yellow
]

## Each pad is a bright ColorRect with a transparent Button on top. Using
## Button.modulate alone (the previous approach) came out almost black,
## because the button's own dark theme multiplied with the tint.
func _build_memory_buttons(interactive: bool) -> void:
	for child in options_container.get_children():
		child.queue_free()
	options_container.columns = 2
	for i in 4:
		var pad := ColorRect.new()
		pad.custom_minimum_size = Vector2(160, 100)
		pad.color = MEMORY_COLOURS[i].darkened(0.35)
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var b := Button.new()
		b.flat = true
		b.disabled = not interactive
		b.anchor_right = 1.0
		b.anchor_bottom = 1.0
		b.offset_right = 0
		b.offset_bottom = 0
		b.pressed.connect(_on_memory_press.bind(i))
		pad.add_child(b)

		options_container.add_child(pad)


func _flash_memory_button(index: int) -> void:
	if index >= options_container.get_child_count():
		return
	var pad := options_container.get_child(index) as ColorRect
	if pad == null:
		return
	pad.color = MEMORY_COLOURS[index].lightened(0.45)   # bright, unmistakable
	await get_tree().create_timer(0.32).timeout
	if is_instance_valid(pad):
		pad.color = MEMORY_COLOURS[index].darkened(0.35)  # back to dim


func _on_memory_press(index: int) -> void:
	if _memory_showing:
		return
	if index == _memory_sequence[_memory_input_index]:
		_flash_memory_button(index)
		_memory_input_index += 1
		if _memory_input_index >= _memory_sequence.size():
			if _memory_sequence.size() >= 6:
				_finish_memory_game(true)
			else:
				feedback_label.text = "Correct! Getting longer..."
				await get_tree().create_timer(0.6).timeout
				_memory_extend()
	else:
		_finish_memory_game(false)


func _finish_memory_game(won: bool) -> void:
	minigame_overlay.visible = false
	task_active = false
	options_container.columns = 1
	# Same shape as watching TV — a real break, costs time and temptation.
	GameBackend.watch_tv(0.3, 10.0 if won else 5.0, 8.0)
	_set_hint("Nice, cleared it!" if won else "Got there in the end. Good break though.")


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
