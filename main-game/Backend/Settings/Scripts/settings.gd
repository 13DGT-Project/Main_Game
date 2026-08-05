extends Node2D

@onready var language_panel = $CanvasLayer/Control/Language
@onready var home_panel = $CanvasLayer/Control/Home_System
@onready var home_node = $CanvasLayer/Control/Home
@onready var language_node = $CanvasLayer/Control/Languages
@onready var language_panel_english = $CanvasLayer/Control/Languages/English
@onready var language_panel_chinese = $CanvasLayer/Control/Languages/Chinese
@onready var language_panel_japanese = $CanvasLayer/Control/Languages/Japanese
@onready var language_panel_spanish = $CanvasLayer/Control/Languages/Spanish

func _ready() -> void:
	TranslationServer.set_locale("en")

func _on_home_pressed() -> void:
	var current_style = language_panel.get_theme_stylebox("panel")
	# 2. Duplicate it to make it a unique instance
	var unique_style = current_style.duplicate()
	# 3. Change the background color property
	unique_style.bg_color = Color("#262626")
	# 4. Commit the unique stylebox back to the panel override
	language_panel.add_theme_stylebox_override("panel", unique_style)

	var current_style2 = home_panel.get_theme_stylebox("panel")
	# 2. Duplicate it to make it a unique instance
	var unique_style2 = current_style2.duplicate()
	# 3. Change the background color property
	unique_style2.bg_color = Color("#8d8d8dde")
	# 4. Commit the unique stylebox back to the panel override
	home_panel.add_theme_stylebox_override("panel", unique_style2)
	home_node.show()
	language_node.hide()

func _on_language_pressed() -> void:
	var current_style = home_panel.get_theme_stylebox("panel")
	# 2. Duplicate it to make it a unique instance
	var unique_style = current_style.duplicate()
	# 3. Change the background color property
	unique_style.bg_color = Color("#262626")
	# 4. Commit the unique stylebox back to the panel override
	home_panel.add_theme_stylebox_override("panel", unique_style)
	
	var current_style2 = language_panel.get_theme_stylebox("panel")
	# 2. Duplicate it to make it a unique instance
	var unique_style2 = current_style2.duplicate()
	# 3. Change the background color property
	unique_style2.bg_color = Color("#8d8d8dde")
	# 4. Commit the unique stylebox back to the panel override
	language_panel.add_theme_stylebox_override("panel", unique_style2)
	home_node.hide()
	language_node.show()

func _on_exit_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu/Scenes/main_menu.tscn")


func set_selected_language(selected_panel: Panel):
	var panels = [
		language_panel_english,
		language_panel_chinese,
		language_panel_japanese,
		language_panel_spanish
	]

	for panel in panels:
		var style = panel.get_theme_stylebox("panel").duplicate()

		if panel == selected_panel:
			style.bg_color = Color("#8d8d8dde") # Selected
		else:
			style.bg_color = Color("#262626") # Unselected

		panel.add_theme_stylebox_override("panel", style)

func _on_english_pressed() -> void:
	set_selected_language(language_panel_english)


func _on_chinese_pressed() -> void:
	set_selected_language(language_panel_chinese)

func _on_japanese_pressed() -> void:
	set_selected_language(language_panel_japanese)

func _on_spanish_pressed() -> void:
	set_selected_language(language_panel_spanish)
