class_name AreaTargetingOverlay
extends Node2D

const OUTLINE_WIDTH: float = 1.0
const RANGE_INDICATOR_COLOR: Color = Color(1.0, 0.0, 0.0, 0.33)  # Red when at max range
const LINE_WIDTH: float = 1.0
const ELLIPSE_POINTS: int = 32  # Number of points to draw smooth ellipse

var radius: int = 100  # Ellipse radius in pixels
var ellipse_vertices: PackedVector2Array = []
var max_range: float = 0.0
var caster_position: Vector2 = Vector2.ZERO
var is_at_max_range: bool = false
var ellipse_color: Color = Color(1.0, 0.3, 0.0, 0.33)  # Configurable color with 33% alpha (fill, outline, and line)

func _init() -> void:
	# Apply isometric scale
	scale = Vector2(1.0, 0.5)
	z_index = 100

static func builder() -> AreaTargetingOverlayBuilder:
	return AreaTargetingOverlayBuilder.new()

func set_ellipse_radius(r: int) -> void:
	"""Set the ellipse radius and regenerate vertices"""
	radius = r
	_generate_ellipse_vertices()
	queue_redraw()

func _generate_ellipse_vertices() -> void:
	"""Generate vertices for a 2:1 ellipse"""
	ellipse_vertices.clear()
	for i in range(ELLIPSE_POINTS):
		var angle = (i / float(ELLIPSE_POINTS)) * TAU
		var x = radius * cos(angle)
		var y = radius * sin(angle)  # Will be scaled by 0.5 due to Node2D scale
		ellipse_vertices.append(Vector2(x, y))

func set_range_limit(range: float, caster_pos: Vector2) -> void:
	"""Set the maximum range from the caster"""
	max_range = range
	caster_position = caster_pos

func update_range_indicator(current_distance: float) -> void:
	"""Update whether we're at max range"""
	var was_at_max = is_at_max_range
	is_at_max_range = current_distance >= max_range - 1.0  # Small threshold

	if was_at_max != is_at_max_range:
		queue_redraw()

func _draw() -> void:
	if ellipse_vertices.size() < 3:
		return

	# Draw line from caster to ellipse edge (shortened by radius)
	if caster_position != Vector2.ZERO:
		var line_start = to_local(caster_position)
		var direction = (Vector2.ZERO - line_start).normalized()
		var line_end = line_start + direction * (line_start.length() - radius)  # Stop at near edge of ellipse
		var line_color = RANGE_INDICATOR_COLOR if is_at_max_range else ellipse_color
		draw_line(line_start, line_end, line_color, LINE_WIDTH)

	# Draw filled ellipse
	var fill_color = RANGE_INDICATOR_COLOR if is_at_max_range else ellipse_color
	draw_colored_polygon(ellipse_vertices, fill_color)

	# Draw outline - close the ellipse by appending first vertex
	var closed_ellipse = ellipse_vertices.duplicate()
	closed_ellipse.append(ellipse_vertices[0])
	var outline_color = RANGE_INDICATOR_COLOR if is_at_max_range else ellipse_color
	draw_polyline(closed_ellipse, outline_color, OUTLINE_WIDTH)

func is_point_in_ellipse(point: Vector2) -> bool:
	"""Check if a point is inside the ellipse using standard ellipse equation"""
	# Convert point to local coordinates relative to ellipse center
	var local_point = point - global_position

	# Account for isometric scaling (0.5 in Y)
	# Ellipse equation: (x/a)^2 + (y/b)^2 <= 1
	# Where a = radius, b = radius (since scale handles the 2:1 ratio)
	var scaled_x = local_point.x / radius
	var scaled_y = local_point.y / (radius * 0.5)  # Account for isometric scale

	return (scaled_x * scaled_x + scaled_y * scaled_y) <= 1.0

func get_furthest_point_distance(from_point: Vector2) -> float:
	"""Get distance from a point to the furthest edge of the ellipse"""
	# The ellipse is scaled (1.0, 0.5) creating a 2:1 aspect ratio
	# semi-major axis (horizontal): radius * 1.0 = radius
	# semi-minor axis (vertical): radius * 0.5 = radius / 2

	# Direction from the reference point to ellipse center
	var direction = (global_position - from_point).normalized()

	# Distance from ellipse center to edge in the direction away from the reference point
	# For an ellipse with semi-axes a and b, the distance to edge at angle θ is:
	# r(θ) = (a*b) / sqrt((a*sin(θ))^2 + (b*cos(θ))^2)
	# Use direction components directly to respect isometric scaling
	var a = radius  # semi-major axis (horizontal)
	var b = radius * 0.5  # semi-minor axis (vertical, due to scale)

	var cos_theta = direction.x
	var sin_theta = direction.y
	# Ellipse parametric formula with correct axis mapping
	var edge_distance = (a * b) / sqrt((a * sin_theta) * (a * sin_theta) + (b * cos_theta) * (b * cos_theta))

	# Total distance = center distance + edge distance
	var center_distance = global_position.distance_to(from_point)
	return center_distance + edge_distance

## Builder Pattern

class AreaTargetingOverlayBuilder:
	var _overlay: AreaTargetingOverlay = AreaTargetingOverlay.new()
	var _radius: int
	var _range: float
	var _caster_pos: Vector2
	var _color: Color = Color(1.0, 0.3, 0.0, 0.33)  # Default orange with 33% alpha

	func ellipse_radius(r: int) -> AreaTargetingOverlayBuilder:
		_radius = r
		return self

	func range_limit(range: float) -> AreaTargetingOverlayBuilder:
		_range = range
		return self

	func caster_position(pos: Vector2) -> AreaTargetingOverlayBuilder:
		_caster_pos = pos
		return self

	func color(hex_color: String) -> AreaTargetingOverlayBuilder:
		"""Set the ellipse color from hex string, forcing 33% alpha"""
		var parsed_color = Color(hex_color)
		parsed_color.a = 0.33  # Force 33% alpha
		_color = parsed_color
		return self

	func build() -> AreaTargetingOverlay:
		if _radius > 0:
			_overlay.set_ellipse_radius(_radius)

		_overlay.set_range_limit(_range, _caster_pos)
		_overlay.ellipse_color = _color

		return _overlay
