extends Node2D

# Line equation: y = mx + b

var m: float = 0.5
var b: float = 100.0

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var x_start: float = 0.0
	var x_end: float = get_viewport_rect().size.x

	var y_start: float = m * x_start + b
	var y_end: float = m * x_end + b

	var p1 = Vector2(x_start, y_start)
	var p2 = Vector2(x_end, y_end)

	# Draw the line (Start Vector2, End Vector2, Color, Line Width, Antialiased)
	draw_line(p1, p2, Color.GREEN, 2.0, true)
