## work_scene.gd
## Root script for WorkScene.tscn — a textured 2D top-down supermarket shift.
## Walk up to a station and press "interact" (bind this to E in Project Settings
## -> Input Map) to start that task. Clock out at the EXIT to bank your pay.
extends Node2D

const MOVE_SPEED: float = 220.0
const RESTOCK_ROUNDS: int = 5
const CHECKOUT_ROUNDS: int = 5
const CUSTOMER_ROUNDS: int = 3
const BAKERY_ROUNDS: int = 4
const DELI_ROUNDS: int = 5
const RESTOCK_TIME_LIMIT: float = 6.0
const CHECKOUT_TIME_LIMIT: float = 2.0
const BAKE_TIME_LIMIT: float = 2.5           # used by both "bake" (bakery) and "slice" (deli) — precision-zone steps
const KNEAD_TIME_LIMIT: float = 3.0          # used by both "knead" (bakery) and "chop" (deli) — rapid-press steps
const KNEAD_TARGET_CLICKS: int = 10
const HOURS_PER_RESTOCK_ITEM: float = 0.08
const HOURS_PER_CHECKOUT_ITEM: float = 0.08
const HOURS_PER_CUSTOMER: float = 0.1
const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const GUI_SCENE := preload("res://Characters/GUI/GUI_Scenes/gui.tscn")
const PAUSE_MENU_SCENE := preload("res://Main_Game/Scenes/PauseMenu2D.tscn")
const HOURS_PER_BAKE: float = 0.05
const HOURS_PER_DELI_ITEM: float = 0.04
const BAKE_ZONE_WIDTH: float = 0.18  # fraction of the bake track counted as "perfect"

@onready var player: CharacterBody2D = $Player
@onready var floor_container: Node2D = $Floor

@onready var shelf_area: Area2D = $ShelfStation/InteractArea
@onready var shelf_prompt: Label = $ShelfStation/PromptLabel
@onready var bakery_area: Area2D = $BakeryStation/InteractArea
@onready var bakery_prompt: Label = $BakeryStation/PromptLabel
@onready var deli_area: Area2D = $DeliStation/InteractArea
@onready var deli_prompt: Label = $DeliStation/PromptLabel
@onready var checkout_area: Area2D = $CheckoutStation/InteractArea
@onready var checkout_prompt: Label = $CheckoutStation/PromptLabel
@onready var customer_area: Area2D = $CustomerStation/InteractArea
@onready var customer_prompt: Label = $CustomerStation/PromptLabel
@onready var customer_sprite: Sprite2D = $CustomerStation/CustomerSprite
@onready var exit_area: Area2D = $ExitStation/InteractArea
@onready var exit_prompt: Label = $ExitStation/PromptLabel

@onready var task_timer: Timer = $TaskTimer

@onready var money_label: Label = $CanvasLayer/HUD/MoneyLabel
@onready var hint_label: Label = $CanvasLayer/HUD/HintLabel

@onready var minigame_overlay: Control = $CanvasLayer/MinigameOverlay
@onready var title_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var timer_bar: ProgressBar = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/TimerBar
@onready var icon_row: HBoxContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/IconRow
@onready var target_icon: TextureRect = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/IconRow/TargetIcon
@onready var info_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var bake_container: Control = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/BakeContainer
@onready var bake_zone: ColorRect = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/BakeContainer/BakeZone
@onready var bake_indicator: ColorRect = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/BakeContainer/BakeIndicator
@onready var mash_container: Control = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/MashContainer
@onready var mash_meter: ProgressBar = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/MashContainer/MashMeter
@onready var options_container: GridContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/OptionsContainer
@onready var drag_container: Control = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer
@onready var drag_item: TextureRect = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/DragItem
@onready var drag_zone: ColorRect = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/DragZone
@onready var feedback_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/FeedbackLabel
@onready var next_button: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/NextButton

