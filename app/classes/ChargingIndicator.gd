extends Node2D
class_name ChargingIndicator

const BASE_SIZE_MULTIPLIER: float = 0.5  # Scale factor to match actor base size
const OUTLINE_WIDTH: float = 0.3  # Width of the charging outline
const OUTLINE_OPACITY: float = 0.2 

var charge_percent: float = 0.0  # 0.0 to 1.0
var skill_color: Color = Color.WHITE
var ellipse_width: float = 6.0
var ellipse_height: float = 4.0

class Builder extends Object:
	var this: ChargingIndicator = ChargingIndicator.new()

	func color(value: Color) -> Builder:
		this.skill_color = value
		return self

	func size(base_size: int) -> Builder:
		if base_size > 0:
			this.ellipse_width = base_size * BASE_SIZE_MULTIPLIER
			this.ellipse_height = base_size * BASE_SIZE_MULTIPLIER * 0.75
		return self

	func build() -> ChargingIndicator:
		this.name = "ChargingIndicator"
		return this

static func builder() -> Builder:
	return Builder.new()
	
func _ready() -> void:
	z_index = 1
	y_sort_enabled = false
	z_as_relative = true


func deploy(node: Node) -> void:
	node.add_child(self)
	node.move_child(self, 0)  # Position at top of hierarchy

func set_charge_progress(current_charge: float, max_charge: float) -> void:
	if max_charge > 0:
		charge_percent = clamp(current_charge / max_charge, 0.0, 1.0)
	else:
		charge_percent = 0.0
	queue_redraw()

func set_color(color: Color) -> void:
	skill_color = color
	queue_redraw()

func set_size(base_size: int) -> void:
	if base_size > 0:
		ellipse_width = base_size * BASE_SIZE_MULTIPLIER
		ellipse_height = base_size * BASE_SIZE_MULTIPLIER * 0.75
	else:
		ellipse_width = 6.0
		ellipse_height = 4.0
	queue_redraw()

func _draw() -> void:
	# Only draw if there's charge to show
	if charge_percent <= 0.0:
		return

	# Draw arc outline that grows clockwise from top (270 degrees / -PI/2)
	draw_ellipse_arc_outline(Vector2.ZERO, ellipse_width, ellipse_height, skill_color, charge_percent)

func draw_ellipse_arc_outline(center: Vector2, width: float, height: float, color: Color, fill_percent: float) -> void:
	# Number of segments for smooth arc (more = smoother)
	var total_segments: int = 48
	var segments_to_draw: int = max(1, int(total_segments * fill_percent))

	# Start angle at top of ellipse (-90 degrees = -PI/2)
	var start_angle: float = -PI / 2.0

	# Generate points for the arc
	var points: PackedVector2Array = []

	for i in range(segments_to_draw + 1):
		# Calculate angle for this point (clockwise)
		var angle: float = start_angle + (i / float(total_segments)) * TAU * fill_percent
		var x: float = center.x + width * cos(angle)
		var y: float = center.y + height * sin(angle)
		points.append(Vector2(x, y))

	# Draw the arc as a polyline with specified width and opacity
	if points.size() >= 2:
		var color_with_opacity: Color = Color(color.r, color.g, color.b, OUTLINE_OPACITY)
		draw_polyline(points, color_with_opacity, OUTLINE_WIDTH, true)  # antialiased
