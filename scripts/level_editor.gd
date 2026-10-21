extends Node2D
# Level editor: place target points and evil points, then append the level to a
# levels file or write it to a new file.
# Uses the same units and file format as points_control.gd and line_2d.gd:
#   (x,y) is a target point, (x,y,r) is an evil point with radius r, one level per line.

# Same scale as line_2d.gd: 1 graph unit = 10 pixels, the board goes from -20 to 20 both ways
const UNIT_PX = 10.0
const BOARD_UNITS = 20.0
const POINT_RADIUS_PX = 4.0
# Same color as Color8(255, 235, 205) in points_control.gd
const POINT_COLOR = Color(1.0, 0.9216, 0.8039)
# How close (in pixels) the mouse has to be to grab a target point
const PICK_RADIUS_PX = 8.0
const MIN_RADIUS = 0.1
const MAX_RADIUS = 20.0
const RADIUS_STEP = 0.1
const SNAP_OPTIONS = [0.0, 0.1, 0.25, 0.5, 1.0]
const DEFAULT_SNAP = 0.5
const MAX_UNDO = 200

enum Mode { POINT, EVIL }

# Should match evil_color in line_2d.gd so the editor looks like the game
@export var evil_color: Color = Color(0.9, 0.1, 0.1)
@export var grid_minor_color: Color = Color(0, 0, 0, 0.07)
@export var grid_major_color: Color = Color(0, 0, 0, 0.2)
@export var grid_label_color: Color = Color(0, 0, 0, 0.45)
@export var hover_color: Color = Color(0, 0, 0, 0.5)
@export var select_color: Color = Color(0.15, 0.45, 1.0)
@export var error_color: Color = Color(0.85, 0.15, 0.15)
# The file the game loads in points_control.gd
@export var default_levels_path := "res://scripts/levels.txt"
# The Back button hides itself if this scene doesn't exist
@export var menu_scene_path := "res://scenes/menu.tscn"

@onready var grid_layer: Node2D = %Grid
@onready var items_layer: Node2D = %Items
@onready var point_button: Button = %PointButton
@onready var evil_button: Button = %EvilButton
@onready var radius_spin: SpinBox = %RadiusSpin
@onready var snap_option: OptionButton = %SnapOption
@onready var undo_button: Button = %UndoButton
@onready var clear_button: Button = %ClearButton
@onready var copy_button: Button = %CopyButton
@onready var append_button: Button = %AppendButton
@onready var new_file_button: Button = %NewFileButton
@onready var back_button: Button = %BackButton
@onready var info_label: Label = %InfoLabel
@onready var status_label: Label = %StatusLabel
@onready var file_dialog: FileDialog = %FileDialog
@onready var warning_dialog: ConfirmationDialog = %WarningDialog

# Same layout as the game: target points are Vector2, evil points are [Vector2 center, float radius]
var points: Array[Vector2] = []
var evil_points: Array = []

var mode: int = Mode.POINT
# An item is {} for nothing, or {"kind": Mode.POINT or Mode.EVIL, "index": int}
var selected: Dictionary = {}
var hovered: Dictionary = {}

var mouse_units := Vector2.ZERO
var mouse_inside := false

var dragging := false
var drag_item: Dictionary = {}
var drag_offset := Vector2.ZERO
var drag_snapshot: Dictionary = {}

var undo_stack: Array = []
# Repeated small edits with the same tag (like scrolling one circle's radius) share one undo step
var last_undo_tag := ""

# Stops the radius SpinBox from editing the selection while code is updating it
var syncing_ui := false
var save_append := true
var last_path := ""


