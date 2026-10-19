extends Line2D

const HEIGHT = 200
const WIDTH = 200
const TOLERANCE = 0.5
var drawing = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	draw_general()
	#print(self.points)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func draw_general():
	drawing = true
	clear_points()
	# Range is pixels that you want to draw
	for x in range(-WIDTH, WIDTH):
		var x_val = x * 0.1 # Multiplier for x, for example 0.1 reduces it from -200 to 200, to -20, 20
		# this implementation works on y functions and parametric - {x(t), y(t)}
		# parametric too op though have to ban it
		
		# this could be any function, challenge is reading user input
		# Templates could be additive, like adding trig to linear is interesting
		var y_val = 3*sin(x_val)
		var y_scale = 10
		# Y Scaling, times 10 makes it 20 tall
		# IMPORTANT - Godot flips y axis so always flip y in the point generation
		var rel_point = Vector2(x, -1 * (y_val * y_scale))
		var global_point = rel_point
		if y_val * y_scale < HEIGHT  and y_val * y_scale > -HEIGHT:
			add_point(global_point)
	drawing = false

func draw_linear(m, b, points):
	drawing = true
	var slope = float(m)
	var intercept = float(b)
	var last_point_oob = true
	var valid = true
	for point in points:
		var x_val = point.x
		var y_val = slope*x_val + intercept
		if abs(y_val - point.y) > TOLERANCE:
			valid = false
	clear_points()
	# Range is pixels that you want to draw
	for x in range(-WIDTH, WIDTH):
		if valid:
			await get_tree().create_timer(0.005).timeout
		var x_scale = 0.1
		var x_val = x * x_scale # Multiplier for x, for example 0.1 reduces it from -200 to 200, to -20, 20
		# this implementation works on y functions and parametric - {x(t), y(t)}
		# parametric too op though have to ban it
		
		# this could be any function, challenge is reading user input
		# Templates could be additive, like adding trig to linear is interesting
		var y_val = slope*x_val + intercept
		var y_scale = 10
		# Y Scaling, times 10 makes it 20 tall
		# IMPORTANT - Godot flips y axis so always flip y in the point generation
		var rel_point = Vector2(x, -1 * (y_val * y_scale))
		var global_point = rel_point
		
		if y_val * y_scale < HEIGHT and y_val * y_scale > -HEIGHT:
			add_point(global_point)
			if last_point_oob:
				add_point(Vector2(global_point.x - 1, -1 * HEIGHT * sign(y_val)))
			last_point_oob = false
		else:
			if !last_point_oob:
				global_point.y = -1 * sign(y_val) * HEIGHT
				add_point(global_point)
				last_point_oob = true
	drawing = false
	return valid


func draw_exponential(a, b, h, k, points):
	drawing = true
	var valid = true
	for point in points:
		var x_val = point.x
		var y_val = a * (b ** (x_val - h)) + k
		if abs(y_val - point.y) > TOLERANCE:
			valid = false
	var last_point_oob = true
	clear_points()
	# Range is pixels that you want to draw
	for x in range(-WIDTH, WIDTH):
		if valid:
			await get_tree().create_timer(0.005).timeout
		var x_scale = 0.1
		var x_val = x * x_scale # Multiplier for x, for example 0.1 reduces it from -200 to 200, to -20, 20
		# this implementation works on y functions and parametric - {x(t), y(t)}
		# parametric too op though have to ban it
		
		# this could be any function, challenge is reading user input
		# Templates could be additive, like adding trig to linear is interesting
		var y_val = a * (b ** (x_val - h)) + k
		var y_scale = 10
		# Y Scaling, times 10 makes it 20 tall
		# IMPORTANT - Godot flips y axis so always flip y in the point generation
		var rel_point = Vector2(x, -1 * (y_val * y_scale))
		var global_point = rel_point
		
		if y_val * y_scale < HEIGHT and y_val * y_scale > -HEIGHT:
			add_point(global_point)
			if last_point_oob and x != -WIDTH:
				add_point(Vector2(global_point.x - 1, -1 * HEIGHT * sign(y_val)))
			last_point_oob = false
		else:
			if !last_point_oob:
				global_point.y = -1 * sign(y_val) * HEIGHT
				add_point(global_point)
				last_point_oob = true
	drawing = false
	return valid



func clear_button_points():
	if not drawing:
		self.points = []
