extends Node2D

@onready var language_panel = $CanvasLayer/Control/Language
@onready var home_panel = $CanvasLayer/Control/Home_System
@onready var home_node = $CanvasLayer/Control/Home
@onready var language_node = $CanvasLayer/Control/Languages
@onready var language_panel_english = $CanvasLayer/Control/Languages/English
@onready var language_panel_chinese = $CanvasLayer/Control/Languages/Chinese
@onready var language_panel_japanese = $CanvasLayer/Control/Languages/Japanese
@onready var language_panel_spanish = $CanvasLayer/Control/Languages/Spanish
## One slider per audio bus. The buses themselves are defined in
## Backend/Audio/default_bus_layout.tres
@onready var volume_sliders := {
	"Master": $CanvasLayer/Control/Home/Master_Volume,
	"Music": $CanvasLayer/Control/Home/Music_Volume,
	"SFX": $CanvasLayer/Control/Home/SFX_Volume,
	"Ambience": $CanvasLayer/Control/Home/Ambience_Volume,
	"UI": $CanvasLayer/Control/Home/UI_Volume,
}
@onready var volume_slider = $CanvasLayer/Control/Home/Master_Volume




func _ready() -> void:
	var locale = TranslationServer.get_locale()

	if locale.begins_with("en"):
		set_selected_language(language_panel_english)
	elif locale.begins_with("zh"):
		set_selected_language(language_panel_chinese)
	elif locale.begins_with("ja"):
		set_selected_language(language_panel_japanese)
	elif locale.begins_with("es"):
		set_selected_language(language_panel_spanish)
	_setup_volume_sliders()


## Sets every slider to its bus's current level. Done in one
## loop so adding a sixth bus later means adding one line to the dictionary
## above and one node in the scene — no new signal handler.
func _setup_volume_sliders() -> void:
	for bus in volume_sliders:
		var slider: HSlider = volume_sliders[bus]
		if slider == null:
			continue
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 1.0
		# set_value_no_signal, or setting the initial value would immediately
		# write it back and save over what was loaded.
		slider.set_value_no_signal(Audio.get_bus_percent(bus))
		if not slider.value_changed.is_connected(_on_bus_volume_changed):
			slider.value_changed.connect(_on_bus_volume_changed.bind(bus))


func _on_bus_volume_changed(value: float, bus: String) -> void:
	Audio.set_bus_percent(bus, value)

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
	TranslationServer.set_locale("en")

func _on_chinese_pressed() -> void:
	set_selected_language(language_panel_chinese)
	TranslationServer.set_locale("zh")

func _on_japanese_pressed() -> void:
	set_selected_language(language_panel_japanese)
	TranslationServer.set_locale("ja")

func _on_spanish_pressed() -> void:
	set_selected_language(language_panel_spanish)
	TranslationServer.set_locale("es")


func _on_master_volume_value_changed(value: float) -> void:
	Audio.set_bus_percent("Master", value)
