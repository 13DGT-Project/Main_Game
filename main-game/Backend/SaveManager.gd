extends Node

const SAVE_PATH := "user://savegame.json"


var game_data: Dictionary = {
	"intro_completed": false,

	# Player stats
	"money": 0,
	"energy": 100.0,
	"grades": 0,

	# University
	"university": "",

	# Time
	"day": 1,
	"hour": 8,
	"minute": 0,

	# Player position
	"player_position": {
		"x": 0.0,
		"y": 0.0,
		"z": 0.0
	}
}


# ============================================================
# CHECK IF SAVE EXISTS
# ============================================================

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# ============================================================
# CREATE NEW GAME
# ============================================================

func new_game() -> void:

	game_data = {
		"intro_completed": false,

		"money": 0,
		"energy": 100.0,
		"grades": 0,

		"university": "",

		"day": 1,
		"hour": 8,
		"minute": 0,

		"player_position": {
			"x": 0.0,
			"y": 0.0,
			"z": 0.0
		}
	}

	save_game()


# ============================================================
# SAVE
# ============================================================

func save_game() -> void:

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		print("ERROR: Could not open save file.")
		return

	file.store_string(JSON.stringify(game_data))
	file.close()

	print("GAME SAVED")


# ============================================================
# LOAD
# ============================================================

func load_game() -> bool:

	if not has_save():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		print("ERROR: Could not open save file.")
		return false

	var data = JSON.parse_string(file.get_as_text())

	file.close()

	if data == null:
		print("ERROR: Save file is corrupted.")
		return false

	game_data = data

	print("GAME LOADED")

	return true


# ============================================================
# DELETE SAVE
# ============================================================

func delete_save() -> void:

	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

	print("SAVE DELETED")


# ============================================================
# SAVE PLAYER POSITION
# ============================================================

func save_player_position(position: Vector3) -> void:

	game_data["player_position"] = {
		"x": position.x,
		"y": position.y,
		"z": position.z
	}


# ============================================================
# LOAD PLAYER POSITION
# ============================================================

func get_player_position() -> Vector3:

	var pos = game_data.get(
		"player_position",
		{
			"x": 0.0,
			"y": 0.0,
			"z": 0.0
		}
	)

	return Vector3(
		pos.get("x", 0.0),
		pos.get("y", 0.0),
		pos.get("z", 0.0)
	)
