extends Node2D

@onready var line_2d: Line2D = $"../Line2D"

@onready var confetti_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D


func load_levels(path: String):
	points = []
	evil_points = []
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Couldn't open %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	var number = "([-+]?\\d*\\.?\\d+)"
	var regex = RegEx.new()
	regex.compile("\\(\\s*" + number + "\\s*,\\s*" + number + "\\s*(?:,\\s*" + number + "\\s*)?\\)")
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		var level_points: Array[Vector2] = []
		var level_evil_points = []
		for m in regex.search_all(line):
			var pos = Vector2(m.get_string(1).to_float(), m.get_string(2).to_float())
			if m.get_string(3).is_empty():
				level_points.append(pos)
			else:
				level_evil_points.append([pos, m.get_string(3).to_float()])
		points.append(level_points)
		evil_points.append(level_evil_points)


var points = []
var evil_points = []


@onready var confetti: GPUParticles2D = $"../PointsControl/Confetti"
@onready var confetti2: GPUParticles2D = $"../PointsControl/Confetti2"
@onready var confetti3: GPUParticles2D = $Confetti3


var level = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_levels("res://scripts/levels.txt")
	import_evil_points()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw():
	var radius = 4
	for point in points[level]:
		draw_circle(Vector2(point.x*10, -1 * point.y*10), radius, Color8(255, 235, 205))

func points_hit(result: bool):
	if result:
		spawn_confetti()
		# await get_tree().create_timer(3).timeout
		line_2d.clear_segments()
		level += 1
		if level == len(points):
			level = 0
		import_evil_points()
		queue_redraw()

func get_targets():
	return points[level]

func get_evil_points():
	return evil_points[level]

func import_evil_points():
	line_2d.set_level_evil_points(get_evil_points())

func spawn_confetti() -> void:
	confetti.restart()
	confetti.emitting = true
	confetti2.restart()
	confetti2.emitting = true
	confetti3.restart()
	confetti3.emitting = true
	confetti_sound.play()
