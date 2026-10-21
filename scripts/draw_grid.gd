@tool
class_name GraphGrid
extends Node2D
# Draws the graph grid: a faint line every unit, a darker line and a number every few units.
# Put this node above the axes in the scene tree so it draws underneath them.
# @tool makes it show up in the Godot editor too, not just when the game runs.

# Same scale as line_2d.gd: the board goes from -20 to 20 and 1 unit is 10 pixels
@export var units := 20:
	set(value):
		units = value
		queue_redraw()
@export var unit_px := 10.0:
	set(value):
		unit_px = value
		queue_redraw()
@export var major_every := 5:
	set(value):
		major_every = value
		queue_redraw()
@export var minor_color := Color(0, 0, 0, 0.07):
	set(value):
		minor_color = value
		queue_redraw()
@export var major_color := Color(0, 0, 0, 0.2):
	set(value):
		major_color = value
		queue_redraw()
@export var show_labels := true:
	set(value):
		show_labels = value
		queue_redraw()
@export var label_color := Color(0, 0, 0, 0.45):
	set(value):
		label_color = value
		queue_redraw()


func _draw() -> void:
	draw_grid(self, units, unit_px, major_every, minor_color, major_color,
		label_color if show_labels else Color.TRANSPARENT)


# Draws the grid on any CanvasItem, so other scripts can call it from their own _draw
# or from a draw signal: GraphGrid.draw_grid(some_node)
# A transparent label_color skips the numbers
static func draw_grid(canvas: CanvasItem, units := 20, unit_px := 10.0, major_every := 5,
		minor_color := Color(0, 0, 0, 0.07), major_color := Color(0, 0, 0, 0.2),
		label_color := Color(0, 0, 0, 0.45)) -> void:
	var half := units * unit_px
	var font := ThemeDB.fallback_font
	for i in range(-units, units + 1):
		var p := i * unit_px
		var is_major := major_every > 0 and i % major_every == 0
		var color := major_color if is_major else minor_color
		canvas.draw_line(Vector2(p, -half), Vector2(p, half), color, 1.0)
		canvas.draw_line(Vector2(-half, p), Vector2(half, p), color, 1.0)
		if is_major and i != 0 and label_color.a > 0.0:
			# Numbers along the x axis, then along the y axis (y is flipped in Godot)
			canvas.draw_string(font, Vector2(p + 2, 12), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, label_color)
			canvas.draw_string(font, Vector2(3, p - 2), str(-i), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, label_color)
