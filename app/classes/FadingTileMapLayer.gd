extends TileMapLayer
class_name FadingTileMapLayer

var process_delta: float = 0.0

const UPDATE_INTERVAL: float = 0.01
var tile_render_states: Dictionary = {}
var discovery_source: Actor = null
var update_timer: float = 0.0

func _ready() -> void:
	add_to_group(Group.MAP_LAYER)
	visibility_changed.connect(_on_visibility_changed)

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
	
	var previous_target_tint = tile_render_state.target_tint
	var previous_target_alpha = tile_render_state.target_alpha
	
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
	
	# Only reset time_left if target values changed
	if previous_target_tint != tile_render_state.target_tint or previous_target_alpha != tile_render_state.target_alpha:
		tile_render_state.time_left = Fader.TRANSITION_TIME
	
	tile_render_state.tick(process_delta)
	tile_data.modulate = tile_render_state.get_modulate()
		
func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true
	
func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	get_tile_render_state(coords)
	use_render_tile(coords, tile_data)

func _process(delta: float) -> void:
	process_delta = delta
	update_timer += delta
	
	# Only update tiles at intervals instead of every frame
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		notify_runtime_tile_data_update()

func set_discovery_source(actor: Actor) -> void:
	discovery_source = actor

func is_tile_in_discovery_area(coords: Vector2i) -> bool:
	if discovery_source == null:
		return false
	
	var tile_world_position: Vector2 = to_global(map_to_local(coords))
	var discovery_box: Area2D = discovery_source.get_node("DiscoveryBox")
	var discovery_shape: CollisionShape2D = discovery_box.get_children().pop_front()
	var circle_shape: CircleShape2D = discovery_shape.shape
	
	# Get the relative position from discovery shape center to tile
	var discovery_shape_world_pos: Vector2 = discovery_source.global_position + discovery_shape.position
	var relative_pos: Vector2 = tile_world_position - discovery_shape_world_pos
	
	# Apply inverse scaling to check against the unit circle
	var scaled_x: float = relative_pos.x / (circle_shape.radius * discovery_shape.scale.x)
	var scaled_y: float = relative_pos.y / (circle_shape.radius * discovery_shape.scale.y)
	
	# Check if point is inside the ellipse (scaled_x² + scaled_y² <= 1)
	return (scaled_x * scaled_x + scaled_y * scaled_y) <= 1.0

func pack_discovered_tiles() -> Array:
	var discovered_tiles: Array = []
	for coords: Vector2i in tile_render_states.keys():
		var tile_state: TileRenderState = tile_render_states[coords]
		if tile_state.is_discovered:
			discovered_tiles.append(str(coords))
	return discovered_tiles

func unpack_discovered_tiles(packed_tiles: Array) -> void:
	for coords_string: String in packed_tiles:
		# Parse format "(x, y)" to Vector2i
		var cleaned = coords_string.strip_edges().trim_prefix("(").trim_suffix(")")
		var parts = cleaned.split(",")
		var coords: Vector2i = Vector2i(parts[0].to_int(), parts[1].to_int())
		
		var tile_state: TileRenderState = get_tile_render_state(coords)
		tile_state.is_discovered = true
		# Set appropriate visual state for discovered tiles
		tile_state.target_tint = Style.DISCOVERED_TILE_TINT
		tile_state.target_alpha = Style.VISIBLE_TILE_TINT
		tile_state.time_left = Fader.TRANSITION_TIME

func _on_visibility_changed() -> void:
	set_process(visible)
