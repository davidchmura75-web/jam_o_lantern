extends Control

@onready var difficulty: OptionButton = $VBoxContainer/HBoxContainer3/Difficulty

@export var bus_name: String = "Master"
var bus_index: int

@onready var sfx_volume: HSlider = $VBoxContainer/HBoxContainer/SFX_Volume
@onready var slow_mode: OptionButton = $VBoxContainer/HBoxContainer4/SlowMode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	difficulty.selected = Globals.difficulty
	slow_mode.selected = Globals.slow_mode
	bus_index = AudioServer.get_bus_index(bus_name)
	# Initialize slider to current bus volume
	sfx_volume.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_to_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test_level.tscn")


func _on_back_to_home_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")


func _on_sfx_volume_value_changed(value: float) -> void:
	Globals.volume = value
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(Globals.volume))
	

func _on_option_button_item_selected(index: int) -> void:
	Globals.difficulty = index


func _on_check_button_toggled(toggled_on: bool) -> void:
	Globals.evil_mode = toggled_on


func _on_slow_mode_item_selected(index: int) -> void:
	Globals.slow_mode = index