@onready var results_panel: Control = $CanvasLayer/ResultsPanel
@onready var results_label: Label = $CanvasLayer/ResultsPanel/CenterContainer/Panel/VBoxContainer/ResultsLabel
@onready var close_button: Button = $CanvasLayer/ResultsPanel/CenterContainer/Panel/VBoxContainer/CloseButton

var current_station: String = ""
var task_active: bool = false
var current_task_type: String = ""

var round_queue: Array = []
var round_index: int = 0
var round_correct: int = 0
var answered_current: bool = false
var mash_progress: int = 0
var drag_dragging: bool = false
var drag_context: String = ""  # "checkout" or "restock" — what a successful drop does

const RESTOCK_FILL_TARGET: int = 4
var restock_fill: int = 0
var restock_target_item: Dictionary = {}

var shift_hours: float = 0.0
var shift_task_score: int = 0
var shift_task_total: int = 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_floor()

	var customer_textures := [
		"res://Backend/Resource/Textures/customer_a.png",
		"res://Backend/Resource/Textures/customer_b.png",
		"res://Backend/Resource/Textures/customer_c.png",
	]
	customer_sprite.texture = load(customer_textures[randi() % customer_textures.size()])

	shelf_area.body_entered.connect(_on_station_entered.bind("shelf"))
	shelf_area.body_exited.connect(_on_station_exited.bind("shelf"))
	bakery_area.body_entered.connect(_on_station_entered.bind("bakery"))
	bakery_area.body_exited.connect(_on_station_exited.bind("bakery"))
	deli_area.body_entered.connect(_on_station_entered.bind("deli"))
	deli_area.body_exited.connect(_on_station_exited.bind("deli"))
	checkout_area.body_entered.connect(_on_station_entered.bind("checkout"))
	checkout_area.body_exited.connect(_on_station_exited.bind("checkout"))
	customer_area.body_entered.connect(_on_station_entered.bind("customer"))
	customer_area.body_exited.connect(_on_station_exited.bind("customer"))
	exit_area.body_entered.connect(_on_station_entered.bind("exit"))
	exit_area.body_exited.connect(_on_station_exited.bind("exit"))

	task_timer.timeout.connect(_on_task_timer_timeout)
	next_button.pressed.connect(_on_next_pressed)
	drag_item.gui_input.connect(_on_drag_item_gui_input)
	close_button.pressed.connect(_on_close_results)

	money_label.text = "Money: $%.2f" % GameBackend.money
	# Note: no Sky3D in this scene — complete_work_shift() queues the whole
	# shift's hours via GameBackend.advance_time(), applied to MainMap's
	# clock when you return through the exit.

	GameBackend.game_ended.connect(_on_game_ended)
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())
	get_tree().current_scene.add_child(GUI_SCENE.instantiate())
	get_tree().current_scene.add_child(PAUSE_MENU_SCENE.instantiate())


const PLAY_AREA_MIN := Vector2(0, 0)
const PLAY_AREA_MAX := Vector2(1000, 650)


func _build_floor() -> void:
	var floor_tex: Texture2D = load("res://Backend/Resource/Textures/floor_tile.png")
	# Generous margin beyond the play area so the camera never sees past the
	# floor's edge, even zoomed in at a corner station.
	for x in range(-400, 1500, 64):
		for y in range(-400, 1150, 64):
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


func _process(_delta: float) -> void:
	if timer_bar.visible and task_timer.wait_time > 0.0:
		timer_bar.value = task_timer.time_left / task_timer.wait_time
	if bake_container.visible and task_timer.wait_time > 0.0:
		var progress: float = 1.0 - (task_timer.time_left / task_timer.wait_time)
		var track_width: float = bake_container.custom_minimum_size.x
		bake_indicator.position.x = clamp(progress * track_width, 0.0, track_width - bake_indicator.size.x)


