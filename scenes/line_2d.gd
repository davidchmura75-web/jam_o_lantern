extends Line2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_draw()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(self.points)
	pass

func _draw():
	# Range is pixels that you want to draw
	for x in range(-200, 200):
		var x_val = x * 0.1 # Multiplier for x, for example 0.1 reduces it from -200 to 200, to -20, 20
		# this implementation works on y functions and parametric - {x(t), y(t)}
		# parametric too op though have to ban it
		
		# this could be any function, challenge is reading user input
		# Templates could be additive, like adding trig to linear is interesting
		var y_val = 2*sin(x_val) + x_val
		
		# Y Scaling, times 10 makes it 20 tall
		# IMPORTANT - Godot flips y axis so always flip y in the point generation
		var rel_point = Vector2(x, -1 * (y_val * 10))
		var global_point = rel_point
		if y_val < 20 and y_val > -20:
			add_point(global_point)
