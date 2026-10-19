extends Node2D

@onready var line_2d: Line2D = $"../Line2D"

var targets = load_point_rows("res://scripts/levels.txt")

@onready var confetti: GPUParticles2D = $"../PointsControl/Confetti"
@onready var confetti2: GPUParticles2D = $"../PointsControl/Confetti2"
@onready var confetti3: GPUParticles2D = $Confetti3


var level = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw():
	var radius = 4
	for point in targets[level]:
		draw_circle(Vector2(point.x*10, -1 * point.y*10), radius, Color8(255, 235, 205))

func points_hit(result: bool):
	if result:
		spawn_confetti()
		# await get_tree().create_timer(3).timeout
		line_2d.clear_points()
		level += 1
		if level == len(targets):
			level = 0
		queue_redraw()

func get_targets():
	return targets[level]

	
func spawn_confetti() -> void:
	confetti.restart()
	confetti.emitting = true
	confetti2.restart()
	confetti2.emitting = true
	confetti3.restart()
	confetti3.emitting = true

# Reads a file where each line is points like (0,1),(1,2),(4,16)
# Returns one Array[Vector2] per line, blank lines are skipped
func load_point_rows(path: String) -> Array:
	var rows = []
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Couldn't open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return rows
	# Matches one (x,y) pair, allows spaces, negatives and decimals like ( -1.5, .5 )
	var regex = RegEx.new()
	regex.compile("\\(\\s*([-+]?\\d*\\.?\\d+)\\s*,\\s*([-+]?\\d*\\.?\\d+)\\s*\\)")
	var line_number = 0
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		line_number += 1
		if line.is_empty():
			continue
		var row: Array[Vector2] = []
		for m in regex.search_all(line):
			row.append(Vector2(m.get_string(1).to_float(), m.get_string(2).to_float()))
		if row.is_empty():
			push_warning("Line %d of %s has no (x,y) points, skipping it" % [line_number, path])
			continue
		rows.append(row)
	return rows
 
