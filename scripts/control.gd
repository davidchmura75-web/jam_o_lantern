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
		functions.LINEAR:
			set_linear_visible(true)
			set_exponential_visible(false)
		functions.QUADRATIC:
			set_linear_visible(false)
			set_exponential_visible(false)
		functions.EXPONENTIAL:
			set_linear_visible(false)
			set_exponential_visible(true)
		functions.SINE:
			set_linear_visible(false)
			set_exponential_visible(false)
		functions.LOGARITHM:
			set_linear_visible(false)
			set_exponential_visible(false)
		_:
			set_linear_visible(false)
			set_exponential_visible(false)


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

func _on_linear_button_pressed() -> void:
	current_function = functions.LINEAR

func _on_quadratic_button_pressed() -> void:
	current_function = functions.QUADRATIC

func _on_draw_button_pressed() -> void:
	match current_function:
		functions.NONE:
			line_2d.clear_points()
		functions.LINEAR:
			points_control.points_hit(line_2d.draw_linear(linear_slope.value, linear_intercept.value, points))
		functions.QUADRATIC:
			line_2d.draw_general()
		functions.EXPONENTIAL:
			points_control.points_hit(line_2d.draw_exponential(exponent_a.value, exponent_b.value, exponent_h.value, exponent_k.value, points))
		functions.SINE:
			line_2d.draw_general()
		functions.LOGARITHM:
			line_2d.draw_general()
		_:
			line_2d.clear_points()

func _on_clear_button_pressed() -> void:
	line_2d.points = []

func _on_exponential_button_pressed() -> void:
	current_function = functions.EXPONENTIAL
