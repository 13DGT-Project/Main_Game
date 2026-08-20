## ending_scene.gd
## Root script for EndingScene.tscn. Reads GameBackend.ending_result (set by
## GameBackend._end_game()) to decide which text/music to show. Doesn't need
## anything passed to it directly since GameBackend is an autoload.
extends Control

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu_button.pressed.connect(_on_menu_pressed)

	var uni: Dictionary = GameBackend.universities.get(GameBackend.selected_university, {})
	var money_needed: float = uni.get("money_needed", 0)
	var grades_needed: float = uni.get("grades_needed", 0)
	var stats_text: String = "Money: $%.0f / $%.0f\nOverall grade: %.0f / %.0f" % [
		GameBackend.money, money_needed, GameBackend.get_overall_grade(), grades_needed
	]

	match GameBackend.ending_result:
		"good":
			title_label.text = "Acceptance Letter!"
			subtitle_label.text = "You got into %s.\n\n%s" % [GameBackend.selected_university, stats_text]
			MusicManager.play_track("good_ending")
		"bad_sanity":
			title_label.text = "Burnout"
			subtitle_label.text = "The pressure got to you before the year was even over.\n\n%s" % stats_text
			MusicManager.play_track("bad_ending")
		_:  # "bad_deadline" or anything unexpected
			title_label.text = "Rejection Letter"
			subtitle_label.text = "It wasn't enough to get into %s this time.\n\n%s" % [GameBackend.selected_university, stats_text]
			MusicManager.play_track("bad_ending")


func _on_menu_pressed() -> void:
	GameBackend.reset_run()
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")
