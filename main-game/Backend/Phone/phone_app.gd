## phone_app.gd
## Root script for phone_app.tscn, registered as the "PhoneApp" autoload.
## Call PhoneApp.toggle() (each scene's _use_selected_item() does this if the
## selected hotbar slot holds the Phone) to open/close it. Works from any
## scene since it's an autoload, same pattern as the Inventory/hotbar UI.
extends CanvasLayer

@onready var panel: Control = $Panel
@onready var screen: Control = $Panel/CenterContainer/PhoneBody/Screen

@onready var home_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen
@onready var chirp_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/ChirpButton
@onready var messages_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/MessagesButton
@onready var bank_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/BankButton
@onready var weather_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/WeatherButton
@onready var close_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/CloseButton

@onready var doomscroll_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/DoomscrollScreen
@onready var feed_container: VBoxContainer = $Panel/CenterContainer/PhoneBody/Screen/DoomscrollScreen/FeedScroll/FeedContainer
@onready var keep_scrolling_button: Button = $Panel/CenterContainer/PhoneBody/Screen/DoomscrollScreen/KeepScrollingButton
@onready var doomscroll_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/DoomscrollScreen/DoomscrollBackButton

@onready var bank_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/BankScreen
@onready var bank_summary_label: Label = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/SummaryLabel
@onready var bank_amount_input: LineEdit = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/AmountInput
@onready var deposit_button: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/DepositButton
@onready var withdraw_button: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/WithdrawButton
@onready var term_deposit_button: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/TermDepositButton
@onready var bank_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/BankBackButton

@onready var cash_1: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/QuickCashGrid/Cash1
@onready var cash_5: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/QuickCashGrid/Cash5
@onready var cash_10: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/QuickCashGrid/Cash10
@onready var cash_20: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/QuickCashGrid/Cash20
@onready var cash_50: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/QuickCashGrid/Cash50
@onready var cash_100: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/QuickCashGrid/Cash100
@onready var cash_max: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/QuickCashGrid/CashMax
@onready var cash_clear: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/QuickCashGrid/CashClear

@onready var messages_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen
@onready var sender_label: Label = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/SenderLabel
@onready var message_label: Label = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/MessageLabel
@onready var reply_button: Button = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/ReplyButton
@onready var messages_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/MessagesBackButton

@onready var weather_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/WeatherScreen
@onready var weather_label: Label = $Panel/CenterContainer/PhoneBody/Screen/WeatherScreen/WeatherLabel
@onready var weather_detail_label: Label = $Panel/CenterContainer/PhoneBody/Screen/WeatherScreen/WeatherDetailLabel
@onready var weather_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/WeatherScreen/WeatherBackButton

var _feed_posts: Array = [
	{"user": "@lunchline_leaks", "text": "you won't believe what happened at lunch today..."},
	{"user": "@daily.pics", "text": "27 people liked a photo of someone's lunch."},
	{"user": "@studytok", "text": "study tips that ACTUALLY work (number 4 will shock you)"},
	{"user": "@groupchat_drama", "text": "a group chat is arguing about something that doesn't matter."},
	{"user": "@dogsofthetown", "text": "someone's dog did a trick. It's fine. It's a fine trick."},
	{"user": "@5am.club", "text": "\"5am productivity routine of a top student\" — 14 minutes long."},
	{"user": "@repost_central", "text": "reposted, reposted again, reposted a third time."},
	{"user": "@earworm", "text": "this song will be stuck in your head for the rest of the day."},
	{"user": "@examseason", "text": "\"how I got 5 NCEA excellences while also sleeping\" (lying)"},
	{"user": "@townnews", "text": "local dairy apparently now stocks a new flavour of chips."},
	{"user": "@overheard", "text": "\"overheard in the library\" thread has 400 replies now."},
	{"user": "@weekendplans", "text": "someone's asking if anyone's free Saturday. 40 replies, no plans made."},
]

var _message_threads: Array = [
	{"sender": "Mum", "lines": ["hey hun, you eating properly? text me back", "love you, good luck with everything"]},
	{"sender": "Study group chat", "lines": ["is anyone actually prepared for this", "asking for a friend (me)"]},
	{"sender": "Best friend", "lines": ["ok but are we still doing something this weekend", "no pressure just checking in"]},
	{"sender": "Unknown number", "lines": ["hey it's me from maths class, got the notes from today?"]},
	{"sender": "Dad", "lines": ["how'd the test go", "proud of you either way"]},
]

