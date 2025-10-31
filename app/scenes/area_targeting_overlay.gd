class_name AreaTargetingOverlay
extends Node2D

const FILL_COLOR: Color = Color(1.0, 0.3, 0.0, 0.3)  # Semi-transparent orange
const OUTLINE_COLOR: Color = Color(1.0, 0.5, 0.0, 0.8)  # Bright orange outline
const OUTLINE_WIDTH: float = 2.0
const RANGE_INDICATOR_COLOR: Color = Color(1.0, 0.0, 0.0, 0.2)  # Red when at max range

var polygon_vertices: PackedVector2Array = []
var max_range: float = 0.0
var start_position: Vector2 = Vector2.ZERO
var is_at_max_range: bool = false

func _init() -> void:
	# Apply initial setup
	scale = Vector2(1.0, 0.5)
	z_index = 100

static func builder() -> AreaTargetingOverlayBuilder:
	return AreaTargetingOverlayBuilder.new()

func set_polygon(polygon_entity) -> void:
	"""Set the polygon shape from a Polygon entity"""
	if !polygon_entity:
		return

	polygon_vertices.clear()
	for vertex in polygon_entity.vertices.lookup():
		polygon_vertices.append(Vector2(vertex.x, vertex.y))

	queue_redraw()

func set_range_limit(range: float, start_pos: Vector2) -> void:
	"""Set the maximum range from the caster"""
	max_range = range
	start_position = start_pos

func update_range_indicator(current_distance: float) -> void:
	"""Update whether we're at max range"""
	var was_at_max = is_at_max_range
	is_at_max_range = current_distance >= max_range - 1.0  # Small threshold

	if was_at_max != is_at_max_range:
		queue_redraw()

func _draw() -> void:
	if polygon_vertices.size() < 3:
		return

	# Draw filled polygon
	var fill_color = RANGE_INDICATOR_COLOR if is_at_max_range else FILL_COLOR
	draw_colored_polygon(polygon_vertices, fill_color)

	# Draw outline - close the polygon by appending first vertex
	var closed_polygon = polygon_vertices.duplicate()
	closed_polygon.append(polygon_vertices[0])
	draw_polyline(closed_polygon, OUTLINE_COLOR, OUTLINE_WIDTH)

func get_world_polygon() -> PackedVector2Array:
	"""Get the polygon vertices in world space (accounting for position and scale)"""
	var world_verts: PackedVector2Array = []
	for vert in polygon_vertices:
		# Apply scale and position to get world coordinates
		var world_vert = global_position + (vert * scale)
		world_verts.append(world_vert)
	return world_verts

## Builder Pattern

class AreaTargetingOverlayBuilder:
	var _overlay: AreaTargetingOverlay
	var _polygon_entity: Entity
	var _range: float
	var _start_pos: Vector2

	func _init():
		_overlay = AreaTargetingOverlay.new()

	func polygon(polygon_entity: Entity) -> AreaTargetingOverlayBuilder:
		_polygon_entity = polygon_entity
		return self

	func range_limit(range: float) -> AreaTargetingOverlayBuilder:
		_range = range
		return self

	func start_position(pos: Vector2) -> AreaTargetingOverlayBuilder:
		_start_pos = pos
		return self

	func build() -> AreaTargetingOverlay:
		if _polygon_entity:
			_overlay.set_polygon(_polygon_entity)

		_overlay.set_range_limit(_range, _start_pos)

		return _overlay
