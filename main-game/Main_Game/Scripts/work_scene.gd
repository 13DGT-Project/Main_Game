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

const CHECKOUT_SCAN_TIME_LIMIT: float = 5.0
const CHECKOUT_TYPE_TIME_LIMIT: float = 9.0
const RESTOCK_TIME_LIMIT: float = 10.0
const BAKE_TIME_LIMIT: float = 2.5           # used by both "bake" (bakery) and "slice" (deli) — precision-zone steps
const KNEAD_TIME_LIMIT: float = 3.0          # used by both "knead" (bakery) and "chop" (deli) — rapid-press steps
const KNEAD_TARGET_CLICKS: int = 10
const WEIGH_TOLERANCE: float = 0.05

const HOURS_PER_RESTOCK_ITEM: float = 0.12
const HOURS_PER_CHECKOUT_ITEM: float = 0.1
const HOURS_PER_CUSTOMER: float = 0.1
const HOURS_PER_BAKE: float = 0.05
const HOURS_PER_DELI_ITEM: float = 0.04
const BAKE_ZONE_WIDTH: float = 0.18  # fraction of the bake track counted as "perfect"

const RESTOCK_FILL_TARGET: int = 4

const JOURNAL_SCENE := preload("res://Main_Game/Scenes/Journal.tscn")
const GUI_SCENE := preload("res://Characters/GUI/GUI_Scenes/gui.tscn")
const MINIMAP_SCRIPT := preload("res://Main_Game/Scripts/minimap.gd")
const MAIN_MAP_SCENE: String = "res://Main_Game/Scenes/MainMap.tscn"
const BOX_CLOSED_TEXTURE: String = "res://Backend/Resource/Textures/item_box_closed.png"

@onready var player: CharacterBody2D = $Player
@onready var floor_layer: TileMapLayer = $Floor
@onready var walls_layer: TileMapLayer = $Walls

@onready var shelf_area: Area2D = $ShelfStation/InteractArea
@onready var shelf_prompt: Label = $ShelfStation/PromptLabel
@onready var shelf2_area: Area2D = $ShelfStation2/InteractArea
@onready var shelf2_prompt: Label = $ShelfStation2/PromptLabel
@onready var fridge1_area: Area2D = $FridgeStation1/InteractArea
@onready var fridge1_prompt: Label = $FridgeStation1/PromptLabel
@onready var fridge2_area: Area2D = $FridgeStation2/InteractArea
@onready var fridge2_prompt: Label = $FridgeStation2/PromptLabel
@onready var freezer1_area: Area2D = $FreezerStation1/InteractArea
@onready var freezer1_prompt: Label = $FreezerStation1/PromptLabel
@onready var freezer2_area: Area2D = $FreezerStation2/InteractArea
@onready var freezer2_prompt: Label = $FreezerStation2/PromptLabel
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
@onready var hint_panel: PanelContainer = $CanvasLayer/HUD/HintPanel
@onready var hint_label: Label = $CanvasLayer/HUD/HintPanel/HintLabel

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

@onready var drag_container: VBoxContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer
@onready var drag_item: TextureRect = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/HeldRow/DragItem
@onready var held_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/HeldRow/HeldLabel
@onready var pick_up_button: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/PickUpButton
@onready var zone_grid: GridContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/ZoneGrid
@onready var zone1: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/ZoneGrid/Zone1
@onready var zone2: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/ZoneGrid/Zone2
@onready var zone3: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/DragContainer/ZoneGrid/Zone3

@onready var type_container: VBoxContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/TypeContainer
@onready var type_prompt_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/TypeContainer/TypePromptLabel
@onready var type_input: LineEdit = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/TypeContainer/TypeInput
@onready var type_submit_button: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/TypeContainer/TypeSubmitButton
@onready var num_pad: GridContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/TypeContainer/NumPad
@onready var lookup_choices: VBoxContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/TypeContainer/LookupChoices

@onready var feedback_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/FeedbackLabel
@onready var next_button: Button = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/NextButton

@onready var results_panel: Control = $CanvasLayer/ResultsPanel
@onready var results_label: Label = $CanvasLayer/ResultsPanel/CenterContainer/Panel/VBoxContainer/ResultsLabel
@onready var close_button: Button = $CanvasLayer/ResultsPanel/CenterContainer/Panel/VBoxContainer/CloseButton

var current_station: String = ""
var _hint_time_left: float = 0.0
var task_active: bool = false
var current_task_type: String = ""

