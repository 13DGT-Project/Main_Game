## Call PhoneApp.toggle() (each scene's _use_selected_item() does this if the
## selected hotbar slot holds the Phone) to open/close it. Works from any
## scene since it's an autoload, same pattern as the Inventory/hotbar UI.
extends CanvasLayer

@onready var panel: Control = $Panel
@onready var screen: Control = $Panel/CenterContainer/PhoneBody/Screen

@onready var home_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen
@onready var chirp_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/AppGridHolder/AppGrid/ChirpButton
@onready var messages_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/AppGridHolder/AppGrid/MessagesButton
@onready var bank_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/AppGridHolder/AppGrid/BankButton
@onready var weather_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/AppGridHolder/AppGrid/WeatherButton
@onready var close_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeBar/CloseButton
## Phone chrome: wallpaper on the home screen, a plain background inside apps,
## the clock/date and the status bar time.
@onready var wallpaper: TextureRect = $Panel/CenterContainer/PhoneBody/Screen/Wallpaper
@onready var app_background: TextureRect = $Panel/CenterContainer/PhoneBody/Screen/AppBackground
@onready var status_time_label: Label = $Panel/CenterContainer/PhoneBody/Screen/StatusBar/TimeLabel
@onready var clock_label: Label = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/TitleLabel
@onready var date_label: Label = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/DateLabel

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
@onready var inbox_view: VBoxContainer = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/InboxView
@onready var inbox_list: VBoxContainer = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/InboxView/InboxScroll/InboxList
@onready var inbox_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/InboxView/InboxBackButton
@onready var thread_view: VBoxContainer = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/ThreadView
@onready var sender_label: Label = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/ThreadView/SenderLabel
@onready var thread_scroll: ScrollContainer = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/ThreadView/ThreadScroll
@onready var bubbles: VBoxContainer = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/ThreadView/ThreadScroll/Bubbles
@onready var reply_container: VBoxContainer = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/ThreadView/ReplyContainer
@onready var messages_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/MessagesScreen/ThreadView/MessagesBackButton

@onready var weather_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/WeatherScreen
@onready var weather_label: Label = $Panel/CenterContainer/PhoneBody/Screen/WeatherScreen/WeatherLabel
@onready var weather_detail_label: Label = $Panel/CenterContainer/PhoneBody/Screen/WeatherScreen/WeatherDetailLabel
@onready var weather_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/WeatherScreen/WeatherBackButton

@onready var games_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/AppGridHolder/AppGrid/GamesButton
@onready var games_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/GamesScreen
@onready var game_info_label: Label = $Panel/CenterContainer/PhoneBody/Screen/GamesScreen/GameInfoLabel
@onready var game_score_label: Label = $Panel/CenterContainer/PhoneBody/Screen/GamesScreen/GameScoreLabel
@onready var game_grid: GridContainer = $Panel/CenterContainer/PhoneBody/Screen/GamesScreen/GameGrid
@onready var game_start_button: Button = $Panel/CenterContainer/PhoneBody/Screen/GamesScreen/GameStartButton
@onready var games_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/GamesScreen/GamesBackButton

## The unread badge sitting on the Messages app icon.
var _messages_badge: Control = null

var _feed_posts: Array = [
	{"user": "@lunchline_leaks", "text": "CHIRP_POST_0"},
	{"user": "@daily.pics", "text": "CHIRP_POST_1"},
	{"user": "@studytok", "text": "CHIRP_POST_2"},
	{"user": "@groupchat_drama", "text": "CHIRP_POST_3"},
	{"user": "@dogsofthetown", "text": "CHIRP_POST_4"},
	{"user": "@5am.club", "text": "CHIRP_POST_5"},
	{"user": "@repost_central", "text": "CHIRP_POST_6"},
	{"user": "@earworm", "text": "CHIRP_POST_7"},
	{"user": "@examseason", "text": "CHIRP_POST_8"},
	{"user": "@townnews", "text": "CHIRP_POST_9"},
	{"user": "@overheard", "text": "CHIRP_POST_10"},
	{"user": "@weekendplans", "text": "CHIRP_POST_11"},
]

