extends Node

var difficulty = 0
var TOLERANCE = 0
var volume = 0.5
var evil_mode = false
var level = 0
var slow_mode = 1
var last_game_is_daily = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	match difficulty:
		0:
			TOLERANCE = 1
		1:
			TOLERANCE = 0.5
		2:
			TOLERANCE = 0.125
		3:
			TOLERANCE = 0.005
		_:
			TOLERANCE = 0.25