var round_queue: Array = []
var round_index: int = 0
var round_correct: int = 0
var answered_current: bool = false
var mash_progress: int = 0

var holding_item: bool = false  # true once the item is picked up / box opened
var drag_context: String = ""  # "checkout_scan" or "restock"

var restock_target_item: Dictionary = {}
var restock_fill: int = 0
var restock_box_opened: bool = false

var current_checkout_item: Dictionary = {}

var shift_hours: float = 0.0
var shift_task_score: int = 0
var shift_task_total: int = 0


func _ready() -> void:
	Audio.play_ambience("work")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var customer_textures := [
		"res://Backend/Resource/Textures/customer_a.png",
		"res://Backend/Resource/Textures/customer_b.png",
		"res://Backend/Resource/Textures/customer_c.png",
	]
	customer_sprite.texture = load(customer_textures[randi() % customer_textures.size()])

	shelf_area.body_entered.connect(_on_station_entered.bind("shelf1"))
	shelf_area.body_exited.connect(_on_station_exited.bind("shelf1"))
	shelf2_area.body_entered.connect(_on_station_entered.bind("shelf2"))
	shelf2_area.body_exited.connect(_on_station_exited.bind("shelf2"))
	fridge1_area.body_entered.connect(_on_station_entered.bind("fridge1"))
	fridge1_area.body_exited.connect(_on_station_exited.bind("fridge1"))
	fridge2_area.body_entered.connect(_on_station_entered.bind("fridge2"))
	fridge2_area.body_exited.connect(_on_station_exited.bind("fridge2"))
	freezer1_area.body_entered.connect(_on_station_entered.bind("freezer1"))
	freezer1_area.body_exited.connect(_on_station_exited.bind("freezer1"))
	freezer2_area.body_entered.connect(_on_station_entered.bind("freezer2"))
	freezer2_area.body_exited.connect(_on_station_exited.bind("freezer2"))
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
	pick_up_button.pressed.connect(_on_pick_up_pressed)
	zone1.pressed.connect(_on_zone_pressed.bind(0))
	zone2.pressed.connect(_on_zone_pressed.bind(1))
	zone3.pressed.connect(_on_zone_pressed.bind(2))
	type_submit_button.pressed.connect(_on_type_submit)
	type_input.text_submitted.connect(func(_t): _on_type_submit())
	close_button.pressed.connect(_on_close_results)

	money_label.text = "Money: $%.2f" % GameBackend.money
	# Note: no Sky3D in this scene — complete_work_shift() queues the whole
	# shift's hours via GameBackend.advance_time(), applied to MainMap's
	# clock when you return through the exit.

	GameBackend.game_ended.connect(_on_game_ended)
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())
	get_tree().current_scene.add_child(GUI_SCENE.instantiate())
	_setup_minimap()


## Rooms here mirror the walls painted into the Walls TileMapLayer — keep the two
## in sync if you move anything, or the map will lie to the player.
func _setup_minimap() -> void:
	var minimap := CanvasLayer.new()
	minimap.set_script(MINIMAP_SCRIPT)
	get_tree().current_scene.add_child(minimap)
	minimap.setup([
		{"name": "Grocery Aisle", "rect": Rect2(0, 50, 500, 350)},
		{"name": "Fridge Bay", "rect": Rect2(550, 50, 500, 350)},
		{"name": "Freezer Bay", "rect": Rect2(1100, 50, 500, 350)},
		{"name": "Bakery", "rect": Rect2(0, 600, 500, 350)},
		{"name": "Deli", "rect": Rect2(550, 600, 500, 350)},
		{"name": "Checkout", "rect": Rect2(1100, 600, 500, 350)},
	], Rect2(0, 0, 1600, 1000), player)


const PLAY_AREA_MIN := Vector2(0, 0)
const PLAY_AREA_MAX := Vector2(1600, 1000)


func _add_decoration(path: String, pos: Vector2) -> void:
	var deco := Sprite2D.new()
	deco.texture = load(path)
	deco.position = pos
	$Decorations.add_child(deco)


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
	if timer_bar.visible and task_timer.wait_time > 0.0:
		timer_bar.value = task_timer.time_left / task_timer.wait_time
	if bake_container.visible and task_timer.wait_time > 0.0:
		var progress: float = 1.0 - (task_timer.time_left / task_timer.wait_time)
		var track_width: float = bake_container.custom_minimum_size.x
		bake_indicator.position.x = clamp(progress * track_width, 0.0, track_width - bake_indicator.size.x)


