extends Node2D

const ELLIPSE_WIDTH: float = 8.0
const ELLIPSE_HEIGHT: float = 6.0
const SHADOW_OFFSET: Vector2 = Vector2(1.0, 1.0)
const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.5)  # Semi-transparent black

var marker_color: Color = Color.WHITE

func set_color(color: Color) -> void:
	marker_color = color
	queue_redraw()

func _draw() -> void:
	# Draw shadow (ellipse offset)
	draw_ellipse(SHADOW_OFFSET, ELLIPSE_WIDTH, ELLIPSE_HEIGHT, SHADOW_COLOR)

	# Draw main ellipse in group color
	draw_ellipse(Vector2.ZERO, ELLIPSE_WIDTH, ELLIPSE_HEIGHT, marker_color)

func draw_ellipse(center: Vector2, width: float, height: float, color: Color) -> void:
	var points: PackedVector2Array = []
	var num_points: int = 32  # Number of points to approximate the ellipse

	for i in range(num_points):
		var angle: float = (i / float(num_points)) * TAU
		var x: float = center.x + width * cos(angle)
		var y: float = center.y + height * sin(angle)
		points.append(Vector2(x, y))

	draw_colored_polygon(points, color)