## Multi-turn threads. Each step: what they said, then your reply options.
## Picking one advances to the next step
## Ten threads of varying length (2-4 exchanges). Each step can carry a
## `from` field — used by group chats so individual people speak, rather than
## every line being attributed to the chat itself.
var _weather_options: Array = [
	{"icon": "☀️", "detail": "WEATHER_0"},
	{"icon": "🌧️", "detail": "WEATHER_1"},
	{"icon": "⛅", "detail": "WEATHER_2"},
	{"icon": "🌬️", "detail": "WEATHER_3"},
	{"icon": "🌫️", "detail": "WEATHER_4"},
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_show_home()

	chirp_button.pressed.connect(_open_chirp)
	messages_button.pressed.connect(_open_messages)
	bank_button.pressed.connect(_open_bank)
	weather_button.pressed.connect(_open_weather)
	close_button.pressed.connect(_on_home_bar_pressed)

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

	messages_back_button.pressed.connect(_finish_thread)
	inbox_back_button.pressed.connect(_show_home)
	weather_back_button.pressed.connect(_show_home)
	games_button.pressed.connect(_open_games)
	games_back_button.pressed.connect(_end_game_and_go_home)
	game_start_button.pressed.connect(_on_game_start_pressed)

	GameBackend.stats_changed.connect(_refresh_bank_summary)
	GameBackend.game_ended.connect(_on_game_ended)
	GameBackend.messages_changed.connect(_refresh_messages_badge)
	GameBackend.message_arrived.connect(_on_message_arrived_live)
	Audio.attach_click_sounds(self)

	# The red circle on the Messages app icon. Notifier owns it, so it can
	# never drift out of sync with the one on the hotbar.
	_messages_badge = Notifier.attach_message_badge(messages_button, 22.0, Vector2(-14, -2))
	_refresh_messages_badge()


## Keeps the Messages icon
func _refresh_messages_badge() -> void:
	var n: int = GameBackend.unread_count
	if _messages_badge != null and is_instance_valid(_messages_badge):
		Notifier.set_badge_count(_messages_badge, n)
	# The red badge on the icon shows the count, like a real phone.
	if is_instance_valid(messages_button):
		messages_button.text = tr("PHONE_MESSAGES")


## If a text lands from the person whose chat is already open and you've
## finished everything else they've said, it appears right there — no going
## back to the inbox and in again.
func _on_message_arrived_live(_sender: String, thread_id: String) -> void:
	if _active_contact == "" or not thread_view.visible:
		return
	if GameBackend.contact_name_for(thread_id) != _active_contact:
		return
	# The reply you were waiting for, in the chat you have open.
	if thread_id == _active_thread_id and not GameBackend.is_done(thread_id):
		GameBackend.mark_read(thread_id)
		_show_thread_step()
		return
	if _active_thread_id != "" and not GameBackend.is_done(_active_thread_id):
		return   # mid-conversation; it'll be picked up when this one ends
	GameBackend.mark_read(thread_id)
	var prev_day: int = GameBackend.arrived_on_day(_active_thread_id) if _active_thread_id != "" else -999
	_start_thread(thread_id, prev_day)


func toggle() -> void:
	if panel.visible:
		close()
	else:
		open()


func open() -> void:
	Audio.play("open")
	panel.visible = true
	_show_home()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	Audio.play("close")
	panel.visible = false
	# A game left running in a closed phone would keep scoring (and spending
	# your time) in the background.
	if _game != "":
		_show_arcade()


func _hide_all_screens() -> void:
	# Inside an app: plain background, and the home bar takes you home.
	wallpaper.visible = false
	app_background.visible = true
	close_button.text = tr("PHONE_BACK_HOME")
	home_screen.visible = false
	doomscroll_screen.visible = false
	bank_screen.visible = false
	messages_screen.visible = false
	weather_screen.visible = false
	games_screen.visible = false


func _show_home() -> void:
	_hide_all_screens()
	home_screen.visible = true
	wallpaper.visible = true
	app_background.visible = false
	close_button.text = tr("PHONE_PUT_AWAY")
	_update_clock()
	# The label is first set at startup, before a language is picked.
	_refresh_messages_badge()


#Chirp (fake social feed)

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
		text_label.text = tr(str(post.text))
		text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		post_box.add_child(user_label)
		post_box.add_child(text_label)
		post_panel.add_child(post_box)
		feed_container.add_child(post_panel)


## "Refresh Feed" 
func _refresh_feed() -> void:
	GameBackend.doomscroll()
	_populate_feed()


#Bank

func _open_bank() -> void:
	_hide_all_screens()
	bank_screen.visible = true
	_refresh_bank_summary()


func _refresh_bank_summary() -> void:
	if not bank_screen.visible:
		return
	var deposit_text: String = tr("COMMON_NONE")
	if GameBackend.term_deposit_amount > 0.0:
		deposit_text = tr("PHONE_TERM_DEPOSIT_VALUE") % [GameBackend.term_deposit_amount, GameBackend.term_deposit_days_left]
	# The IRD number is here
	# and because StudyLink asks for it, so the game has to give you somewhere
	# to go and look it up.
	# The button used to say "10 days, +6%" whatever the real terms were.
	term_deposit_button.text = tr("PHONE_TERM_DEPOSIT_BUTTON") % [GameBackend.TERM_DEPOSIT_DAYS, GameBackend.TERM_DEPOSIT_RATE * 100.0]
	bank_summary_label.text = tr("PHONE_BANK_SUMMARY") % [
		GameBackend.player_name, GameBackend.ird_number,
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


#Messages

var _current_thread: Dictionary = {}
## Which person's chat is open. The inbox is keyed by contact now, not thread.
var _active_contact: String = ""
var _active_thread_id: String = ""
var _thread_step: int = 0
var _pending_sanity: float = 0.0
var _pending_temptation: float = 0.0
## The "•••" pause before someone's message appears. Tests switch it off.
var typing_enabled: bool = true
var _typing_token: int = 0

## Opening the app lands you on the inbox, like a real messages app.
func _open_messages() -> void:
	_hide_all_screens()
	messages_screen.visible = true
	_show_inbox()


## The inbox lists people, not conversations.
func _show_inbox() -> void:
	inbox_view.visible = true
	thread_view.visible = false

	for child in inbox_list.get_children():
		child.queue_free()

	var people: Array = GameBackend.contacts()

	if people.is_empty():
		var empty := Label.new()
		empty.text = tr("PHONE_NO_MESSAGES")
		empty.add_theme_color_override("font_color", Color(0.6, 0.64, 0.72))
		inbox_list.add_child(empty)
		return

	for who in people:
		inbox_list.add_child(_make_contact_row(str(who)))

	# Nothing is ever removed — every contact stays for the whole run. The
	# count is here so it's obvious when there are more below the fold.
	var footer := Label.new()
	footer.text = tr("PHONE_CHATS_UNREAD") % [people.size(), GameBackend.unread_count]
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", Color(0.48, 0.52, 0.60))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inbox_list.add_child(footer)


## One row per person: initials, name, a preview of the very last thing said
## in any of their conversations, and an unread count if they've been in touch.
func _make_contact_row(who: String) -> Button:
	var row := Button.new()
	row.custom_minimum_size = Vector2(0, 58)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.pressed.connect(_open_contact.bind(who))

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 8)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 8
	hbox.offset_right = -8
	hbox.offset_top = 5
	hbox.offset_bottom = -5
	row.add_child(hbox)

	# --- avatar
	var av := Panel.new()
	av.custom_minimum_size = Vector2(40, 40)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var av_style := StyleBoxFlat.new()
	av_style.bg_color = _avatar_colour(who)
	av_style.corner_radius_top_left = 20
	av_style.corner_radius_top_right = 20
	av_style.corner_radius_bottom_left = 20
	av_style.corner_radius_bottom_right = 20
	av.add_theme_stylebox_override("panel", av_style)
	var initials := Label.new()
	initials.text = _initials(GameBackend.contact_name(who))
	initials.mouse_filter = Control.MOUSE_FILTER_IGNORE
	initials.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initials.add_theme_font_size_override("font_size", 15)
	av.add_child(initials)
	hbox.add_child(av)

	# --- name + preview
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(col)

	var unread: int = GameBackend.unread_for_contact(who)

	var name_label := Label.new()
	name_label.text = GameBackend.contact_name(who)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 14)
	if unread > 0:
		name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	col.add_child(name_label)

	var preview := Label.new()
	preview.text = _contact_preview(who)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.clip_text = true
	preview.add_theme_font_size_override("font_size", 11)
	preview.add_theme_color_override("font_color",
		Color(0.78, 0.82, 0.90) if unread > 0 else Color(0.55, 0.59, 0.66))
	col.add_child(preview)

	# --- unread pill
	if unread > 0:
		var pill := Panel.new()
		pill.custom_minimum_size = Vector2(22, 22)
		pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pill_style := StyleBoxFlat.new()
		pill_style.bg_color = Color(0.898, 0.282, 0.302)
		pill_style.corner_radius_top_left = 11
		pill_style.corner_radius_top_right = 11
		pill_style.corner_radius_bottom_left = 11
		pill_style.corner_radius_bottom_right = 11
		pill.add_theme_stylebox_override("panel", pill_style)
		var n := Label.new()
		n.text = str(unread)
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		n.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", 12)
		pill.add_child(n)
		hbox.add_child(pill)

	return row