func _ready() -> void:
	grid_layer.draw.connect(_draw_grid)
	items_layer.draw.connect(_draw_items)

	point_button.pressed.connect(_set_mode.bind(Mode.POINT))
	evil_button.pressed.connect(_set_mode.bind(Mode.EVIL))
	_set_mode(Mode.POINT)

	radius_spin.min_value = MIN_RADIUS
	radius_spin.max_value = MAX_RADIUS
	radius_spin.step = RADIUS_STEP
	radius_spin.value_changed.connect(_on_radius_spin_changed)

	snap_option.clear()
	for step in SNAP_OPTIONS:
		snap_option.add_item("Off" if step == 0.0 else _fmt(step))
	snap_option.select(SNAP_OPTIONS.find(DEFAULT_SNAP))

	undo_button.pressed.connect(undo)
	clear_button.pressed.connect(_on_clear_pressed)
	copy_button.pressed.connect(_on_copy_pressed)
	append_button.pressed.connect(_request_save.bind(true))
	new_file_button.pressed.connect(_request_save.bind(false))
	back_button.visible = ResourceLoader.exists(menu_scene_path)
	back_button.pressed.connect(func(): get_tree().change_scene_to_file(menu_scene_path))

	# res:// is only writable when running from the Godot editor, exported builds have to use user://
	if OS.has_feature("editor"):
		file_dialog.access = FileDialog.ACCESS_RESOURCES
		last_path = default_levels_path
	else:
		file_dialog.access = FileDialog.ACCESS_USERDATA
		last_path = "user://levels.txt"
	file_dialog.filters = PackedStringArray(["*.txt ; Level files"])
	file_dialog.mode_overrides_title = false
	file_dialog.file_selected.connect(_on_file_selected)
	warning_dialog.confirmed.connect(_open_file_dialog)

	_set_status("Click the board to place points.")


func _process(_delta: float) -> void:
	mouse_units = _mouse_units()
	mouse_inside = _in_board(mouse_units)

	if dragging:
		# Catches a release that happened over a button or outside the window
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_end_drag()
		else:
			_set_item_pos(drag_item, _place_pos(mouse_units + drag_offset))
	else:
		hovered = _pick(mouse_units) if mouse_inside else {}

	var coords := "x: -   y: -"
	if mouse_inside:
		var p := _place_pos(mouse_units)
		coords = "x: %s   y: %s" % [_fmt(p.x), _fmt(p.y)]
	info_label.text = "%s      Points: %d   Evil: %d" % [coords, points.size(), evil_points.size()]
	undo_button.disabled = undo_stack.is_empty()

	items_layer.queue_redraw()


# ---------- Input ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventKey and event.pressed and not event.echo:
		_on_key(event)


func _on_mouse_button(event: InputEventMouseButton) -> void:
	var pos := _mouse_units()
	if not _in_board(pos):
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				var hit := _pick(pos)
				# Shift-click always places, so you can put something inside a big evil point
				if hit.is_empty() or event.shift_pressed:
					_place(pos)
				else:
					_select(hit)
					_begin_drag(hit, pos)
		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				var hit := _pick(pos)
				if not hit.is_empty():
					_delete(hit)
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_scroll_radius(pos, RADIUS_STEP)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_scroll_radius(pos, -RADIUS_STEP)
		_:
			return
	get_viewport().set_input_as_handled()


func _on_key(event: InputEventKey) -> void:
	if event.keycode == KEY_Z and event.is_command_or_control_pressed():
		undo()
	elif event.keycode == KEY_1:
		_set_mode(Mode.POINT)
	elif event.keycode == KEY_2:
		_set_mode(Mode.EVIL)
	elif event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
		if not selected.is_empty():
			_delete(selected)
	elif event.keycode == KEY_ESCAPE:
		selected = {}
	else:
		return
	get_viewport().set_input_as_handled()


# ---------- Editing ----------

func _set_mode(new_mode: int) -> void:
	mode = new_mode
	point_button.button_pressed = mode == Mode.POINT
	evil_button.button_pressed = mode == Mode.EVIL


func _place(pos: Vector2) -> void:
	_push_undo()
	var p := _place_pos(pos)
	if mode == Mode.POINT:
		points.append(p)
		_select({"kind": Mode.POINT, "index": points.size() - 1})
	else:
		evil_points.append([p, float(radius_spin.value)])
		_select({"kind": Mode.EVIL, "index": evil_points.size() - 1})


func _delete(item: Dictionary) -> void:
	_push_undo()
	if item.kind == Mode.POINT:
		points.remove_at(item.index)
	else:
		evil_points.remove_at(item.index)
	selected = {}
	hovered = {}


func _select(item: Dictionary) -> void:
	selected = item
	if not item.is_empty() and item.kind == Mode.EVIL:
		_sync_radius_spin(evil_points[item.index][1])