func _unhandled_input(event: InputEvent) -> void:
	if drag_dragging:
		if event is InputEventMouseMotion:
			var max_x: float = drag_container.custom_minimum_size.x - drag_item.size.x
			drag_item.position.x = clamp(drag_item.position.x + event.relative.x, 0.0, max_x)
			_check_drag_drop()
			return
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			drag_dragging = false
			return

	if task_active:
		return
	if event.is_action_pressed("interact") and current_station != "":
		if current_station == "exit":
			_end_shift()
		else:
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
			if not GameBackend.use_water_bottle():
				hint_label.text = "Your water bottle is empty — find a tap to refill it."


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
	shelf_prompt.visible = current_station == "shelf"
	bakery_prompt.visible = current_station == "bakery"
	deli_prompt.visible = current_station == "deli"
	checkout_prompt.visible = current_station == "checkout"
	customer_prompt.visible = current_station == "customer"
	exit_prompt.visible = current_station == "exit"
	if task_active:
		return
	hint_label.text = "Press E to interact" if current_station != "" else ""


# --- Task flow -------------------------------------------------------------

func _start_task(station: String) -> void:
	if task_active:
		return
	current_task_type = station
	task_active = true
	round_index = 0
	round_correct = 0

	match station:
		"shelf":
			round_queue = WorkData.get_restock_round(RESTOCK_ROUNDS)
			title_label.text = "Restocking Shelves"
		"bakery":
			round_queue = WorkData.get_bakery_round(BAKERY_ROUNDS)
			title_label.text = "Bakery"
		"deli":
			round_queue = WorkData.get_deli_round(DELI_ROUNDS)
			title_label.text = "Deli Counter"
		"checkout":
			round_queue = WorkData.get_checkout_round(CHECKOUT_ROUNDS)
			title_label.text = "Checkout"
		"customer":
			round_queue = WorkData.get_customer_questions(CUSTOMER_ROUNDS)
			title_label.text = "Customer Service"

	hint_label.text = ""
	minigame_overlay.visible = true
	_show_step()


func _show_step() -> void:
	feedback_label.text = ""
	next_button.visible = false
	answered_current = false
	bake_container.visible = false
	mash_container.visible = false
	drag_container.visible = false
	drag_dragging = false
	drag_item.position.x = 0.0
	for child in options_container.get_children():
		child.queue_free()

	match current_task_type:
		"shelf":
			_show_restock_step()

		"bakery":
			var bitem: Dictionary = round_queue[round_index]
			if bitem.kind == "knead":
				_show_mash_step(bitem, "Knead", "Knead the %s dough! Mash the button before time's up!" % bitem.name)
			else:
				_show_precision_step(bitem, "Bake", "Baking: %s\nHit Bake! when the marker is in the green zone!" % bitem.name)

		"deli":
			var ditem: Dictionary = round_queue[round_index]
			if ditem.kind == "chop":
				_show_mash_step(ditem, "Chop", "Chop the %s! Mash the button before time's up!" % ditem.name)
			else:
				_show_precision_step(ditem, "Slice", "Slicing: %s\nHit Slice! when the marker is in the green zone!" % ditem.name)

		"checkout":
			icon_row.visible = false
			timer_bar.visible = true
			var citem: Dictionary = round_queue[round_index]
			info_label.text = "%s — $%.2f\nDrag it across to the scanner!" % [citem.name, citem.price]
			options_container.columns = 1
			drag_context = "checkout"
			drag_container.visible = true
			drag_item.texture = load(citem.texture)
			drag_item.position.x = 0.0
			_start_timer(CHECKOUT_TIME_LIMIT)

		"customer":
			icon_row.visible = false
			timer_bar.visible = false
			var q: Dictionary = round_queue[round_index]
			info_label.text = q.question
			options_container.columns = 1
			var opts: Array = q.options
			for i in opts.size():
				var abtn := Button.new()
				abtn.text = opts[i]
				abtn.pressed.connect(_on_untimed_choice.bind(i == q.correct))
				options_container.add_child(abtn)