func _initials(who: String) -> String:
	var parts: PackedStringArray = who.strip_edges().split(" ", false)
	if parts.is_empty():
		return "?"
	if parts.size() == 1:
		return parts[0].substr(0, 2).to_upper()
	return (parts[0].substr(0, 1) + parts[1].substr(0, 1)).to_upper()


## The last line said in any conversation with this person — or, if their
## newest conversation hasn't been opened yet, its opening line.
func _contact_preview(who: String) -> String:
	var threads: Array = GameBackend.threads_for_contact(who)
	if threads.is_empty():
		return ""
	for i in range(threads.size() - 1, -1, -1):
		var tid: String = str(threads[i])
		var saved: Array = GameBackend.thread_log(tid)
		if not saved.is_empty():
			var last: Dictionary = saved[-1]
			var body: String = str(last.body).replace("\n", " ")
			return (tr("PHONE_YOU_PREFIX") % body) if bool(last.mine) else body
	# Nothing said yet — show the opener of the newest unread conversation.
	var newest: Dictionary = MessageData.personalise(
		MessageData.thread_by_id(str(threads[-1])), GameBackend.player_name)
	if newest.is_empty() or not newest.has("steps"):
		return ""
	return str(newest.steps[0].them).replace("\n", " ")


## Stable per-contact colour, so the same person always looks the same.
func _avatar_colour(who: String) -> Color:
	var h: int = 0
	for c in who.to_utf8_buffer():
		h = (h * 31 + c) % 360
	return Color.from_hsv(float(h) / 360.0, 0.45, 0.62)


## Opens one person's chat: every conversation they've ever had with you,
## replayed in order with a day divider between them, then whichever one is
## still live.
func _open_contact(who: String) -> void:
	Audio.play("click")
	_active_contact = who

	inbox_view.visible = false
	thread_view.visible = true
	sender_label.text = GameBackend.contact_name(who)

	for child in bubbles.get_children():
		child.queue_free()

	# replay the whole history with this person
	var threads: Array = GameBackend.threads_for_contact(who)
	var last_day: int = -999
	for tid_any in threads:
		var tid: String = str(tid_any)
		var saved: Array = GameBackend.thread_log(tid)
		if saved.is_empty():
			continue
		var day: int = int(saved[0].get("day", GameBackend.arrived_on_day(tid)))
		if day != last_day:
			_add_day_divider(day)
			last_day = day
		for entry in saved:
			_add_bubble(str(entry.speaker), str(entry.body), bool(entry.mine), false)

	#then drop into whatever is unfinished
	var active: String = GameBackend.active_thread_for_contact(who)
	GameBackend.mark_contact_read(who)

	if active == "":
		_active_thread_id = ""
		_current_thread = {}
		_all_caught_up()
		return

	_start_thread(active, last_day)


