extends Line2D

const HEIGHT = 200
const WIDTH = 200
var TOLERANCE = 0.5
# Multiplier for x, for example 0.1 reduces it from -200 to 200, to -20, 20
const X_SCALE = 0.1
# Y Scaling, times 10 makes it 20 tall
# Keep 1 / X_SCALE equal to Y_SCALE or the evil points stop matching the graph's units in both directions
const Y_SCALE = 10
# How many graph points get drawn each frame while animating, higher is faster
# 400 samples / 8 = 50 frames, about 0.8 seconds at 60 FPS
const POINTS_PER_FRAME = 8
# Where in the evil sound to start playing from, in seconds
const EVIL_SOUND_START = 0.8

signal evil_point_hit(index)
# Emitted when the line reaches a target point it goes through, index matches the points array passed to plot
signal point_hit(index)
# Emitted at the start of every draw and when the graph is cleared, so old green points go back to normal
signal points_reset

@export var evil_color: Color = Color(0.9, 0.1, 0.1):
	set(value):
		evil_color = value
		_redraw_evil_points()
@export var evil_points: Array = []:
	set(value):
		evil_points = value
		_redraw_evil_points()

# Sound played when the graph goes through one of the points, rename the path if the child has a different name
@onready var hit_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var evil_audio_stream_player_2d: AudioStreamPlayer2D = $"../PointsControl/EVILAudioStreamPlayer2D"

var drawing = false
# Goes up by one every draw, lets an old animated draw notice a newer one started and stop
var draw_id = 0
# Extra Line2D children, one for each piece of the graph after the first
# A single Line2D always connects every point, so a new line is needed each time the graph re-enters the screen
var extra_segments = []
# Separate node the evil points are drawn on, z_index puts it above every line segment
var evil_layer: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	evil_layer = Node2D.new()
	evil_layer.z_index = 1
	add_child(evil_layer)
	evil_layer.draw.connect(_draw_evil_points)
	_redraw_evil_points()
	draw_general()
	#print(self.points)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	TOLERANCE = Globals.TOLERANCE


# Turns graph units into the pixel position used by add_point
# IMPORTANT - Godot flips y axis so always flip y in the point generation
func graph_to_pixel(v: Vector2) -> Vector2:
	return Vector2(v.x / X_SCALE, -1 * v.y * Y_SCALE)


# ---------- Evil points ----------

func add_evil_point(pos: Vector2, radius: float):
	evil_points.append([pos, max(radius, 0.0)])
	_redraw_evil_points()


func move_evil_point(index: int, pos: Vector2):
	evil_points[index][0] = pos
	_redraw_evil_points()


func set_evil_point_radius(index: int, radius: float):
	evil_points[index][1] = max(radius, 0.0)
	_redraw_evil_points()


func remove_evil_point(index: int):
	evil_points.remove_at(index)
	_redraw_evil_points()


func clear_evil_points():
	evil_points = []


func set_level_evil_points(level_evil_points):
	evil_points = level_evil_points.duplicate(true)



func _is_evil_point(entry) -> bool:
	return entry is Array and entry.size() >= 2


func _redraw_evil_points():
	if evil_layer != null:
		evil_layer.queue_redraw()


func _draw_evil_points():
	for entry in evil_points:
		if not _is_evil_point(entry):
			continue
		var center = graph_to_pixel(entry[0])
		var pixel_radius = float(entry[1]) * Y_SCALE
		evil_layer.draw_circle(center, pixel_radius, evil_color)


func get_hit_evil_points(samples) -> Array:
	var hit = []
	for index in evil_points.size():
		var entry = evil_points[index]
		if not _is_evil_point(entry):
			continue
		var center: Vector2 = entry[0]
		var radius = float(entry[1])
		for i in range(1, samples.size()):
			var a = samples[i - 1]
			var b = samples[i]
			if not is_finite(a.y) or not is_finite(b.y):
				continue
			var closest = Geometry2D.get_closest_point_to_segment(center, a, b)
			if closest.distance_to(center) < radius:
				hit.append(index)
				break
	return hit