## Restocking: keep clicking the matching item to fill the shelf's stock
## meter before time runs out. Options reshuffle after every click (right or
## wrong) so it feels like repeatedly grabbing units off a supply cart.
## Restocking: drag the item into the shelf slot to fill the stock meter.
## The item resets to the start each successful drop, so filling the shelf
## takes several drags — feels like repeatedly grabbing units off a cart.
func _show_restock_step() -> void:
	icon_row.visible = false
	timer_bar.visible = true
	mash_container.visible = true
	restock_target_item = round_queue[round_index]
	restock_fill = 0
	info_label.text = "Stock the shelf with %s!\nDrag it into the shelf slot — keep going until it's full." % restock_target_item.name
	mash_meter.max_value = RESTOCK_FILL_TARGET
	mash_meter.value = 0
	options_container.columns = 1
	drag_context = "restock"
	drag_container.visible = true
	drag_item.texture = load(restock_target_item.texture)
	drag_item.position.x = 0.0
	_start_timer(RESTOCK_TIME_LIMIT)


## Precision-zone step: a marker sweeps a bar, hit the action button while
## it's in the green zone. Used for "bake" (bakery) and "slice" (deli).
func _show_precision_step(item: Dictionary, verb: String, message: String) -> void:
	icon_row.visible = true
	timer_bar.visible = false
	bake_container.visible = true
	target_icon.texture = load(item.texture)
	info_label.text = message
	var zone_start: float = randf_range(0.1, 1.0 - BAKE_ZONE_WIDTH - 0.1)
	var track_width: float = bake_container.custom_minimum_size.x
	bake_zone.position.x = zone_start * track_width
	bake_zone.size.x = BAKE_ZONE_WIDTH * track_width
	options_container.columns = 1
	var action_btn := Button.new()
	action_btn.text = "%s!" % verb
	action_btn.pressed.connect(_on_bake_take_out.bind(zone_start))
	options_container.add_child(action_btn)
	_start_timer(BAKE_TIME_LIMIT)


## Rapid-press step: mash the button to fill the meter before time runs out.
## Used for "knead" (bakery) and "chop" (deli).
func _show_mash_step(item: Dictionary, verb: String, message: String) -> void:
	icon_row.visible = true
	timer_bar.visible = true
	mash_container.visible = true
	target_icon.texture = load(item.texture)
	info_label.text = message
	mash_progress = 0
	mash_meter.max_value = KNEAD_TARGET_CLICKS
	mash_meter.value = 0
	options_container.columns = 1
	var mash_btn := Button.new()
	mash_btn.text = "%s!" % verb
	mash_btn.pressed.connect(_on_mash_press)
	options_container.add_child(mash_btn)
	_start_timer(KNEAD_TIME_LIMIT)


func _start_timer(duration: float) -> void:
	task_timer.wait_time = duration
	task_timer.start()


func _on_task_timer_timeout() -> void:
	if answered_current:
		return
	_resolve_step(false)


func _on_timed_choice(is_correct: bool) -> void:
	if answered_current:
		return
	task_timer.stop()
	_resolve_step(is_correct)


func _on_untimed_choice(is_correct: bool) -> void:
	if answered_current:
		return
	_resolve_step(is_correct)


## Fires when the mouse presses down on the draggable icon itself. Only
## detects the START of a drag — actual motion/release is tracked in
## _unhandled_input (see below), since a small Control like this icon can
## easily be "outrun" by fast mouse movement if it tried to track motion
## itself, and stop receiving events.
func _on_drag_item_gui_input(event: InputEvent) -> void:
	if answered_current:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		drag_dragging = true