func _unhandled_input(event: InputEvent) -> void:
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
	shelf_prompt.visible = current_station == "shelf1"
	shelf2_prompt.visible = current_station == "shelf2"
	fridge1_prompt.visible = current_station == "fridge1"
	fridge2_prompt.visible = current_station == "fridge2"
	freezer1_prompt.visible = current_station == "freezer1"
	freezer2_prompt.visible = current_station == "freezer2"
	bakery_prompt.visible = current_station == "bakery"
	deli_prompt.visible = current_station == "deli"
	checkout_prompt.visible = current_station == "checkout"
	customer_prompt.visible = current_station == "customer"
	exit_prompt.visible = current_station == "exit"
	if task_active:
		return
	_set_hint("Press E to interact" if current_station != "" else "", 0.0)


# --- Task flow -------------------------------------------------------------

const RESTOCK_STATION_IDS := ["shelf1", "shelf2", "fridge1", "fridge2", "freezer1", "freezer2"]

func _start_task(station: String) -> void:
	if task_active:
		return
	if station in RESTOCK_STATION_IDS:
		station = "shelf"  # all 7 aisle points launch the same restock minigame,
							# which already covers all storage types generically
	current_task_type = station
	task_active = true
	round_index = 0
	round_correct = 0

	match station:
		"shelf":
			round_queue = WorkData.get_restock_round(RESTOCK_ROUNDS)
			title_label.text = "Restocking"
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

	_set_hint("")
	minigame_overlay.visible = true
	_show_step()


func _show_step() -> void:
	feedback_label.text = ""
	next_button.visible = false
	answered_current = false
	bake_container.visible = false
	mash_container.visible = false
	drag_container.visible = false
	type_container.visible = false
	num_pad.visible = false
	lookup_choices.visible = false
	type_submit_button.visible = true
	icon_row.visible = false
	timer_bar.visible = false
	holding_item = false
	type_submit_button.disabled = false
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
			var citem: Dictionary = round_queue[round_index]
			current_checkout_item = citem
			match citem.checkout_type:
				"scan":
					_show_checkout_scan(citem)
				"weigh":
					_show_checkout_weigh(citem)
				"lookup":
					_show_checkout_lookup(citem)

		"customer":
			var q: Dictionary = round_queue[round_index]
			info_label.text = q.question
			options_container.columns = 1
			var opts: Array = q.options
			for i in opts.size():
				var abtn := Button.new()
				abtn.text = opts[i]
				abtn.custom_minimum_size = Vector2(420, 52)
				abtn.add_theme_font_size_override("font_size", 18)
				abtn.pressed.connect(_on_untimed_choice.bind(i == q.correct))
				options_container.add_child(abtn)


# --- Checkout: three genuinely different interactions depending on the item -

## Barcode items: freely drag the item (both X and Y) onto a scanner target
## that appears at a random spot each time.
## Barcode items: click Pick Up to hold the item, then click SCAN to run it
## across the scanner. Click-based rather than drag-based — dragging silently
## failed because the overlay panel swallowed mouse-motion events before the
## scene script ever saw them.
func _show_checkout_scan(item: Dictionary) -> void:
	timer_bar.visible = true
	drag_container.visible = true
	zone_grid.columns = 1
	zone1.visible = true
	zone2.visible = false
	zone3.visible = false
	zone1.text = "SCAN IT"
	drag_item.texture = load(item.texture)
	held_label.text = item.name
	pick_up_button.text = "Pick Up %s" % item.name
	pick_up_button.visible = true
	pick_up_button.disabled = false
	zone1.disabled = true
	holding_item = false
	drag_context = "checkout_scan"
	info_label.text = "%s — $%.2f\nPick it up, then run it over the scanner." % [item.name, item.price]
	options_container.columns = 1
	_start_timer(CHECKOUT_SCAN_TIME_LIMIT)


func _show_checkout_weigh(item: Dictionary) -> void:
	icon_row.visible = true
	timer_bar.visible = true
	type_container.visible = true
	target_icon.texture = load(item.texture)
	type_prompt_label.text = "Weigh out %.2fkg of %s" % [item.target_weight, item.name]
	type_input.text = ""
	type_input.placeholder_text = "Type the weight in kg"
	info_label.text = "$%.2f/kg — tap in the weight, then Submit" % item.price
	options_container.columns = 1
	num_pad.visible = true
	lookup_choices.visible = false
	type_submit_button.visible = true
	type_input.editable = true
	_build_num_pad()
	_start_timer(CHECKOUT_TYPE_TIME_LIMIT)


