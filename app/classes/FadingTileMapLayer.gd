extends TileMapLayer
class_name FadingTileMapLayer

var process_delta: float = 0.0

const SCALE_TO_VIEW: float = 5.0
var tile_render_states: Dictionary = {}
var discovery_source: Actor = null

func _ready() -> void:
	add_to_group(Group.MAP_LAYER)
	visibility_changed.connect(_on_visibility_changed)
#
func calculate_distance_and_radius(coords: Vector2i) -> TileRenderState.UpdateParams:
	var primary_actor: Actor = Finder.get_primary_actor()
	var primary_actor_cell: Vector2i = local_to_map(to_local(primary_actor.global_position))
	var distance: float = primary_actor_cell.distance_to(coords)
	var viewbox_area: Area2D = primary_actor.get_node("ViewBox") # TODO - it should be any tile from within the viewbox shape
	var viewbox_collision_shape: CollisionShape2D = viewbox_area.get_children()[0]
	var viewbox_circle_shape: CircleShape2D = viewbox_collision_shape.shape
	var radius_world: float = viewbox_circle_shape.radius
	var radius_cells: float = (radius_world / (tile_set.tile_size.x + tile_set.tile_size.y)) * SCALE_TO_VIEW
	return TileRenderState.UpdateParams.create(distance, radius_cells)

func get_tile_render_state(coords: Vector2i) -> TileRenderState:
	if not tile_render_states.has(coords):
		tile_render_states[coords] = (
			TileRenderState.builder()
			.is_discovered(false)
			.is_in_view(false)
			.tint(0.0)
			.alpha(0.0)
			.build()
		)
	return tile_render_states[coords]

func use_render_tile(coords: Vector2i, tile_data: TileData) -> void:
	var tile_render_state: TileRenderState = get_tile_render_state(coords)
	
	# Check if tile is in discovery area
	var is_in_discovery: bool = is_tile_in_discovery_area(coords)
	
	if is_in_discovery:
		tile_render_state.is_discovered = true
		tile_render_state.is_in_view = true
		tile_render_state.target_tint = Style.VISIBLE_TILE_TINT
		tile_render_state.target_alpha = Style.VISIBLE_TILE_TINT
	elif tile_render_state.is_discovered:
		tile_render_state.is_in_view = false
		tile_render_state.target_tint = Style.DISCOVERED_TILE_TINT
		tile_render_state.target_alpha = Style.VISIBLE_TILE_TINT
	else:
		tile_render_state.is_in_view = false
		tile_render_state.target_tint = Style.UNDISCOVERED_TILE_TINT
		tile_render_state.target_alpha = Style.UNDISCOVERED_TILE_TINT
	
	tile_render_state.time_left = Fader.TRANSITION_TIME
	tile_render_state.tick(process_delta)
	tile_data.modulate = tile_render_state.get_modulate()
		
func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true
	
func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	get_tile_render_state(coords)
	use_render_tile(coords, tile_data)

func _process(delta: float) -> void: # TODO - consider slowing down this class
	process_delta = delta
	notify_runtime_tile_data_update()

func set_discovery_source(actor: Actor) -> void:
	discovery_source = actor

func is_tile_in_discovery_area(coords: Vector2i) -> bool:
	if discovery_source == null:
		return false
	
	var tile_world_position: Vector2 = to_global(map_to_local(coords))
	var discovery_box: Area2D = discovery_source.get_node("DiscoveryBox")
	var discovery_shape: CollisionShape2D = discovery_box.get_children()[0]
	var circle_shape: CircleShape2D = discovery_shape.shape
	
	# Get the relative position from actor to tile
	var relative_pos: Vector2 = tile_world_position - discovery_source.global_position
	
	# Apply inverse scaling to check against the unit circle
	var scaled_x: float = relative_pos.x / (circle_shape.radius * discovery_shape.scale.x)
	var scaled_y: float = relative_pos.y / (circle_shape.radius * discovery_shape.scale.y)
	
	# Check if point is inside the ellipse (scaled_x² + scaled_y² <= 1)
	return (scaled_x * scaled_x + scaled_y * scaled_y) <= 1.0

func _on_visibility_changed() -> void:
	set_process(visible)
