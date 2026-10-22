extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test_level.tscn")
	Globals.last_game_is_daily = false


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")



func _on_daily_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/daily.tscn")
	Globals.last_game_is_daily = true



func _on_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/editor.tscn")



func _on_quit_pressed() -> void:
	get_tree().quit() 