## Begins (or resumes) one conversation inside the currently open chat.
func _start_thread(tid: String, last_day: int = -999) -> void:
	# A text can land on day 54 and sit unread until day 58, by which point
	# its premise may no longer be true. If it hasn't been started yet and
	# it's gone stale, quietly retire it and move on rather than making
	# StudyLink ask whether you've applied for the loan you already have.
	if GameBackend.thread_log(tid).is_empty() and MessageData.thread_is_stale(tid):
		GameBackend.mark_read(tid)
		GameBackend.mark_done(tid)
		var following: String = GameBackend.active_thread_for_contact(_active_contact)
		if following != "" and following != tid:
			_start_thread(following, last_day)
		else:
			_all_caught_up()
		return

	_active_thread_id = tid
	_current_thread = MessageData.personalise(
		MessageData.thread_by_id(tid), GameBackend.player_name)
	_pending_sanity = 0.0
	_pending_temptation = 0.0

	# A new conversation on a later day gets its own divider, so a chat that
	# spans two months doesn't read as one continuous exchange.
	var arrived: int = GameBackend.arrived_on_day(tid)
	if GameBackend.thread_log(tid).is_empty() and arrived != last_day:
		_add_day_divider(arrived)

	_thread_step = GameBackend.thread_step(tid)
	if GameBackend.is_done(tid):
		_end_thread()
	elif GameBackend.is_thread_waiting(tid):
		_show_waiting_status()
	else:
		_show_thread_step()


## "— Day 42 —" between conversations.
func _add_day_divider(day: int) -> void:
	var l := Label.new()
	l.text = tr("PHONE_DAY_DIVIDER") % day
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(0.45, 0.49, 0.57))
	bubbles.add_child(l)


## True when the offer has arrived, been read to the end, and the player still
## hasn't hit the button that ends the run.
## This is deliberately NOT "is the thread unfinished". The thread gets marked
## done as soon as its last line is shown — which is correct for the inbox —
## but the run doesn't end until the player actually acknowledges the offer.
## Conflating the two is what made it possible to close the phone one tap
## early and lock yourself out of finishing the game.
func _offer_still_to_acknowledge() -> bool:
	return (GameBackend.results_phase >= 2
		and not GameBackend.game_over
		and GameBackend.has_arrived("university_offer")
		and _active_contact == GameBackend.contact_name_for("university_offer"))


func _show_offer_finish_button() -> void:
	for child in reply_container.get_children():
		child.queue_free()
	var finish := Button.new()
	finish.text = tr("PHONE_SIT_WITH_IT")
	finish.custom_minimum_size = Vector2(0, 34)
	finish.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	finish.pressed.connect(_on_offer_acknowledged)
	reply_container.add_child(finish)


func _on_offer_acknowledged() -> void:
	close()
	GameBackend.acknowledge_offer()


func _all_caught_up() -> void:
	# The offer button outranks "you're up to date" — otherwise reopening the
	# admissions chat after reading the offer leaves you with no way to
	# finish the game.
	if _offer_still_to_acknowledge():
		_show_offer_finish_button()
		return
	for child in reply_container.get_children():
		child.queue_free()
	var l := Label.new()
	l.text = tr("PHONE_CAUGHT_UP") % GameBackend.contact_name(_active_contact)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", Color(0.6, 0.64, 0.72))
	reply_container.add_child(l)


## A chat bubble. Theirs sit left and grey; yours sit right and blue.
func _add_bubble(speaker: String, body: String, is_me: bool, record: bool = true) -> void:
	if record and _active_thread_id != "":
		GameBackend.append_thread_log(_active_thread_id, speaker, body, is_me)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bubble := PanelContainer.new()
	bubble.custom_minimum_size = Vector2(190, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.45, 0.72) if is_me else Color(0.26, 0.27, 0.32)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	bubble.add_theme_stylebox_override("panel", style)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)

	# Only label the speaker in group chats, where it isn't obvious.
	if not is_me and speaker != str(_current_thread.sender):
		var who := Label.new()
		who.text = GameBackend.contact_name(speaker)
		who.add_theme_font_size_override("font_size", 11)
		who.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
		col.add_child(who)

	var msg := Label.new()
	msg.text = body
	msg.add_theme_font_size_override("font_size", 13)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(180, 0)
	col.add_child(msg)

	bubble.add_child(col)

	if is_me:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(bubble)
	else:
		row.add_child(bubble)
		var spacer2 := Control.new()
		spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer2)

	bubbles.add_child(row)
	_scroll_to_bottom()


func _scroll_to_bottom() -> void:
	await get_tree().process_frame
	if is_instance_valid(thread_scroll):
		thread_scroll.scroll_vertical = int(thread_scroll.get_v_scroll_bar().max_value)


func _show_thread_step() -> void:
	var steps: Array = _current_thread.steps
	if _thread_step >= steps.size():
		_end_thread()
		return

	var step: Dictionary = steps[_thread_step]
	# If this line is already the last thing in the saved transcript, don't
	# duplicate it.
	var log_arr: Array = GameBackend.thread_log(_active_thread_id)
	var body: String = _expand(str(step.them))
	var already: bool = log_arr.size() > 0 and str(log_arr[-1].body) == body and not bool(log_arr[-1].mine)
	for child in reply_container.get_children():
		child.queue_free()
	if not already:
		var speaker: String = str(step.get("from", _current_thread.sender))
		if typing_enabled:
			# "…" for a moment first, so the reply feels typed rather than
			# fired at you. Longer messages take a little longer.
			_typing_token += 1
			var token: int = _typing_token
			var dots := _add_typing_bubble(speaker)
			await get_tree().create_timer(clampf(0.45 + body.length() * 0.012, 0.5, 1.6)).timeout
			if is_instance_valid(dots):
				dots.queue_free()
			# Phone closed, or a different chat opened, while they were typing:
			# the line isn't saved yet, so it simply shows next time.
			if token != _typing_token or not panel.visible or not thread_view.visible:
				return
		_add_bubble(speaker, body, false)

	for reply in step.replies:
		var btn := Button.new()
		btn.text = reply.text
		btn.custom_minimum_size = Vector2(0, 34)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 12)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_reply_chosen.bind(reply))
		reply_container.add_child(btn)