# ---------- Graph drawing ----------

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
# Returns whether the function goes through all of the given points without touching an evil point
func plot(f: Callable, points, animate := false) -> bool:
	drawing = true
	draw_id += 1
	var my_id = draw_id
	# Range is pixels that you want to draw
	# Sample the whole function first so the evil point check is done before anything is drawn
	var samples = []
	for x in range(-WIDTH, WIDTH):
		var x_val = x * X_SCALE
		# this implementation works on y functions and parametric - {x(t), y(t)}
		# parametric too op though have to ban it

		# this could be any function, challenge is reading user input
		# Templates could be additive, like adding trig to linear is interesting
		samples.append(Vector2(x_val, f.call(x_val)))
	var valid = true
	# Pixel x -> indices of the points at that x, the sound and point_hit fire when the line reaches it
	# A dictionary so two points with the same x both get reported
	var hit_point_pixels = {}
	for index in points.size():
		var point = points[index]
		var y_val = f.call(point.x)
		# NaN fails every comparison, so check it directly or an undefined function would count as valid
		if not is_finite(y_val) or abs(y_val - point.y) > TOLERANCE:
			valid = false
		else:
			var px = clampi(roundi(point.x / X_SCALE), -WIDTH, WIDTH - 1)
			if not hit_point_pixels.has(px):
				hit_point_pixels[px] = []
			hit_point_pixels[px].append(index)
	var hit_evil_points = get_hit_evil_points(samples)
	if not hit_evil_points.is_empty():
		valid = false
	clear_segments()
	# Turn every point back to normal before this draw starts lighting them up
	points_reset.emit()
	# The line currently being added to, starts as this line and swaps to a new segment on each re-entry
	var segment: Line2D = self
	var segment_started = false
	var last_point_oob = true
	# Y value of the previous step, used to know which edge the graph is coming back in from
	var last_y_val = NAN
	# TODO - slow_mode 1 and the else branch both animate, so valid vs invalid makes no difference here
	# If one of these cases was meant to skip the animation, set that branch to false
	if Globals.slow_mode == 0:
		animate = false
	elif Globals.slow_mode == 1 and valid:
		animate = true
	elif Globals.slow_mode == 2:
		animate = true
	for i in samples.size():
		# Waiting always takes at least one frame, so draw POINTS_PER_FRAME points between each wait
		if animate and i % POINTS_PER_FRAME == 0:
			await get_tree().process_frame
			# A newer draw started while this one was waiting, stop so they don't draw on top of each other
			if my_id != draw_id:
				return valid
		var x = i - WIDTH
		if hit_point_pixels.has(x):
			hit_sound.play()
			for index in hit_point_pixels[x]:
				point_hit.emit(index)
		var y_val = samples[i].y
		# IMPORTANT - Godot flips y axis so always flip y in the point generation
		var rel_point = Vector2(x, -1 * (y_val * Y_SCALE))
		var global_point = rel_point

		if is_nan(y_val):
			# Undefined here (like a negative base to a fractional power), leave a gap with no edge point
			last_point_oob = true
		elif y_val * Y_SCALE < HEIGHT and y_val * Y_SCALE > -HEIGHT:
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
	# Play once even if several evil points were hit, starting partway into the sound
	if not hit_evil_points.is_empty():
		evil_audio_stream_player_2d.play(EVIL_SOUND_START)
	for index in hit_evil_points:
		evil_point_hit.emit(index)
	return valid


func draw_general():
	pass


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

func draw_logarithm(a, b, c, d, points):
	# Standard form ax^2 + bx + c
	return await plot(func(x_val): return (log(x_val ** a + b)/log(c)) + d, points)

func draw_sine(a,b,c,d,points):
	# Standard form asin(bx+c)+d
	return await plot(func(x_val): return (a * sin(b * x_val + c) + d), points)

func clear_button_points():
	if not drawing:
		clear_segments()
		# Clearing the graph also turns the points back to normal
		points_reset.emit()
