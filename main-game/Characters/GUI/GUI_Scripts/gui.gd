extends CanvasLayer

@onready var energy_bar = $Control/Energy
@onready var sanity_bar = $Control/Sanity
@onready var thirst_bar = $Control/Thirst
@onready var time_label = $Control/TimeLabel
@onready var date_label = $Control/DateLabel
@onready var uni = $Control/University

func _ready() -> void:
	uni.text = str(GameBackend.universities[GameBackend.selected_university])
	GameBackend.stats_changed.connect(_refresh_from_backend)
	_refresh_from_backend()


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
	
	