## Story threads use placeholders so the text can carry live results.
func _expand(body: String) -> String:
	if body == "RESULTS_SUMMARY":
		var lines: Array = []
		for subject in GameBackend.active_subjects:
			var d: Dictionary = GameBackend.subject_result_detail(subject)
			var ext: String = "-"
			if not d.externals.is_empty():
				var e: Dictionary = d.externals[0]
				ext = GameBackend.band_name(str(e.band)) if e.taken else tr("NCEA_ABSENT")
			lines.append(tr("PHONE_RESULTS_LINE") % [
				GameBackend.subject_name(str(subject)), ext, d.credits, d.grade])
		lines.append("")
		lines.append(tr("NCEA_UE_ACHIEVED" if GameBackend.has_university_entrance() else "NCEA_UE_NOT_ACHIEVED"))
		if not GameBackend.has_university_entrance():
			lines.append(tr("PHONE_RESULTS_FULL_BREAKDOWN"))
		return "\n".join(lines)
	if body == "OFFER_SUMMARY":
		return GameBackend.offer_message()
	# LOAN_APPROVAL / LOAN_DECLINE are the letters StudyLink sends you.
	# LOAN_SUMMARY is the running balance — right for a portal, wrong for an
	# approval letter, where "borrowed so far: $0.00" is all it could say.
	if body == "LOAN_APPROVAL":
		return GameBackend.loan_approval_text()
	if body == "LOAN_DECLINE":
		return GameBackend.loan_decline_text()
	if body == "LOAN_SUMMARY":
		return GameBackend.loan_status_text()
	if body == "ALLOWANCE_SUMMARY":
		return GameBackend.allowance_status_text()
	if body == "PARENT_CONFIRM":
		# Getting this far in the thread IS the action — you asked them, they
		# did it. That's the whole mechanic.
		GameBackend.confirm_parents_income()
		return tr("PHONE_PARENT_CONFIRM")
	return body


func _on_reply_chosen(reply: Dictionary) -> void:
	Audio.play("click")
	_add_bubble(GameBackend.player_name, str(reply.text), true)
	_pending_sanity += float(reply.get("sanity", 0.0))
	_pending_temptation += float(reply.get("temptation", 0.0))
	GameBackend.stat_messages_replied += 1
	# Saying yes to something in a text actually books it (commit), and a
	# reply can also set a story flag or send/receive money.
	var note: String = GameBackend.apply_reply_effects(reply)
	if note != "":
		_add_system_line(note)
	# A reply can jump elsewhere in the thread, so conversations fork.
	_thread_step = MessageData.next_step_for(reply, _thread_step)
	GameBackend.set_thread_step(_active_thread_id, _thread_step)
	# Some replies don't come straight back.
	var wait: float = MessageData.wait_before_step(_active_thread_id, _thread_step)
	if wait > 0.0:
		GameBackend.set_thread_wait(_active_thread_id, wait)
		_show_waiting_status()
		return
	_show_thread_step()


## Shown under your last message while they haven't answered yet.
func _show_waiting_status() -> void:
	for child in reply_container.get_children():
		child.queue_free()
	var l := Label.new()
	var who: String = GameBackend.contact_name(str(_current_thread.get("sender", _active_contact)))
	l.text = tr("PHONE_SEEN") % who if randi() % 2 == 0 else tr("PHONE_DELIVERED")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.55, 0.59, 0.66))
	reply_container.add_child(l)
	var hint := Label.new()
	hint.text = tr("PHONE_WILL_REPLY")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.45, 0.49, 0.57))
	reply_container.add_child(hint)


## "+$20 received" — a small centred line in the chat, not a bubble.
func _add_system_line(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.45, 0.80, 0.55))
	bubbles.add_child(l)
	_scroll_to_bottom()


func _add_typing_bubble(speaker: String) -> Control:
	var row := HBoxContainer.new()
	var bubble := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.26, 0.27, 0.32)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	bubble.add_theme_stylebox_override("panel", style)
	var l := Label.new()
	l.text = "•••"
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", Color(0.75, 0.78, 0.84))
	bubble.add_child(l)
	row.add_child(bubble)
	bubbles.add_child(row)
	var tw := l.create_tween().set_loops()
	tw.tween_property(l, "modulate:a", 0.35, 0.35)
	tw.tween_property(l, "modulate:a", 1.0, 0.35)
	_scroll_to_bottom()
	return row


func _end_thread() -> void:
	for child in reply_container.get_children():
		child.queue_free()
	if _active_thread_id != "":
		GameBackend.mark_done(_active_thread_id)
	# Reading your offer is what closes out the year, so the button that does
	# it has to survive closing and reopening the phone.
	if _offer_still_to_acknowledge():
		_show_offer_finish_button()
		return
	# If this person has ANOTHER conversation waiting, continue into it in the
	# same chat rather than kicking you back to the inbox
	if _active_contact != "":
		var next_tid: String = GameBackend.active_thread_for_contact(_active_contact)
		if next_tid != "" and next_tid != _active_thread_id:
			var last_day: int = GameBackend.arrived_on_day(_active_thread_id) if _active_thread_id != "" else -999
			_start_thread(next_tid, last_day)
			return
		_all_caught_up()
		return

	var ended := Label.new()
	ended.text = tr("PHONE_END_CONVO")
	ended.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ended.add_theme_font_size_override("font_size", 12)
	ended.add_theme_color_override("font_color", Color(0.6, 0.64, 0.72))
	reply_container.add_child(ended)


