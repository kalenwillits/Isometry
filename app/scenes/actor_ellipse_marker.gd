extends Node2D

const BASE_SIZE_MULTIPLIER: float = 0.5  # Scale factor for base size to ellipse size

var marker_color: Color = Color.WHITE
var ellipse_width: float = 6.0
var ellipse_height: float = 4.0

func set_color(color: Color) -> void:
	marker_color = color
	queue_redraw()

func set_size(base_size: int) -> void:
	# Scale ellipse based on actor base size
	# If base_size is 0 or invalid, use default size
	if base_size > 0:
		ellipse_width = base_size * BASE_SIZE_MULTIPLIER
		ellipse_height = base_size * BASE_SIZE_MULTIPLIER * 0.75  # Slightly taller ratio
	else:
		# Default size
		ellipse_width = 6.0
		ellipse_height = 4.0
	queue_redraw()

func _draw() -> void:
	# Draw ellipse in group color
	draw_ellipse(Vector2.ZERO, ellipse_width, ellipse_height, marker_color)

func draw_ellipse(center: Vector2, width: float, height: float, color: Color) -> void:
	var points: PackedVector2Array = []
	var num_points: int = 24  # Fewer points than player marker for performance

	for i in range(num_points):
		var angle: float = (i / float(num_points)) * TAU
		var x: float = center.x + width * cos(angle)
		var y: float = center.y + height * sin(angle)
		points.append(Vector2(x, y))

	draw_colored_polygon(points, color)
