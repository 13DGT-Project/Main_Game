## phone_app.gd
## Root script for phone_app.tscn, registered as the "PhoneApp" autoload.
## Call PhoneApp.toggle() (main_character.gd does this on "use_item" if the
## selected hotbar slot holds the Phone) to open/close it. Works from any
## scene since it's an autoload, same pattern as the Inventory/hotbar UI.
extends CanvasLayer

@onready var panel: Control = $Panel
@onready var screen: Control = $Panel/CenterContainer/PhoneBody/Screen

@onready var home_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen
@onready var doomscroll_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/DoomscrollButton
@onready var bank_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/BankButton
@onready var close_button: Button = $Panel/CenterContainer/PhoneBody/Screen/HomeScreen/CloseButton

@onready var doomscroll_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/DoomscrollScreen
@onready var doomscroll_feed_label: Label = $Panel/CenterContainer/PhoneBody/Screen/DoomscrollScreen/FeedLabel
@onready var keep_scrolling_button: Button = $Panel/CenterContainer/PhoneBody/Screen/DoomscrollScreen/KeepScrollingButton
@onready var doomscroll_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/DoomscrollScreen/DoomscrollBackButton

@onready var bank_screen: Control = $Panel/CenterContainer/PhoneBody/Screen/BankScreen
@onready var bank_summary_label: Label = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/SummaryLabel
@onready var bank_amount_input: LineEdit = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/AmountInput
@onready var deposit_button: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/DepositButton
@onready var withdraw_button: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/WithdrawButton
@onready var term_deposit_button: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/TermDepositButton
@onready var bank_back_button: Button = $Panel/CenterContainer/PhoneBody/Screen/BankScreen/BankBackButton

var _feed_lines: Array = [
	"\"you won't believe what happened at lunch today...\"",
	"27 people liked a photo of someone's lunch.",
	"\"study tips that ACTUALLY work (number 4 will shock you)\"",
	"A group chat is arguing about something that doesn't matter.",
	"Someone's dog did a trick. It's fine. It's a fine trick.",
	"\"5am productivity routine of a top student\" — 14 minutes long.",
	"Reposted, reposted again, reposted a third time.",
	"\"this song will be stuck in your head for the rest of the day\"",
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	_show_home()

	doomscroll_button.pressed.connect(_open_doomscroll)
	bank_button.pressed.connect(_open_bank)
	close_button.pressed.connect(close)

	keep_scrolling_button.pressed.connect(_keep_scrolling)
	doomscroll_back_button.pressed.connect(_show_home)

	deposit_button.pressed.connect(_on_deposit_pressed)
	withdraw_button.pressed.connect(_on_withdraw_pressed)
	term_deposit_button.pressed.connect(_on_term_deposit_pressed)
	bank_back_button.pressed.connect(_show_home)

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


func _show_home() -> void:
	home_screen.visible = true
	doomscroll_screen.visible = false
	bank_screen.visible = false


func _open_doomscroll() -> void:
	home_screen.visible = false
	doomscroll_screen.visible = true
	bank_screen.visible = false
	doomscroll_feed_label.text = _feed_lines[randi() % _feed_lines.size()]


func _keep_scrolling() -> void:
	GameBackend.doomscroll()
	doomscroll_feed_label.text = _feed_lines[randi() % _feed_lines.size()]


func _open_bank() -> void:
	home_screen.visible = false
	doomscroll_screen.visible = false
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


func _on_deposit_pressed() -> void:
	GameBackend.deposit_savings(_get_amount_input())
	_refresh_bank_summary()


func _on_withdraw_pressed() -> void:
	GameBackend.withdraw_savings(_get_amount_input())
	_refresh_bank_summary()


func _on_term_deposit_pressed() -> void:
	GameBackend.start_term_deposit(_get_amount_input())
	_refresh_bank_summary()
