extends CanvasLayer

@onready var energy_bar = $Control/Energy
@onready var sanity_bar = $Control/Sanity
@onready var thirst_bar = $Control/Thirst
@onready var time_label = $Control/TimeLabel
@onready var date_label = $Control/DateLabel
@onready var uni = $Control/University

func _ready() -> void:
	_refresh_university_label()
	GameBackend.stats_changed.connect(_refresh_from_backend)
	_refresh_from_backend()


func _refresh_university_label() -> void:
	if GameBackend.selected_university == "" or not GameBackend.universities.has(GameBackend.selected_university):
		uni.text = "No university chosen yet"
		return
	var data: Dictionary = GameBackend.universities[GameBackend.selected_university]
	uni.text = "%s — $%d / %d%%" % [GameBackend.selected_university, data.get("money_needed", 0), data.get("grades_needed", 0)]


func _refresh_from_backend() -> void:
	update_energy(GameBackend.energy)
	update_sanity(GameBackend.sanity)
	update_thirst(GameBackend.thirst)


func update_energy(value: float):
	energy_bar.value = value
		
func update_sanity(value: float):
	sanity_bar.value = value

func update_thirst(value: float):
	thirst_bar.value = value

func update_time(time_text:String):
	time_label.text = time_text

func update_date(date_text:String):
	date_label.text = date_text
	
	
