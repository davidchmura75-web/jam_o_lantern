extends Node2D

@onready var line_2d: Line2D = $"../Line2D"

var targets = [
	[Vector2(0,0),Vector2(2,2)],
	[Vector2(0,1),Vector2(1,2), Vector2(4,16)]
	]

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
		line_2d.clear_points()
		level += 1
		if level == len(targets):
			level = 0
		queue_redraw()
		spawn_confetti()

func get_targets():
	return targets[level]

	
func spawn_confetti() -> void:
	confetti.restart()
	confetti.emitting = true
	confetti2.restart()
	confetti2.emitting = true
	confetti3.restart()
	confetti3.emitting = true
