extends "res://scripts/points_control.gd"
## Daily version of PointsControl. Loads Daily.txt and picks one puzzle
## based on today's date: line 1 is January 1, line 2 is January 2, and so on.
## It uses its own index, so the main game's Globals.level is never touched.

@export_file("*.txt") var daily_file: String = "res://scripts/Daily.txt"

var daily_index: int = 0


func _ready() -> void:
	load_levels(daily_file)
	connect_line_signals()
	if points.is_empty():
		push_error("Daily.txt has no puzzles in it")
		return
	daily_index = _todays_index()
	import_evil_points()
	queue_redraw()


func _todays_index() -> int:
	var today: Dictionary = Time.get_date_dict_from_system()  # player's local date
	var today_unix: int = Time.get_unix_time_from_datetime_dict(today)
	var jan_1_unix: int = Time.get_unix_time_from_datetime_dict({"year": today["year"], "month": 1, "day": 1})
	var day_of_year: int = floori((today_unix - jan_1_unix) / 86400.0)  # 0 on Jan 1
	return posmod(day_of_year, points.size())


func points_hit(result: bool):
	if result:
		spawn_confetti()
		if owner.has_method("win"):
			owner.win()


func get_targets():
	if points.is_empty():
		return []
	return points[daily_index]


func get_evil_points():
	if evil_points.is_empty():
		return []
	return evil_points[daily_index]