func _begin_drag(item: Dictionary, pos: Vector2) -> void:
	dragging = true
	drag_item = item
	# Keeps the item from jumping to the cursor when it's grabbed off-center
	drag_offset = _item_pos(item) - pos
	drag_snapshot = _snapshot()


func _end_drag() -> void:
	dragging = false
	# Only a drag that actually moved something becomes an undo step
	if points != drag_snapshot.points or evil_points != drag_snapshot.evil:
		_add_undo_snapshot(drag_snapshot)
		last_undo_tag = ""


# Scrolling over an evil point resizes it, otherwise it resizes the selected evil point,
# otherwise it changes the radius the next evil point will get
func _scroll_radius(pos: Vector2, amount: float) -> void:
	var hit := _pick(pos)
	if not hit.is_empty() and hit.kind == Mode.EVIL:
		_select(hit)
	if not selected.is_empty() and selected.kind == Mode.EVIL:
		var radius: float = evil_points[selected.index][1]
		_set_evil_radius(selected.index, radius + amount)
	else:
		radius_spin.value = radius_spin.value + amount


func _on_radius_spin_changed(value: float) -> void:
	if syncing_ui:
		return
	if not selected.is_empty() and selected.kind == Mode.EVIL:
		_set_evil_radius(selected.index, value)


func _set_evil_radius(index: int, radius: float) -> void:
	radius = clampf(snappedf(radius, RADIUS_STEP), MIN_RADIUS, MAX_RADIUS)
	if is_equal_approx(radius, float(evil_points[index][1])):
		return
	_push_undo("radius:%d" % index)
	evil_points[index][1] = radius
	_sync_radius_spin(radius)


func _sync_radius_spin(radius: float) -> void:
	syncing_ui = true
	radius_spin.value = radius
	syncing_ui = false


func _on_clear_pressed() -> void:
	if points.is_empty() and evil_points.is_empty():
		return
	_push_undo()
	points.clear()
	evil_points.clear()
	selected = {}
	_set_status("Cleared. Ctrl+Z brings it back.")


func _on_copy_pressed() -> void:
	DisplayServer.clipboard_set(_level_line())
	_set_status("Copied the level line to the clipboard.")


# ---------- Undo ----------

func _snapshot() -> Dictionary:
	return {"points": points.duplicate(), "evil": evil_points.duplicate(true)}


func _push_undo(tag := "") -> void:
	if tag != "" and tag == last_undo_tag:
		return
	_add_undo_snapshot(_snapshot())
	last_undo_tag = tag


func _add_undo_snapshot(snapshot: Dictionary) -> void:
	undo_stack.append(snapshot)
	if undo_stack.size() > MAX_UNDO:
		undo_stack.pop_front()


func undo() -> void:
	if undo_stack.is_empty() or dragging:
		return
	var snapshot: Dictionary = undo_stack.pop_back()
	points.assign(snapshot.points)
	evil_points = snapshot.evil
	selected = {}
	hovered = {}
	last_undo_tag = ""


# ---------- Helpers ----------

func _mouse_units() -> Vector2:
	var local := items_layer.get_local_mouse_position()
	# Godot's y axis points down, the graph's points up
	return Vector2(local.x / UNIT_PX, -local.y / UNIT_PX)


func _to_px(v: Vector2) -> Vector2:
	return Vector2(v.x * UNIT_PX, -v.y * UNIT_PX)


func _in_board(pos: Vector2) -> bool:
	return absf(pos.x) <= BOARD_UNITS and absf(pos.y) <= BOARD_UNITS


func _place_pos(pos: Vector2) -> Vector2:
	var step: float = SNAP_OPTIONS[snap_option.selected]
	# With snapping off, still round to hundredths so the file stays readable
	if step <= 0.0:
		step = 0.01
	pos = pos.snapped(Vector2(step, step))
	return pos.clamp(Vector2(-BOARD_UNITS, -BOARD_UNITS), Vector2(BOARD_UNITS, BOARD_UNITS))


func _item_pos(item: Dictionary) -> Vector2:
	if item.kind == Mode.POINT:
		return points[item.index]
	return evil_points[item.index][0]


