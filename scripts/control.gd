extends Control

@onready var linear_expression: Label = $"Linear/Linear Expression"
@onready var linear_slope: SpinBox = $"Linear/Linear Slope"
@onready var linear_intercept: SpinBox = $"Linear/Linear Intercept"

@onready var line_2d: Line2D = $"../Line2D"

@onready var exponent_expression: Label = $"Exponential/Exponent Expression"
@onready var exponent_a: SpinBox = $"Exponential/Exponent A"
@onready var exponent_h: SpinBox = $"Exponential/Exponent H"
@onready var exponent_b: SpinBox = $"Exponential/Exponent B"
@onready var exponent_k: SpinBox = $"Exponential/Exponent K"

@onready var logarithm_expression: Label = $"Logarithm/Logarithm Expression"
@onready var log_base: SpinBox = $"Logarithm/Log Base"
@onready var log_x_shift: SpinBox = $"Logarithm/Log X Shift"
@onready var log_x_power: SpinBox = $"Logarithm/Log X Power"
@onready var log_y_shift: SpinBox = $"Logarithm/Log Y Shift"

@onready var quadratic_expression: Label = $"Quadratic/Quadratic Expression"
@onready var quad_a: SpinBox = $"Quadratic/Quad A"
@onready var quad_b: SpinBox = $"Quadratic/Quad B"
@onready var quad_c: SpinBox = $"Quadratic/Quad C"

@onready var sine_expression: Label = $"Sine Wave/Sine Expression"
@onready var sine_a: SpinBox = $"Sine Wave/Sine A"
@onready var sine_b: SpinBox = $"Sine Wave/Sine B"
@onready var sine_c: SpinBox = $"Sine Wave/Sine C"
@onready var sine_d: SpinBox = $"Sine Wave/Sine D"

@onready var points_control: Node2D = $"../PointsControl"


enum functions {NONE, LINEAR, QUADRATIC, EXPONENTIAL, SINE, LOGARITHM}

var current_function = functions.NONE

var points = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	points = points_control.get_targets()
	match current_function:
		functions.NONE:
			set_linear_visible(false)
			set_exponential_visible(false)
			set_logarithm_visible(false)
			set_quadratic_visible(false)
			set_sine_visible(false)
		functions.LINEAR:
			set_linear_visible(true)
			set_exponential_visible(false)
			set_logarithm_visible(false)
			set_quadratic_visible(false)
			set_sine_visible(false)
		functions.QUADRATIC:
			set_linear_visible(false)
			set_exponential_visible(false)
			set_logarithm_visible(false)
			set_quadratic_visible(true)
			set_sine_visible(false)
		functions.EXPONENTIAL:
			set_linear_visible(false)
			set_exponential_visible(true)
			set_logarithm_visible(false)
			set_quadratic_visible(false)
			set_sine_visible(false)
		functions.SINE:
			set_linear_visible(false)
			set_exponential_visible(false)
			set_logarithm_visible(false)
			set_quadratic_visible(false)
			set_sine_visible(true)
		functions.LOGARITHM:
			set_linear_visible(false)
			set_exponential_visible(false)
			set_logarithm_visible(true)
			set_quadratic_visible(false)
			set_sine_visible(false)
		_:
			set_linear_visible(false)
			set_exponential_visible(false)
			set_logarithm_visible(false)
			set_quadratic_visible(false)
			set_sine_visible(false)


func set_linear_visible(shown: bool):
	linear_expression.visible = shown
	linear_intercept.visible = shown
	linear_slope.visible = shown

func set_exponential_visible(shown: bool):
	exponent_expression.visible = shown
	exponent_a.visible = shown
	exponent_b.visible = shown
	exponent_h.visible = shown
	exponent_k.visible = shown

func set_logarithm_visible(shown: bool):
	logarithm_expression.visible = shown
	log_base.visible = shown
	log_x_shift.visible = shown
	log_y_shift.visible = shown
	log_x_power.visible = shown

func set_quadratic_visible(shown: bool):
	quadratic_expression.visible = shown
	quad_a.visible = shown
	quad_b.visible = shown
	quad_c.visible = shown

func set_sine_visible(shown: bool):
	sine_expression.visible = shown
	sine_a.visible = shown
	sine_b.visible = shown
	sine_c.visible = shown
	sine_d.visible = shown

func _on_linear_button_pressed() -> void:
	current_function = functions.LINEAR

func _on_quadratic_button_pressed() -> void:
	current_function = functions.QUADRATIC

func _on_draw_button_pressed() -> void:
	match current_function:
		functions.NONE:
			line_2d.clear_points()
		functions.LINEAR:
			await points_control.points_hit(await line_2d.draw_linear(linear_slope.value, linear_intercept.value, points))
		functions.QUADRATIC:
			await points_control.points_hit(await line_2d.draw_quadratic(quad_a.value, quad_b.value, quad_c.value, points))
		functions.EXPONENTIAL:
			await points_control.points_hit(await line_2d.draw_exponential(exponent_a.value, exponent_b.value, exponent_h.value, exponent_k.value, points))
		functions.SINE:
			await points_control.points_hit(await line_2d.draw_sine(sine_a.value, sine_b.value, sine_c.value, sine_d.value, points))
		functions.LOGARITHM:
			await line_2d.draw_general()
		_:
			line_2d.clear_points()

func _on_clear_button_pressed() -> void:
	line_2d.clear_button_points()

func _on_exponential_button_pressed() -> void:
	current_function = functions.EXPONENTIAL

func _on_logarithm_button_pressed() -> void:
	current_function = functions.LOGARITHM


func _on_sine_button_pressed() -> void:
	current_function = functions.SINE
