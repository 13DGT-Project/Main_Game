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

@onready var shelf_area: Area2D = $ShelfStation/InteractArea
@onready var shelf_prompt: Label = $ShelfStation/PromptLabel
@onready var exit_area: Area2D = $ExitStation/InteractArea
@onready var exit_prompt: Label = $ExitStation/PromptLabel

@onready var hint_panel: PanelContainer = $CanvasLayer/HUD/HintPanel
@onready var hint_label: Label = $CanvasLayer/HUD/HintPanel/HintLabel
@onready var minigame_overlay: Control = $CanvasLayer/MinigameOverlay
@onready var info_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/InfoLabel
@onready var options_container: VBoxContainer = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/OptionsCenter/OptionsContainer
@onready var feedback_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/FeedbackLabel
@onready var title_label: Label = $CanvasLayer/MinigameOverlay/CenterContainer/Panel/VBoxContainer/TitleLabel

## Ravi runs the dairy. He's the same Ravi who texts you about leaving your
## student ID on his counter. Talk to him enough and be decent about it, and
## you get mate's rates.
const RAVI_TEXTURE := preload("res://Backend/Resource/Textures/ravi.png")
const COUNTER_TEXTURE := preload("res://Backend/Resource/Textures/checkout_counter.png")
const RAVI_POS := Vector2(170, 190)
const MATES_RATES: float = 0.85
const HELP_HOURS: float = 2.0

var ravi_prompt: Label
var _convo: Dictionary = {}
var _convo_step: int = 0
var _convo_sanity: float = 0.0

var current_station: String = ""
var _hint_time_left: float = 0.0
var task_active: bool = false


func _ready() -> void:
	Audio.play_ambience("work")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	shelf_area.body_entered.connect(_on_station_entered.bind("shelf"))
	shelf_area.body_exited.connect(_on_station_exited.bind("shelf"))
	exit_area.body_entered.connect(_on_station_entered.bind("exit"))
	exit_area.body_exited.connect(_on_station_exited.bind("exit"))
	_build_ravi()
	GameBackend.remember_place("dairy")

	GameBackend.game_ended.connect(_on_game_ended)
	get_tree().current_scene.add_child(JOURNAL_SCENE.instantiate())
	get_tree().current_scene.add_child(GUI_SCENE.instantiate())
	get_tree().current_scene.add_child(PAUSE_MENU_SCENE.instantiate())

	if not _is_dairy_open():
		_show_closed_message()


## Ravi, his counter, and the spot where you can talk to him. Built here so
## the scene file doesn't need editing.
func _build_ravi() -> void:
	var station := Node2D.new()
	station.name = "RaviStation"
	station.position = RAVI_POS
	add_child(station)
	move_child(station, player.get_index())

	var ravi := Sprite2D.new()
	ravi.texture = RAVI_TEXTURE
	ravi.position = Vector2(0, -34)
	ravi.scale = Vector2(1.15, 1.15)
	station.add_child(ravi)

	var counter := Sprite2D.new()
	counter.texture = COUNTER_TEXTURE
	counter.scale = Vector2(0.62, 0.55)
	counter.position = Vector2(0, 8)
	station.add_child(counter)

	var name_tag := Label.new()
	name_tag.text = GameBackend.contact_name("Ravi")
	name_tag.position = Vector2(-60, -98)
	name_tag.custom_minimum_size = Vector2(120, 0)
	name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_tag.add_theme_font_size_override("font_size", 14)
	name_tag.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	name_tag.add_theme_constant_override("outline_size", 4)
	station.add_child(name_tag)

	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(190, 150)
	shape.shape = rect
	shape.position = Vector2(0, 40)
	area.add_child(shape)
	station.add_child(area)
	area.body_entered.connect(_on_station_entered.bind("ravi"))
	area.body_exited.connect(_on_station_exited.bind("ravi"))

	ravi_prompt = Label.new()
	ravi_prompt.text = tr("PROMPT_TALK_RAVI")
	ravi_prompt.position = Vector2(-110, -124)
	ravi_prompt.custom_minimum_size = Vector2(220, 0)
	ravi_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ravi_prompt.visible = false
	station.add_child(ravi_prompt)


func _is_dairy_open() -> bool:
	var hour: int = int(GameBackend.game_hour)
	return hour >= 15 or hour < 7


func _show_closed_message() -> void:
	task_active = true
	feedback_label.text = ""
	for child in options_container.get_children():
		child.queue_free()
	info_label.text = tr("SHOP_DAIRY_CLOSED")
	var leave_btn := Button.new()
	leave_btn.text = tr("SHOP_HEAD_OUT")
	leave_btn.pressed.connect(func(): get_tree().change_scene_to_file(MAIN_MAP_SCENE))
	options_container.add_child(leave_btn)
	minigame_overlay.visible = true


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
		elif current_station == "ravi":
			_open_ravi()
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
	shelf_prompt.visible = current_station == "shelf"
	exit_prompt.visible = current_station == "exit"
	if ravi_prompt != null:
		ravi_prompt.visible = current_station == "ravi"
	if not task_active:
		_set_hint(tr("PROMPT_INTERACT") if current_station != "" else "", 0.0)