func _set_item_pos(item: Dictionary, pos: Vector2) -> void:
	if item.kind == Mode.POINT:
		points[item.index] = pos
	else:
		evil_points[item.index][0] = pos


# Target points win over evil points since they're small and usually drawn inside circles.
# Among evil points the smallest one under the cursor wins, so small circles inside big ones stay grabbable
func _pick(pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_dist := PICK_RADIUS_PX / UNIT_PX
	for i in points.size():
		var d := points[i].distance_to(pos)
		if d <= best_dist:
			best_dist = d
			best = {"kind": Mode.POINT, "index": i}
	if not best.is_empty():
		return best
	var best_radius := INF
	for i in evil_points.size():
		var center: Vector2 = evil_points[i][0]
		var radius: float = evil_points[i][1]
		var reach := maxf(radius, PICK_RADIUS_PX / UNIT_PX)
		if center.distance_to(pos) <= reach and radius < best_radius:
			best_radius = radius
			best = {"kind": Mode.EVIL, "index": i}
	return best


func _fmt(v: float) -> String:
	var s := String.num(v, 3)
	return "0" if s == "-0" else s


func _set_status(text: String, is_error := false) -> void:
	status_label.text = text
	if is_error:
		status_label.add_theme_color_override("font_color", error_color)
	else:
		status_label.remove_theme_color_override("font_color")


# ---------- Drawing ----------

func _draw_grid() -> void:
	var half := BOARD_UNITS * UNIT_PX
	var font := ThemeDB.fallback_font
	for i in range(-int(BOARD_UNITS), int(BOARD_UNITS) + 1):
		var p := i * UNIT_PX
		var color := grid_major_color if i % 5 == 0 else grid_minor_color
		grid_layer.draw_line(Vector2(p, -half), Vector2(p, half), color, 1.0)
		grid_layer.draw_line(Vector2(-half, p), Vector2(half, p), color, 1.0)
		if i % 5 == 0 and i != 0:
			grid_layer.draw_string(font, Vector2(p + 2, 12), str(i), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, grid_label_color)
			grid_layer.draw_string(font, Vector2(3, p - 2), str(-i), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, grid_label_color)


func _draw_items() -> void:
	for entry in evil_points:
		items_layer.draw_circle(_to_px(entry[0]), float(entry[1]) * UNIT_PX, evil_color)
	for p in points:
		items_layer.draw_circle(_to_px(p), POINT_RADIUS_PX, POINT_COLOR)

	if not hovered.is_empty() and hovered != selected:
		_draw_outline(hovered, hover_color)
	if not selected.is_empty():
		_draw_outline(selected, select_color)

	# Faded preview of what a click would place
	if mouse_inside and not dragging and (hovered.is_empty() or Input.is_key_pressed(KEY_SHIFT)):
		var ghost := _to_px(_place_pos(mouse_units))
		if mode == Mode.POINT:
			items_layer.draw_circle(ghost, POINT_RADIUS_PX, Color(POINT_COLOR, 0.6))
			items_layer.draw_arc(ghost, POINT_RADIUS_PX + 1, 0, TAU, 24, hover_color, 1.0, true)
		else:
			items_layer.draw_circle(ghost, float(radius_spin.value) * UNIT_PX, Color(evil_color, 0.35))


func _draw_outline(item: Dictionary, color: Color) -> void:
	var center := _to_px(_item_pos(item))
	var radius := POINT_RADIUS_PX + 3
	if item.kind == Mode.EVIL:
		radius = float(evil_points[item.index][1]) * UNIT_PX + 2
	items_layer.draw_arc(center, radius, 0, TAU, 64, color, 2.0, true)


# ---------- Saving ----------

func _request_save(append: bool) -> void:
	if points.is_empty():
		_set_status("Add at least one point first. A level with no points is beaten by any function.", true)
		return
	save_append = append
	var problems := _find_problems()
	if problems.is_empty():
		_open_file_dialog()
	else:
		warning_dialog.dialog_text = "This level might be impossible:\n\n%s\n\nSave anyway?" % "\n".join(problems)
		warning_dialog.popup_centered()


func _open_file_dialog() -> void:
	if save_append:
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.title = "Append level to file"
		file_dialog.ok_button_text = "Append"
	else:
		file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		file_dialog.title = "Save level as a new file"
		file_dialog.ok_button_text = "Save"
	file_dialog.current_path = last_path
	file_dialog.popup_centered_ratio(0.6)
	if save_append:
		# Godot keeps the Open button greyed out until a file is clicked in the list,
		# even when the file name is already filled in. Wait for the dialog to finish
		# its own setup, then turn the button on if the filled-in file exists.
		await get_tree().process_frame
		if file_dialog.visible and file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
			file_dialog.get_ok_button().disabled = not FileAccess.file_exists(file_dialog.current_path)


func _on_file_selected(path: String) -> void:
	last_path = path
	var line := _level_line()
	var err := _append_line(path, line) if save_append else _write_new_file(path, line)
	if err == OK and not _file_ends_with_line(path, line):
		# The write said it worked but the level isn't in the file, treat that as a failure too
		err = ERR_FILE_CANT_WRITE
	if err != OK:
		var message := "Couldn't write %s: %s" % [path, error_string(err)]
		push_error(message)
		_set_status(message, true)
		return
	var count := _count_levels(path)
	var verb := "Appended" if save_append else "Saved"
	print("%s level %d to %s: %s" % [verb, count, path, line])
	_set_status("%s to %s. It's level %d (Globals.level = %d)." % [verb, path.get_file(), count, count - 1])


# Builds the line in the same format as levels.txt, target points sorted by x, then evil points
func _level_line() -> String:
	var sorted_points: Array[Vector2] = points.duplicate()
	sorted_points.sort_custom(func(a, b): return a.x < b.x)
	var parts := PackedStringArray()
	for p in sorted_points:
		parts.append("(%s,%s)" % [_fmt(p.x), _fmt(p.y)])
	for entry in evil_points:
		var center: Vector2 = entry[0]
		parts.append("(%s,%s,%s)" % [_fmt(center.x), _fmt(center.y), _fmt(entry[1])])
	return ",".join(parts)


# Reads the whole file and writes it back with the new line on the end.
# Rewriting is more reliable than READ_WRITE + seek, which misbehaves on some platforms
func _append_line(path: String, line: String) -> Error:
	if not FileAccess.file_exists(path):
		return _write_new_file(path, line)
	var text := FileAccess.get_file_as_string(path)
	var read_err := FileAccess.get_open_error()
	if read_err != OK:
		return read_err
	# Normalise Windows line endings and make sure the last level ends with a newline
	text = text.replace("\r\n", "\n")
	if not text.is_empty() and not text.ends_with("\n"):
		text += "\n"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text + line + "\n")
	file.close()
	return OK


