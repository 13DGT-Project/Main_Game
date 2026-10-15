extends Node2D

@onready var Auckland = $Auckland
@onready var Canterbury = $Canterbury
@onready var Waikato = $Waikato

const MAJOR_SELECT_SCENE := "res://Backend/Intro/MajorSelect.tscn"

## Easy / medium / hard colours for the difficulty label.
const DIFFICULTY_COLOURS := [Color("7fd88f"), Color("ffd166"), Color("ff7b6b")]


func _ready() -> void:
	# Fill in each university's panel from GameBackend.universities, so the
	# numbers on this screen are always the ones the game actually uses.
	_fill_info(Auckland, "Auckland")
	_fill_info(Canterbury, "Canterbury")
	_fill_info(Waikato, "Waikato")


func _fill_info(panel: Node, uni: String) -> void:
	var data: Dictionary = GameBackend.universities.get(uni, {})
	var level: int = clampi(int(data.get("difficulty", 2)), 1, 3)
	var difficulty: Label = panel.get_node("Difficulty")
	difficulty.text = "%s %s %s" % [tr("INTRO_UNI_DIFFICULTY").strip_edges(),
		"★".repeat(level) + "☆".repeat(3 - level), tr("UNI_DIFFICULTY_%d" % level)]
	difficulty.add_theme_color_override("font_color", DIFFICULTY_COLOURS[level - 1])
	var grade: Label = panel.get_node("Grade")
	grade.text = "%s %d / 100" % [tr("INTRO_UNI_GRADES").strip_edges(), int(data.get("grades_needed", 0))]
	var money: Label = panel.get_node("Money")
	money.text = "%s $%s" % [tr("INTRO_UNI_MONEY").strip_edges(), _with_commas(int(data.get("money_needed", 0)))]
	# A dark outline keeps the text readable where it sits over a photo.
	for lbl in [difficulty, grade, money]:
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		lbl.add_theme_constant_override("outline_size", 8)


## 8200 -> "8,200"
func _with_commas(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out

func _on_button_pressed() -> void:
	MusicManager.pause_music()
	get_tree().change_scene_to_file("res://Main_Game/Scenes/MainMap.tscn")
	Inventory.get_node("UI").show()


func _on_confirm_pressed() -> void:
	GameBackend.selected_university = "Auckland"
	get_tree().change_scene_to_file(MAJOR_SELECT_SCENE)


func _on_auckland_pressed() -> void:
	Auckland.show()
	Canterbury.hide()
	Waikato.hide()

func _on_confirm_2_pressed() -> void:
	GameBackend.selected_university = "Canterbury"
	get_tree().change_scene_to_file(MAJOR_SELECT_SCENE)
	
	
func _on_canterbury_pressed() -> void:
	Auckland.hide()
	Canterbury.show()
	Waikato.hide()
	

func _on_waikato_pressed() -> void:
	Waikato.show()
	Auckland.hide()
	Canterbury.hide()




func _on_confirm_3_pressed() -> void:
	GameBackend.selected_university = "Waikato"
	get_tree().change_scene_to_file(MAJOR_SELECT_SCENE)