func _finish_thread() -> void:
	# Texting is quick and cheap next to seeing someone in person.
	if _pending_sanity != 0.0 or _pending_temptation != 0.0:
		GameBackend.socialize(max(1.0, _pending_sanity), 0.08, max(0.0, _pending_temptation))
	_pending_sanity = 0.0
	_pending_temptation = 0.0
	_show_inbox()


#Weather no gameplay effect for now

func _open_weather() -> void:
	_hide_all_screens()
	weather_screen.visible = true
	var w: Dictionary = _weather_options[randi() % _weather_options.size()]
	weather_label.text = w.icon
	weather_detail_label.text = tr(str(w.detail))


# Games — a little arcade. Each game costs a quarter of an hour of in-game
# time and gives the same small lift (and pull) as any other phone time.

const QM_ROUNDS: int = 10
const QM_TIME_PER_ROUND: float = 4.0

var _qm_active: bool = false
var _qm_score: int = 0
var _qm_round: int = 0
var _qm_answer: int = 0
var _qm_timer: SceneTreeTimer = null
## Which game is on screen: "", "maths", "memory", "higher", "tap".
var _game: String = ""

func _open_games() -> void:
	_hide_all_screens()
	games_screen.visible = true
	_show_arcade()


## The list of games, with your best at each.
func _show_arcade() -> void:
	_stop_all_games()
	_game = ""
	game_info_label.text = tr("ARCADE_PICK")
	# On the game list the home bar takes you out; inside a game, Back
	# returns to the list.
	games_back_button.visible = false
	game_score_label.text = ""
	game_start_button.visible = false
	game_start_button.text = tr("START_BUTTON")
	_clear_grid()
	game_grid.columns = 1
	for g in [["maths", "ARCADE_MATHS"], ["memory", "ARCADE_MEMORY"], ["higher", "ARCADE_HIGHER"], ["tap", "ARCADE_TAP"]]:
		var b := Button.new()
		var best: String = _best_text(str(g[0]))
		b.text = tr(str(g[1])) + ("" if best == "" else "\n" + best)
		b.custom_minimum_size = Vector2(300, 58)
		b.add_theme_font_size_override("font_size", 15)
		b.pressed.connect(_choose_game.bind(str(g[0])))
		game_grid.add_child(b)


func _best_text(game: String) -> String:
	if not GameBackend.phone_best.has(game):
		return ""
	var v: int = int(GameBackend.phone_best[game])
	match game:
		"memory":
			return tr("ARCADE_BEST_MOVES") % v
		_:
			return tr("ARCADE_BEST") % v


## Higher is better everywhere except Memory, where fewer moves wins.
func _record_best(game: String, value: int) -> bool:
	var had: bool = GameBackend.phone_best.has(game)
	var old: int = int(GameBackend.phone_best.get(game, 0))
	var better: bool = not had or (value < old if game == "memory" else value > old)
	if better:
		GameBackend.phone_best[game] = value
	GameBackend.stat_games_played += 1
	GameBackend.doomscroll(0.25, 6.0, 9.0)
	return better and had


func _choose_game(game: String) -> void:
	_game = game
	games_back_button.visible = true
	_clear_grid()
	game_score_label.text = ""
	game_start_button.visible = true
	game_start_button.text = tr("START_BUTTON")
	match game:
		"maths":
			game_info_label.text = tr("QM_INFO") % QM_ROUNDS
		"memory":
			game_info_label.text = tr("MEM_INFO")
		"higher":
			game_info_label.text = tr("HL_INFO")
		"tap":
			game_info_label.text = tr("TAP_INFO") % TAP_ROUNDS


func _on_game_start_pressed() -> void:
	game_start_button.visible = false
	match _game:
		"maths":
			_start_tap_rush()
		"memory":
			_start_memory()
		"higher":
			_start_higher()
		"tap":
			_start_tap()


func _clear_grid() -> void:
	for child in game_grid.get_children():
		game_grid.remove_child(child)
		child.queue_free()


func _stop_all_games() -> void:
	_qm_active = false
	_cancel_qm_timer()
	_tap_active = false
	_mem_locked = false


func _finish_with(score_line: String, game: String, value: int) -> void:
	_clear_grid()
	var new_best: bool = _record_best(game, value)
	game_info_label.text = tr("ARCADE_NEW_BEST") if new_best else tr("QM_DONE")
	game_score_label.text = score_line
	game_start_button.visible = true
	game_start_button.text = tr("QM_AGAIN")
	var menu := Button.new()
	menu.text = tr("ARCADE_OTHER_GAMES")
	menu.custom_minimum_size = Vector2(300, 40)
	menu.pressed.connect(_show_arcade)
	game_grid.columns = 1
	game_grid.add_child(menu)


# --- Quick Maths ---------------------------------------------------------------

## Always kill the previous timer before making another
func _cancel_qm_timer() -> void:
	if _qm_timer != null and _qm_timer.timeout.is_connected(_on_qm_timeout):
		_qm_timer.timeout.disconnect(_on_qm_timeout)
	_qm_timer = null


func _start_tap_rush() -> void:
	_qm_active = true
	_qm_score = 0
	_qm_round = 0
	game_start_button.visible = false
	_next_qm_round()