# Reads the file back to check the level actually landed on the last line
func _file_ends_with_line(path: String, line: String) -> bool:
	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	return not lines.is_empty() and lines[lines.size() - 1].strip_edges() == line


func _write_new_file(path: String, line: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(line + "\n")
	file.close()
	return OK


# Same rule as load_levels in points_control.gd: every non-empty line is a level
func _count_levels(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var count := 0
	while not file.eof_reached():
		if not file.get_line().strip_edges().is_empty():
			count += 1
	return count


# Catches levels that can't be beaten, using the same tolerance the game checks with
func _find_problems() -> PackedStringArray:
	var problems := PackedStringArray()
	var tolerance: float = Globals.TOLERANCE
	for i in points.size():
		for j in range(i + 1, points.size()):
			var a := points[i]
			var b := points[j]
			if is_equal_approx(a.x, b.x) and absf(a.y - b.y) > 2 * tolerance:
				problems.append("- (%s,%s) and (%s,%s) have the same x, so one function can't go through both."
					% [_fmt(a.x), _fmt(a.y), _fmt(b.x), _fmt(b.y)])
	for p in points:
		for entry in evil_points:
			var center: Vector2 = entry[0]
			var radius: float = entry[1]
			# A function that hits p passes within the tolerance of it, so it'd be inside the circle too
			if p.distance_to(center) + tolerance < radius:
				problems.append("- (%s,%s) is inside an evil point, so any function through it hits the evil point."
					% [_fmt(p.x), _fmt(p.y)])
				break
	return problems
