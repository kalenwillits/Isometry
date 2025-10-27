extends Node2D

const INDICATOR_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)  # White
const INDICATOR_WIDTH: float = 2.0

var viewport_rect: Rect2 = Rect2()

func set_viewport_rect(rect: Rect2) -> void:
	viewport_rect = rect
	queue_redraw()

func _draw() -> void:
	if viewport_rect.size != Vector2.ZERO:
		# Draw unfilled rectangle representing camera viewport
		draw_rect(viewport_rect, INDICATOR_COLOR, false, INDICATOR_WIDTH)