## No barcode: type the item's name from memory.
func _show_checkout_lookup(item: Dictionary) -> void:
	icon_row.visible = true
	timer_bar.visible = true
	type_container.visible = true
	target_icon.texture = load(item.texture)
	type_prompt_label.text = "No barcode found! What's this item called?"
	type_input.text = ""
	type_input.placeholder_text = "Type the item's name"
	info_label.text = "$%.2f — pick the right item" % item.price
	options_container.columns = 1
	num_pad.visible = false
	lookup_choices.visible = true
	type_submit_button.visible = false
	type_input.editable = false
	type_input.text = ""
	_build_lookup_choices(item)
	_start_timer(CHECKOUT_TYPE_TIME_LIMIT)


## An on-screen number pad, so weighing doesn't depend on the keyboard —
## testers found typing mid-task fiddly.
func _build_num_pad() -> void:
	for child in num_pad.get_children():
		child.queue_free()
	for key in ["7", "8", "9", "⌫", "4", "5", "6", ".", "1", "2", "3", "C", "0", "00"]:
		var b := Button.new()
		b.text = key
		b.custom_minimum_size = Vector2(72, 52)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_on_num_pad_pressed.bind(key))
		num_pad.add_child(b)


func _on_num_pad_pressed(key: String) -> void:
	if answered_current:
		return
	match key:
		"C":
			type_input.text = ""
		"⌫":
			type_input.text = type_input.text.substr(0, max(0, type_input.text.length() - 1))
		_:
			type_input.text += key


## Multiple-choice for no-barcode items, rather than typing a name blind.
func _build_lookup_choices(item: Dictionary) -> void:
	for child in lookup_choices.get_children():
		child.queue_free()
	for name in WorkData.get_lookup_options(item.name):
		var b := Button.new()
		b.text = name
		b.custom_minimum_size = Vector2(340, 48)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_lookup_choice.bind(name))
		lookup_choices.add_child(b)


func _on_lookup_choice(chosen: String) -> void:
	if answered_current:
		return
	task_timer.stop()
	_resolve_step(chosen == current_checkout_item.name)


func _on_type_submit() -> void:
	if answered_current or not type_container.visible:
		return
	var typed: String = type_input.text.strip_edges()
	var is_correct: bool = false
	match current_checkout_item.checkout_type:
		"weigh":
			var typed_val: float = typed.to_float()
			is_correct = absf(typed_val - float(current_checkout_item.target_weight)) <= WEIGH_TOLERANCE
		"lookup":
			is_correct = typed.to_lower() == current_checkout_item.name.to_lower()
	task_timer.stop()
	_resolve_step(is_correct)


# --- Restocking: open the box, see what's inside, drag it to the correct
# storage (Shelf / Fridge / Freezer). Fill the meter with several units of
# the same item before moving on to the next round.

func _show_restock_step() -> void:
	mash_container.visible = true
	timer_bar.visible = true
	drag_container.visible = true
	zone_grid.columns = 3
	zone1.visible = true
	zone2.visible = true
	zone3.visible = true
	zone1.text = "SHELF"
	zone2.text = "FRIDGE"
	zone3.text = "FREEZER"

	restock_fill = 0
	restock_target_item = {}   # picked fresh per box in _reset_restock_box()
	mash_meter.max_value = RESTOCK_FILL_TARGET
	mash_meter.value = 0
	drag_context = "restock"
	options_container.columns = 1
	_reset_restock_box()
	_start_timer(RESTOCK_TIME_LIMIT)


## Shows a fresh unopened box. You click Open Box to see what's inside, then
## click whichever storage zone that item belongs in.
func _reset_restock_box() -> void:
	# Draw a different item for every box, so a shift isn't four identical
	# deliveries in a row. Avoids repeating the item you just did.
	var pool: Array = WorkData._restock_items
	var previous_name: String = str(restock_target_item.get("name", ""))
	var pick: Dictionary = pool[randi() % pool.size()]
	if pool.size() > 1:
		var guard: int = 0
		while str(pick.get("name", "")) == previous_name and guard < 8:
			pick = pool[randi() % pool.size()]
			guard += 1
	restock_target_item = pick

	restock_box_opened = false
	holding_item = false
	drag_item.texture = load(BOX_CLOSED_TEXTURE)
	held_label.text = "Sealed box"
	pick_up_button.text = "Open Box"
	pick_up_button.visible = true
	pick_up_button.disabled = false
	_set_zones_disabled(true)
	info_label.text = "A delivery box has arrived! (%d / %d stocked)" % [restock_fill, RESTOCK_FILL_TARGET]