## Checked on every mouse-motion while dragging (from _unhandled_input).
## "checkout": one successful drag into the zone finishes the step.
## "restock": each successful drag fills the shelf meter a bit and resets
## the icon to the start for the next unit, until the meter's full.
func _check_drag_drop() -> void:
	if answered_current:
		return
	if drag_item.position.x + drag_item.size.x * 0.5 < drag_zone.position.x:
		return

	match drag_context:
		"checkout":
			drag_dragging = false
			task_timer.stop()
			_resolve_step(true)
		"restock":
			restock_fill += 1
			mash_meter.value = restock_fill
			if restock_fill >= RESTOCK_FILL_TARGET:
				drag_dragging = false
				task_timer.stop()
				_resolve_step(true)
			else:
				drag_dragging = false
				drag_item.position.x = 0.0


func _on_mash_press() -> void:
	if answered_current:
		return
	mash_progress += 1
	mash_meter.value = mash_progress
	if mash_progress >= KNEAD_TARGET_CLICKS:
		task_timer.stop()
		_resolve_step(true)


func _on_bake_take_out(zone_start: float) -> void:
	if answered_current:
		return
	# Read progress BEFORE stopping — Timer.stop() zeroes time_left immediately.
	var progress: float = 1.0 - (task_timer.time_left / task_timer.wait_time) if task_timer.wait_time > 0.0 else 1.0
	task_timer.stop()
	var in_zone: bool = progress >= zone_start and progress <= zone_start + BAKE_ZONE_WIDTH
	_resolve_step(in_zone)


func _resolve_step(is_correct: bool) -> void:
	answered_current = true
	if is_correct:
		round_correct += 1
		feedback_label.text = "Nice one!"
	else:
		feedback_label.text = "Missed that one."
	for child in options_container.get_children():
		if child is BaseButton:
			child.disabled = true
	drag_dragging = false
	next_button.visible = true


func _on_next_pressed() -> void:
	round_index += 1
	if round_index >= round_queue.size():
		_finish_task()
	else:
		_show_step()


func _finish_task() -> void:
	minigame_overlay.visible = false
	task_active = false

	var hours_for_task: float = 0.0
	match current_task_type:
		"shelf":
			hours_for_task = HOURS_PER_RESTOCK_ITEM * round_queue.size()
		"bakery":
			hours_for_task = HOURS_PER_BAKE * round_queue.size()
		"deli":
			hours_for_task = HOURS_PER_DELI_ITEM * round_queue.size()
		"checkout":
			hours_for_task = HOURS_PER_CHECKOUT_ITEM * round_queue.size()
		"customer":
			hours_for_task = HOURS_PER_CUSTOMER * round_queue.size()

	shift_hours += hours_for_task
	shift_task_score += round_correct
	shift_task_total += round_queue.size()
	hint_label.text = "%s done: %d / %d correct" % [current_task_type.capitalize(), round_correct, round_queue.size()]


# --- Shift end ---------------------------------------------------------------

func _end_shift() -> void:
	if task_active:
		return
	if shift_hours <= 0.0:
		hint_label.text = "Do at least one task before clocking out!"
		return

	var performance: float = 0.0 if shift_task_total == 0 else float(shift_task_score) / float(shift_task_total)
	GameBackend.complete_work_shift(shift_hours, performance)

	results_label.text = "Shift complete!\nHours worked: %.1f\nTasks: %d / %d correct\nTotal money: $%.2f" % [
		shift_hours, shift_task_score, shift_task_total, GameBackend.money
	]
	results_panel.visible = true
	money_label.text = "Money: $%.2f" % GameBackend.money

	shift_hours = 0.0
	shift_task_score = 0
	shift_task_total = 0


const MAIN_MAP_SCENE: String = "res://Main_Game/Scenes/MainMap.tscn"

func _on_close_results() -> void:
	get_tree().change_scene_to_file(MAIN_MAP_SCENE)


func _on_game_ended(_result: String) -> void:
	get_tree().change_scene_to_file("res://Main_Game/Scenes/EndingScene.tscn")