func _open_menu() -> void:
	task_active = true
	feedback_label.text = ""
	title_label.text = tr("SHOP_DAIRY")
	info_label.text = tr("SHOP_DAIRY_Q")
	if GameBackend.has_flag("ravi_friend"):
		info_label.text += "\n" + tr("RAVI_MATES_RATES")
	_clear_options()

	var items: Array = WorkData.pick_menu(WorkData.DAIRY_MENU, 8)
	for item in items:
		var ibtn := Button.new()
		var price: float = float(item.cost) * (MATES_RATES if GameBackend.has_flag("ravi_friend") else 1.0)
		ibtn.text = tr("SHOP_ITEM_PRICE") % [tr(str(item.label)), snappedf(price, 0.1)]
		ibtn.pressed.connect(_on_buy.bind(item))
		options_container.add_child(ibtn)

	var cancel_btn := Button.new()
	cancel_btn.text = tr("SHOP_NEVER_MIND")
	cancel_btn.pressed.connect(_close_menu)
	options_container.add_child(cancel_btn)

	_set_hint("")
	minigame_overlay.visible = true


func _on_buy(item: Dictionary) -> void:
	var cost: float = float(item.cost)
	if GameBackend.has_flag("ravi_friend"):
		cost = snappedf(cost * MATES_RATES, 0.1)
	var success: bool = GameBackend.cook_meal(cost, item.energy, item.thirst, item.sanity, 0.1)
	minigame_overlay.visible = false
	task_active = false
	if success:
		_set_hint(tr("SHOP_BOUGHT") % tr(str(item.label)))
	else:
		_set_hint(tr("SHOP_NO_MONEY"))


func _close_menu() -> void:
	minigame_overlay.visible = false
	task_active = false


# --- Ravi ------------------------------------------------------------------------

func _clear_options() -> void:
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()


func _add_option(text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(440, 44)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(action)
	options_container.add_child(b)


func _open_ravi() -> void:
	task_active = true
	feedback_label.text = ""
	title_label.text = GameBackend.contact_name("Ravi")
	GameBackend.ravi_visits += 1
	info_label.text = SchoolData.get_ravi_greeting(GameBackend.player_name)
	_ravi_menu()
	_set_hint("")
	minigame_overlay.visible = true


func _ravi_menu() -> void:
	_clear_options()
	if GameBackend.has_commitment_today("dairy_help"):
		_add_option(tr("RAVI_MIND_SHOP"), _mind_the_shop)
	_add_option(tr("RAVI_CHAT"), _start_ravi_chat)
	_add_option(tr("RAVI_BUY"), _open_menu)
	_add_option(tr("RAVI_BYE"), _close_menu)


## The favour he asked for by text: two hours behind the counter.
func _mind_the_shop() -> void:
	GameBackend.advance_time(HELP_HOURS)
	GameBackend.fulfil_commitment("dairy_help")
	GameBackend.set_flag("ravi_friend")
	info_label.text = tr("RAVI_SHOP_DONE")
	_clear_options()
	_add_option(tr("RAVI_BYE"), _close_menu)


func _start_ravi_chat() -> void:
	_convo = SchoolData.get_ravi_conversation(GameBackend.player_name)
	_convo_step = 0
	_convo_sanity = 0.0
	_show_ravi_step()


func _show_ravi_step() -> void:
	if _convo.is_empty() or _convo_step < 0 or _convo_step >= _convo.steps.size():
		_finish_ravi_chat()
		return
	var step: Dictionary = _convo.steps[_convo_step]
	info_label.text = str(step.them)
	_clear_options()
	for reply in step.replies:
		_add_option(str(reply.text), _on_ravi_reply.bind(reply))


func _on_ravi_reply(reply: Dictionary) -> void:
	Audio.play("click")
	_convo_sanity += float(reply.get("sanity", 0.0))
	var note: String = GameBackend.apply_reply_effects(reply)
	if note != "":
		feedback_label.text = note
	var next: int = SchoolData.next_step_for(reply, _convo_step)
	if next >= _convo.steps.size() or bool(reply.get("ends", false)):
		_finish_ravi_chat()
		return
	_convo_step = next
	_show_ravi_step()


func _finish_ravi_chat() -> void:
	GameBackend.socialize(max(0.0, _convo_sanity), 0.25, 0.0)
	# A few proper chats and he's decided you're alright.
	if GameBackend.seen_conversations.size() > 0:
		var ravi_chats: int = 0
		for id in GameBackend.seen_conversations:
			if str(id).begins_with("ravi_"):
				ravi_chats += int(GameBackend.seen_conversations[id])
		if ravi_chats >= 3 and not GameBackend.has_flag("ravi_friend"):
			GameBackend.set_flag("ravi_friend")
			feedback_label.text = tr("RAVI_NOW_FRIENDS")
	info_label.text = SchoolData.get_ravi_signoff()
	_clear_options()
	_add_option(tr("RAVI_BUY"), _open_menu)
	_add_option(tr("RAVI_BYE"), _close_menu)


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