func _on_open_box() -> void:
	restock_box_opened = true
	holding_item = true
	drag_item.texture = load(restock_target_item.texture)
	held_label.text = restock_target_item.name
	pick_up_button.disabled = true
	_set_zones_disabled(false)
	info_label.text = "It's %s! Where does it go?" % restock_target_item.name


func _set_zones_disabled(is_disabled: bool) -> void:
	zone1.disabled = is_disabled
	zone2.disabled = is_disabled
	zone3.disabled = is_disabled


## Pick Up doubles as "Open Box" during restocking, since both are the same
## "reveal / ready the item" beat before you choose where it goes.
func _on_pick_up_pressed() -> void:
	if answered_current:
		return
	match drag_context:
		"restock":
			if not restock_box_opened:
				_on_open_box()
		"checkout_scan":
			holding_item = true
			pick_up_button.disabled = true
			zone1.disabled = false
			info_label.text = "Holding %s — now run it over the scanner." % current_checkout_item.name


## A storage/scanner zone was clicked. index: 0 = shelf/scan, 1 = fridge, 2 = freezer.
func _on_zone_pressed(index: int) -> void:
	if answered_current or not holding_item:
		return

	match drag_context:
		"checkout_scan":
			Audio.play("scan_beep")
			task_timer.stop()
			_resolve_step(true)

		"restock":
			var keys := ["shelf", "fridge", "freezer"]
			if keys[index] == restock_target_item.storage:
				restock_fill += 1
				mash_meter.value = restock_fill
				if restock_fill >= RESTOCK_FILL_TARGET:
					task_timer.stop()
					_resolve_step(true)
				else:
					Audio.play("stock_place")
					feedback_label.text = "Nice, in it goes!"
					_reset_restock_box()
			else:
				feedback_label.text = "%s doesn't go in the %s — try again!" % [restock_target_item.name, keys[index]]



func _show_precision_step(item: Dictionary, verb: String, message: String) -> void:
	icon_row.visible = true
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
	action_btn.custom_minimum_size = Vector2(220, 64)  # bigger target — testers found small buttons fiddly
	action_btn.add_theme_font_size_override("font_size", 22)
	action_btn.pressed.connect(_on_bake_take_out.bind(zone_start))
	options_container.add_child(action_btn)
	# Randomise how fast the marker sweeps, so every round plays differently
	# rather than being the same memorised timing each time.
	_start_timer(randf_range(BAKE_TIME_LIMIT * 0.6, BAKE_TIME_LIMIT * 1.8))


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
	mash_btn.custom_minimum_size = Vector2(220, 64)
	mash_btn.add_theme_font_size_override("font_size", 22)
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
	Audio.play("correct" if is_correct else "wrong")
	if is_correct:
		round_correct += 1
		feedback_label.text = "Nice one!"
	else:
		feedback_label.text = "Missed that one."
	for child in options_container.get_children():
		if child is BaseButton:
			child.disabled = true
	type_submit_button.disabled = true
	holding_item = false
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
	_set_hint("%s done: %d / %d correct" % [current_task_type.capitalize(), round_correct, round_queue.size()])


# --- Shift end ---------------------------------------------------------------

func _end_shift() -> void:
	if task_active:
		return
	if shift_hours <= 0.0:
		_set_hint("Do at least one task before clocking out!")
		return

	var performance: float = 0.0 if shift_task_total == 0 else float(shift_task_score) / float(shift_task_total)
	Audio.play("cash")
	GameBackend.complete_work_shift(shift_hours, performance)
	# If you'd agreed to this shift, turning up clears the booking. Not
	# turning up is handled by GameBackend._check_missed_commitments() when
	# the day rolls over — that's where the no-show counter lives.
	GameBackend.fulfil_commitment("work")

	results_label.text = "Shift complete!\nHours worked: %.1f\nTasks: %d / %d correct\nTotal money: $%.2f" % [
		shift_hours, shift_task_score, shift_task_total, GameBackend.money
	]
	results_panel.visible = true
	money_label.text = "Money: $%.2f" % GameBackend.money

	shift_hours = 0.0
	shift_task_score = 0
	shift_task_total = 0


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
