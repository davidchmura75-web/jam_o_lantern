extends Line2D

const HEIGHT = 200
const WIDTH = 200
const TOLERANCE = 0.75
var drawing = false
# Goes up by one every draw, lets an old animated draw notice a newer one started and stop
var draw_id = 0
# Extra Line2D children, one for each piece of the graph after the first
# A single Line2D always connects every point, so a new line is needed each time the graph re-enters the screen
var extra_segments = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	draw_general()
	#print(self.points)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Clears this line and frees any extra segments from the last drawing
func clear_segments():
	for segment in extra_segments:
		segment.queue_free()
	extra_segments.clear()
	clear_points()


# Makes a new Line2D child that looks the same as this one
# Children use the parent's transform so the points line up with no offset
func new_segment() -> Line2D:
	var segment = Line2D.new()
	segment.width = width
	segment.default_color = default_color
	segment.gradient = gradient
	segment.joint_mode = joint_mode
	segment.begin_cap_mode = begin_cap_mode
	segment.end_cap_mode = end_cap_mode
	segment.antialiased = antialiased
	add_child(segment)
	extra_segments.append(segment)
	return segment


# Shared drawing for every function type, f takes an x value and returns a y value
# Returns whether the function goes through all of the given points
func plot(f: Callable, points, animate := true) -> bool:
	drawing = true
	draw_id += 1
	var my_id = draw_id
	var valid = true
	for point in points:
		var y_val = f.call(point.x)
		# NaN fails every comparison, so check it directly or an undefined function would count as valid
		if not is_finite(y_val) or abs(y_val - point.y) > TOLERANCE:
			valid = false
	clear_segments()
	# The line currently being added to, starts as this line and swaps to a new segment on each re-entry
	var segment: Line2D = self
	var segment_started = false
	var last_point_oob = true
	# Y value of the previous step, used to know which edge the graph is coming back in from
	var last_y_val = NAN
	var x_scale = 0.1
	var y_scale = 10
	# Range is pixels that you want to draw
	for x in range(-WIDTH, WIDTH):
		if animate and valid:
			await get_tree().create_timer(0.005).timeout
			# A newer draw started while this one was waiting, stop so they don't draw on top of each other
			if my_id != draw_id:
				return valid
		var x_val = x * x_scale # Multiplier for x, for example 0.1 reduces it from -200 to 200, to -20, 20
		# this implementation works on y functions and parametric - {x(t), y(t)}
		# parametric too op though have to ban it

		# this could be any function, challenge is reading user input
		# Templates could be additive, like adding trig to linear is interesting
		var y_val = f.call(x_val)
		# Y Scaling, times 10 makes it 20 tall
		# IMPORTANT - Godot flips y axis so always flip y in the point generation
		var rel_point = Vector2(x, -1 * (y_val * y_scale))
		var global_point = rel_point

		if is_nan(y_val):
			# Undefined here (like a negative base to a fractional power), leave a gap with no edge point
			last_point_oob = true
		elif y_val * y_scale < HEIGHT and y_val * y_scale > -HEIGHT:
			if last_point_oob:
				# Coming back on screen, start a new segment so it doesn't connect to where it left
				if segment_started:
					segment = new_segment()
				# Edge point goes BEFORE the current point so the line stays in x order
				# Uses the last y so it starts from the edge it actually came in from
				if x != -WIDTH and not is_nan(last_y_val):
					segment.add_point(Vector2(global_point.x - 1, -1 * HEIGHT * sign(last_y_val)))
				segment_started = true
			segment.add_point(global_point)
			last_point_oob = false
		else:
			if !last_point_oob:
				# Leaving the screen, clamp the final point to the edge it left from
				global_point.y = -1 * sign(y_val) * HEIGHT
				segment.add_point(global_point)
			last_point_oob = true
		last_y_val = y_val
	drawing = false
	return valid


func draw_general():
	# No points to check and no animation, so this runs all at once like before
	plot(func(x_val): return 3 * sin(x_val), [], false)


func draw_linear(m, b, points):
	var slope = float(m)
	var intercept = float(b)
	return await plot(func(x_val): return slope * x_val + intercept, points)


func draw_exponential(a, b, h, k, points):
	# A negative b gives NaN at most x values, those spots are left as gaps
	return await plot(func(x_val): return a * (b ** (x_val - h)) + k, points)


func draw_quadratic(a, b, c, points):
	# Standard form ax^2 + bx + c
	return await plot(func(x_val): return a * x_val * x_val + b * x_val + c, points)

func draw_sine(a, b, c, d, points):
	return await plot(func(x_val): return a * sin(b * x_val + c) + d, points)

func clear_button_points():
	if not drawing:
		clear_segments()