var _weather_options: Array = [
	{"icon": "☀️", "detail": "Sunny and clear. A good day to walk to school instead of catching the bus."},
	{"icon": "🌧️", "detail": "Rain most of the day. Don't forget a jacket — or just accept getting damp."},
	{"icon": "⛅", "detail": "Partly cloudy, mild. Nothing to plan around either way."},
	{"icon": "🌬️", "detail": "Windy. Hold onto your papers if you're walking anywhere outside."},
	{"icon": "🌫️", "detail": "Foggy this morning, clearing up by midday."},
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_show_home()

	chirp_button.pressed.connect(_open_chirp)
	messages_button.pressed.connect(_open_messages)
	bank_button.pressed.connect(_open_bank)
	weather_button.pressed.connect(_open_weather)
	close_button.pressed.connect(close)

	keep_scrolling_button.pressed.connect(_refresh_feed)
	doomscroll_back_button.pressed.connect(_show_home)

	deposit_button.pressed.connect(_on_deposit_pressed)
	withdraw_button.pressed.connect(_on_withdraw_pressed)
	term_deposit_button.pressed.connect(_on_term_deposit_pressed)
	bank_back_button.pressed.connect(_show_home)

	cash_1.pressed.connect(_add_quick_cash.bind(1.0))
	cash_5.pressed.connect(_add_quick_cash.bind(5.0))
	cash_10.pressed.connect(_add_quick_cash.bind(10.0))
	cash_20.pressed.connect(_add_quick_cash.bind(20.0))
	cash_50.pressed.connect(_add_quick_cash.bind(50.0))
	cash_100.pressed.connect(_add_quick_cash.bind(100.0))
	cash_max.pressed.connect(_set_amount_to_max)
	cash_clear.pressed.connect(_clear_amount)

	reply_button.pressed.connect(_on_reply_pressed)
	messages_back_button.pressed.connect(_show_home)
	weather_back_button.pressed.connect(_show_home)

	GameBackend.stats_changed.connect(_refresh_bank_summary)


func toggle() -> void:
	if panel.visible:
		close()
	else:
		open()


func open() -> void:
	panel.visible = true
	_show_home()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	panel.visible = false


func _hide_all_screens() -> void:
	home_screen.visible = false
	doomscroll_screen.visible = false
	bank_screen.visible = false
	messages_screen.visible = false
	weather_screen.visible = false


func _show_home() -> void:
	_hide_all_screens()
	home_screen.visible = true


# --- Chirp (fake social feed) ------------------------------------------------

func _open_chirp() -> void:
	_hide_all_screens()
	doomscroll_screen.visible = true
	_populate_feed()


func _populate_feed() -> void:
	for child in feed_container.get_children():
		child.queue_free()
	var shuffled: Array = _feed_posts.duplicate()
	shuffled.shuffle()
	for post in shuffled.slice(0, 6):
		var post_panel := PanelContainer.new()
		var post_box := VBoxContainer.new()
		post_box.add_theme_constant_override("separation", 2)
		var user_label := Label.new()
		user_label.text = post.user
		user_label.add_theme_font_size_override("font_size", 14)
		var text_label := Label.new()
		text_label.text = post.text
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		post_box.add_child(user_label)
		post_box.add_child(text_label)
		post_panel.add_child(post_box)
		feed_container.add_child(post_panel)


## "Refresh Feed" — unlike scrolling through what's already loaded (free),
## asking for more content is the part that actually costs you.
func _refresh_feed() -> void:
	GameBackend.doomscroll()
	_populate_feed()


# --- Bank ----------------------------------------------------------------------

func _open_bank() -> void:
	_hide_all_screens()
	bank_screen.visible = true
	_refresh_bank_summary()


func _refresh_bank_summary() -> void:
	if not bank_screen.visible:
		return
	var deposit_text: String = "none"
	if GameBackend.term_deposit_amount > 0.0:
		deposit_text = "$%.2f (%d days left)" % [GameBackend.term_deposit_amount, GameBackend.term_deposit_days_left]
	bank_summary_label.text = "Wallet: $%.2f\nSavings: $%.2f (grows daily)\nTerm deposit: %s" % [
		GameBackend.money, GameBackend.savings_balance, deposit_text
	]


func _get_amount_input() -> float:
	return max(0.0, bank_amount_input.text.to_float())


func _add_quick_cash(amount: float) -> void:
	bank_amount_input.text = str(_get_amount_input() + amount)


func _set_amount_to_max() -> void:
	bank_amount_input.text = str(GameBackend.money)


func _clear_amount() -> void:
	bank_amount_input.text = ""


func _on_deposit_pressed() -> void:
	GameBackend.deposit_savings(_get_amount_input())
	bank_amount_input.text = ""
	_refresh_bank_summary()


func _on_withdraw_pressed() -> void:
	GameBackend.withdraw_savings(_get_amount_input())
	bank_amount_input.text = ""
	_refresh_bank_summary()


func _on_term_deposit_pressed() -> void:
	GameBackend.start_term_deposit(_get_amount_input())
	bank_amount_input.text = ""
	_refresh_bank_summary()


# --- Messages ------------------------------------------------------------------

var _current_thread: Dictionary = {}

func _open_messages() -> void:
	_hide_all_screens()
	messages_screen.visible = true
	_current_thread = _message_threads[randi() % _message_threads.size()]
	sender_label.text = _current_thread.sender
	message_label.text = "\n".join(_current_thread.lines)
	reply_button.disabled = false


## A quick text back to a friend/family member — small sanity relief, barely
## any time, unlike sitting down for a full chat in person.
func _on_reply_pressed() -> void:
	GameBackend.socialize(4.0, 0.05, 1.0)
	reply_button.disabled = true
	message_label.text += "\n\nYou: sorry, been busy — talk soon!"


# --- Weather (pure flavour, no gameplay effect) --------------------------------

func _open_weather() -> void:
	_hide_all_screens()
	weather_screen.visible = true
	var w: Dictionary = _weather_options[randi() % _weather_options.size()]
	weather_label.text = w.icon
	weather_detail_label.text = w.detail
