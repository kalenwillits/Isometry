extends Node2D

const MARKER_RADIUS: float = 12.0
const MARKER_COLOR: Color = Color(1.0, 0.3, 0.3, 1.0)  # Bright red
const OUTLINE_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)  # White outline
const OUTLINE_WIDTH: float = 2.0

func _draw() -> void:
	# Draw white outline
	draw_circle(Vector2.ZERO, MARKER_RADIUS + OUTLINE_WIDTH, OUTLINE_COLOR)

	# Draw red marker
	draw_circle(Vector2.ZERO, MARKER_RADIUS, MARKER_COLOR)

	# Draw crosshair
	var cross_size: float = MARKER_RADIUS * 0.6
	draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), OUTLINE_COLOR, 2.0)
	draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), OUTLINE_COLOR, 2.0)
