extends Node2D
## Daily level: same as the test level, plus a stopwatch and a win screen.
## win() is called by daily_points_control.gd when the puzzle is solved.

## Scene to go to after winning. Leave empty to use the project's main scene.
@export_file("*.tscn") var menu_scene: String = ""
## Seconds to wait before the win screen pops up, so the confetti is visible first
@export var win_screen_delay: float = 1.5
## Short pause after the win screen appears before clicks count, so a stray click doesn't skip it
@export var click_guard: float = 0.4

@onready var timer_label: Label = $"CanvasLayer/Control/TimerLabel"
@onready var win_screen: Control = $"WinLayer/WinScreen"
@onready var win_time_label: Label = $"WinLayer/WinScreen/Panel/VBox/WinTime"

var elapsed: float = 0.0
var running: bool = true
var can_leave: bool = false


func _ready() -> void:
	win_screen.hide()
	timer_label.text = format_time(elapsed)


func _process(delta: float) -> void:
	if running:
		elapsed += delta
		timer_label.text = format_time(elapsed)


func _input(event: InputEvent) -> void:
	if not can_leave:
		return
	if not event.is_pressed() or event.is_echo():
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey:
		get_viewport().set_input_as_handled()
		go_to_menu()


func win() -> void:
	if not running:
		return
	running = false
	timer_label.text = format_time(elapsed)
	win_time_label.text = "Time: " + format_time(elapsed)
	if win_screen_delay > 0.0:
		await get_tree().create_timer(win_screen_delay).timeout
	win_screen.show()
	await get_tree().create_timer(click_guard).timeout
	can_leave = true


func go_to_menu() -> void:
	can_leave = false
	var target: String = menu_scene
	if target == "":
		target = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if target == "":
		push_error("No menu scene set on DailyLevel and no main scene in Project Settings")
		return
	get_tree().change_scene_to_file(target)


static func format_time(t: float) -> String:
	var minutes: int = floori(t / 60.0)
	var seconds: int = int(t) % 60
	var hundredths: int = int(t * 100.0) % 100
	return "%02d:%02d.%02d" % [minutes, seconds, hundredths]