func _next_qm_round() -> void:
	_cancel_qm_timer()
	if not _qm_active:
		return
	if _qm_round >= QM_ROUNDS:
		_finish_quick_maths()
		return
	_qm_round += 1

	# Mix of operations, kept mental-arithmetic sized.
	var a: int = randi_range(2, 19)
	var b: int = randi_range(2, 12)
	var op: int = randi() % 3
	var question := ""
	match op:
		0:
			_qm_answer = a + b
			question = "%d + %d" % [a, b]
		1:
			# Keep subtraction positive so answers stay clean.
			if b > a:
				var t: int = a; a = b; b = t
			_qm_answer = a - b
			question = "%d − %d" % [a, b]
		_:
			var m: int = randi_range(2, 9)
			_qm_answer = b * m
			question = "%d × %d" % [b, m]

	game_info_label.text = "%s = ?" % question
	game_score_label.text = tr("QM_ROUND") % [_qm_round, QM_ROUNDS, _qm_score]

	# Four options: the answer plus three plausible near-misses.
	var options: Array = [_qm_answer]
	var guard: int = 0
	while options.size() < 4 and guard < 40:
		guard += 1
		var delta: int = randi_range(-9, 9)
		var wrong: int = _qm_answer + delta
		if delta != 0 and wrong > 0 and not wrong in options:
			options.append(wrong)
	options.shuffle()

	_clear_grid()
	game_grid.columns = 2
	for value in options:
		var b2 := Button.new()
		b2.text = str(value)
		b2.custom_minimum_size = Vector2(110, 54)
		b2.add_theme_font_size_override("font_size", 20)
		b2.pressed.connect(_on_qm_answer.bind(value))
		game_grid.add_child(b2)

	_qm_timer = get_tree().create_timer(QM_TIME_PER_ROUND)
	_qm_timer.timeout.connect(_on_qm_timeout)


func _on_qm_timeout() -> void:
	if not _qm_active:
		return
	_next_qm_round()


func _on_qm_answer(value: int) -> void:
	if not _qm_active:
		return
	if value == _qm_answer:
		_qm_score += 1
		Audio.play("correct")
	else:
		Audio.play("wrong")
	_next_qm_round()


func _finish_quick_maths() -> void:
	_cancel_qm_timer()
	_qm_active = false
	_finish_with(tr("QM_FINAL") % [_qm_score, QM_ROUNDS], "maths", _qm_score)


# --- Memory: find the 8 pairs in as few moves as you can ---------------------------

const MEM_COLOURS := [Color(0.90, 0.36, 0.36), Color(0.95, 0.62, 0.25), Color(0.93, 0.83, 0.30),
	Color(0.40, 0.78, 0.45), Color(0.30, 0.70, 0.85), Color(0.42, 0.48, 0.92),
	Color(0.72, 0.45, 0.88), Color(0.90, 0.48, 0.72)]
const MEM_HIDDEN := Color(0.20, 0.22, 0.27)

var _mem_values: Array = []
var _mem_buttons: Array = []
var _mem_found: Array = []
var _mem_first: int = -1
var _mem_moves: int = 0
var _mem_locked: bool = false


func _start_memory() -> void:
	_mem_values = []
	for i in 8:
		_mem_values.append(i)
		_mem_values.append(i)
	_mem_values.shuffle()
	_mem_found = []
	_mem_found.resize(16)
	_mem_found.fill(false)
	_mem_first = -1
	_mem_moves = 0
	_mem_locked = false
	_clear_grid()
	game_grid.columns = 4
	_mem_buttons = []
	for i in 16:
		var b := Button.new()
		b.custom_minimum_size = Vector2(70, 70)
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(_on_mem_pressed.bind(i))
		game_grid.add_child(b)
		_mem_buttons.append(b)
		_mem_paint(i, false)
	game_info_label.text = tr("MEM_INFO")
	game_score_label.text = tr("MEM_MOVES") % _mem_moves


func _mem_paint(i: int, shown: bool) -> void:
	var b: Button = _mem_buttons[i]
	var st := StyleBoxFlat.new()
	st.bg_color = MEM_COLOURS[_mem_values[i]] if shown else MEM_HIDDEN
	st.set_corner_radius_all(10)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, st)
	b.text = str(int(_mem_values[i]) + 1) if shown else ""


func _on_mem_pressed(i: int) -> void:
	if _mem_locked or _mem_found[i] or i == _mem_first:
		return
	Audio.play("click")
	_mem_paint(i, true)
	if _mem_first == -1:
		_mem_first = i
		return
	_mem_moves += 1
	game_score_label.text = tr("MEM_MOVES") % _mem_moves
	var a: int = _mem_first
	_mem_first = -1
	if _mem_values[a] == _mem_values[i]:
		_mem_found[a] = true
		_mem_found[i] = true
		Audio.play("correct")
		if not false in _mem_found:
			_finish_with(tr("MEM_FINAL") % _mem_moves, "memory", _mem_moves)
		return
	_mem_locked = true
	await get_tree().create_timer(0.7).timeout
	if _game != "memory" or _mem_buttons.size() != 16 or not is_instance_valid(_mem_buttons[a]):
		return
	_mem_paint(a, false)
	_mem_paint(i, false)
	_mem_locked = false


# --- Higher or Lower: how long can you keep the streak going? -------------------------

var _hl_card: int = 0
var _hl_streak: int = 0


func _start_higher() -> void:
	_hl_card = randi_range(1, 13)
	_hl_streak = 0
	_hl_show()


func _hl_show() -> void:
	_clear_grid()
	game_grid.columns = 2
	game_info_label.text = tr("HL_CARD") % _hl_card
	game_score_label.text = tr("HL_STREAK") % _hl_streak
	for choice in [["HL_LOWER", -1], ["HL_HIGHER", 1]]:
		var b := Button.new()
		b.text = tr(str(choice[0]))
		b.custom_minimum_size = Vector2(140, 60)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_hl_guess.bind(int(choice[1])))
		game_grid.add_child(b)


func _on_hl_guess(direction: int) -> void:
	var next: int = randi_range(1, 13)
	while next == _hl_card:
		next = randi_range(1, 13)
	var right: bool = (next > _hl_card) == (direction > 0)
	var was: int = _hl_card
	_hl_card = next
	if right:
		_hl_streak += 1
		Audio.play("correct")
		_hl_show()
	else:
		Audio.play("wrong")
		_finish_with(tr("HL_FINAL") % [was, next, _hl_streak], "higher", _hl_streak)


# --- Tap the Light: hit the lit square before it goes out -------------------------------

const TAP_ROUNDS: int = 20
var _tap_active: bool = false
var _tap_round: int = 0
var _tap_hits: int = 0
var _tap_lit: int = -1
var _tap_buttons: Array = []
var _tap_token: int = 0


func _start_tap() -> void:
	_tap_lit = -1
	_tap_active = true
	_tap_round = 0
	_tap_hits = 0
	_clear_grid()
	game_grid.columns = 3
	_tap_buttons = []
	for i in 9:
		var b := Button.new()
		b.custom_minimum_size = Vector2(92, 92)
		b.pressed.connect(_on_tap_pressed.bind(i))
		game_grid.add_child(b)
		_tap_buttons.append(b)
	game_info_label.text = tr("TAP_GO")
	_tap_next()


func _tap_paint(i: int, lit: bool) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.98, 0.80, 0.30) if lit else Color(0.20, 0.22, 0.27)
	st.set_corner_radius_all(12)
	for state in ["normal", "hover", "pressed", "focus"]:
		_tap_buttons[i].add_theme_stylebox_override(state, st)


func _tap_next() -> void:
	if not _tap_active:
		return
	if _tap_round >= TAP_ROUNDS:
		_tap_active = false
		_finish_with(tr("TAP_FINAL") % [_tap_hits, TAP_ROUNDS], "tap", _tap_hits)
		return
	_tap_round += 1
	if _tap_lit >= 0 and _tap_lit < _tap_buttons.size():
		_tap_paint(_tap_lit, false)
	var pick: int = randi() % 9
	while pick == _tap_lit:
		pick = randi() % 9
	_tap_lit = pick
	_tap_paint(pick, true)
	game_score_label.text = tr("TAP_SCORE") % [_tap_hits, _tap_round, TAP_ROUNDS]
	# Gets faster as you go.
	_tap_token += 1
	var token: int = _tap_token
	await get_tree().create_timer(lerpf(1.0, 0.45, float(_tap_round) / TAP_ROUNDS)).timeout
	if token == _tap_token and _tap_active:
		_tap_next()


func _on_tap_pressed(i: int) -> void:
	if not _tap_active:
		return
	if i == _tap_lit:
		_tap_hits += 1
		Audio.play("correct")
		_tap_paint(i, false)
		_tap_lit = -1
		_tap_next()
	else:
		Audio.play("wrong")


func _end_game_and_go_home() -> void:
	if _game != "":
		_show_arcade()
		return
	_stop_all_games()
	_show_home()


func _on_game_ended(_result: String) -> void:
	_stop_all_games()
	close()


# --- Phone chrome -------------------------------------------------------------

var _clock_tick: float = 0.0

func _process(delta: float) -> void:
	if not panel.visible:
		return
	_clock_tick += delta
	if _clock_tick >= 0.5:
		_clock_tick = 0.0
		_update_clock()


## The time comes from the game clock, the date from the last day/month the
## town's sky clock reported.
func _update_clock() -> void:
	var h: float = fposmod(GameBackend.game_hour, 24.0)
	var hh: int = int(h)
	var mm: int = int((h - hh) * 60.0)
	var t: String = "%d:%02d" % [hh, mm]
	status_time_label.text = t
	clock_label.text = t
	var d: int = GameBackend.saved_day
	var m: int = GameBackend.saved_month
	var y: int = GameBackend.saved_year
	if m < 1 or m > 12:
		date_label.text = tr("COMMON_DAY") % GameBackend.get_elapsed_days()
		return
	date_label.text = tr("DATE_FORMAT").format({
		"wd": tr("DAY_SHORT_" + _weekday(d, m, y)),
		"d": d,
		"m": tr("MONTH_SHORT_%d" % m),
	})


## Day of the week (Zeller's congruence), as the three-letter key suffix.
func _weekday(d: int, m: int, y: int) -> String:
	var mm: int = m
	var yy: int = y
	if mm < 3:
		mm += 12
		yy -= 1
	var k: int = yy % 100
	var j: int = yy / 100
	var h: int = (d + (13 * (mm + 1)) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
	return ["SAT", "SUN", "MON", "TUE", "WED", "THU", "FRI"][h]


## The bar at the bottom: puts the phone away on the home screen, and goes
## back home from inside an app (finishing whatever was open first).
func _on_home_bar_pressed() -> void:
	if home_screen.visible:
		close()
		return
	if messages_screen.visible:
		_finish_thread()
	if games_screen.visible:
		_stop_all_games()
		_game = ""
	_show_home()
