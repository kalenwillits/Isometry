extends CanvasLayer

@onready var viewport: SubViewport = $Overlay/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport
@onready var viewport_camera: Camera2D = $Overlay/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport/Camera
@onready var player_marker: Node2D = $Overlay/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport/PlayerMarker

const TILE_SIZE: Vector2 = Vector2(32, 16)  # Isometric tile size from Map.gd
const PLAYER_MARKER_RADIUS: float = 8.0
const UPDATE_FPS: int = 10

var update_timer: float = 0.0
var update_interval: float = 1.0 / UPDATE_FPS

func _ready() -> void:
	visible = false
	add_to_group(Group.MAP_VIEW)

func open_view() -> void:
	Logger.info("Opening map view", self)

	var primary_actor: Actor = Finder.get_primary_actor()
	if not primary_actor:
		Logger.warn("Cannot open map view: primary actor not found", self)
		return

	# Get the primary actor's current map
	var map_key: String = primary_actor.map
	Logger.debug("Primary actor map key: %s" % map_key, self)

	if map_key.is_empty():
		Logger.warn("Cannot open map view: primary actor has no map", self)
		return

	# Try multiple methods to find the map node
	var map_node = Finder.select(map_key) as Map
	if not map_node:
		# Try getting it from World node
		var world = Finder.select(Group.WORLD)
		if world:
			map_node = world.get_node_or_null(map_key) as Map
			Logger.debug("Tried getting map from World node", self)

	if not map_node:
		# Try using get_tree to find it in the group
		map_node = get_tree().get_first_node_in_group(map_key) as Map
		Logger.debug("Tried getting map from tree group", self)

	if not map_node:
		Logger.warn("Cannot open map view: map node not found: %s" % map_key, self)
		Logger.warn("Available groups: %s" % str(get_tree().get_nodes_in_group(Group.MAP)), self)
		return

	Logger.debug("Found map node: %s" % map_node.name, self)

	# Clear previous map content
	clear_viewport()

	# Clone map layers with only discovered tiles
	clone_map_layers(map_node, primary_actor)

	# Position player marker
	position_player_marker(primary_actor)

	# Calculate zoom to fit discovered area
	calculate_and_set_zoom(primary_actor)

	Logger.info("Map view opened successfully", self)
	visible = true

func close_view() -> void:
	visible = false
	clear_viewport()

func clear_viewport() -> void:
	# Remove all children except camera and player marker
	for child in viewport.get_children():
		if child != viewport_camera and child != player_marker:
			child.queue_free()

func clone_map_layers(map_node: Map, primary_actor: Actor) -> void:
	# Get all TileMapLayer children from the map
	var layers = map_node.get_children().filter(func(child): return child is TileMapLayer)

	for layer in layers:
		var original_layer: TileMapLayer = layer as TileMapLayer

		# Create a simplified TileMapLayer (not FadingTileMapLayer)
		var cloned_layer := TileMapLayer.new()
		cloned_layer.name = original_layer.name + "_Clone"
		cloned_layer.tile_set = original_layer.tile_set
		cloned_layer.y_sort_enabled = original_layer.y_sort_enabled
		cloned_layer.z_index = original_layer.z_index
		cloned_layer.z_as_relative = original_layer.z_as_relative

		# Copy only discovered tiles
		if original_layer is FadingTileMapLayer:
			var fading_layer: FadingTileMapLayer = original_layer as FadingTileMapLayer

			for coords in fading_layer.tile_render_states.keys():
				var tile_state = fading_layer.tile_render_states[coords]
				if tile_state.is_discovered:
					var source_id = original_layer.get_cell_source_id(coords)
					var atlas_coords = original_layer.get_cell_atlas_coords(coords)
					var alternative_tile = original_layer.get_cell_alternative_tile(coords)

					if source_id != -1:  # Valid tile
						cloned_layer.set_cell(coords, source_id, atlas_coords, alternative_tile)
		else:
			# If not a FadingTileMapLayer, copy all tiles (fallback)
			for coords in original_layer.get_used_cells():
				var source_id = original_layer.get_cell_source_id(coords)
				var atlas_coords = original_layer.get_cell_atlas_coords(coords)
				var alternative_tile = original_layer.get_cell_alternative_tile(coords)

				if source_id != -1:
					cloned_layer.set_cell(coords, source_id, atlas_coords, alternative_tile)

		viewport.add_child(cloned_layer)

func position_player_marker(primary_actor: Actor) -> void:
	# Position the player marker at the primary actor's location
	player_marker.global_position = primary_actor.global_position
	player_marker.queue_redraw()

func calculate_and_set_zoom(primary_actor: Actor) -> void:
	# Collect all discovered tile coordinates
	var discovered_coords: Array[Vector2i] = []

	var map_key: String = primary_actor.map
	var map_node = Finder.select(map_key) as Map

	# Try alternative lookup methods if not found
	if not map_node:
		var world = Finder.select(Group.WORLD)
		if world:
			map_node = world.get_node_or_null(map_key) as Map

	if not map_node:
		map_node = get_tree().get_first_node_in_group(map_key) as Map

	if not map_node:
		return

	var layers = map_node.get_children().filter(func(child): return child is TileMapLayer)

	for layer in layers:
		if layer is FadingTileMapLayer:
			var fading_layer: FadingTileMapLayer = layer as FadingTileMapLayer
			for coords in fading_layer.tile_render_states.keys():
				var tile_state = fading_layer.tile_render_states[coords]
				if tile_state.is_discovered and coords not in discovered_coords:
					discovered_coords.append(coords)

	if discovered_coords.is_empty():
		# Default zoom if no tiles discovered
		viewport_camera.zoom = Vector2(1.0, 1.0)
		viewport_camera.position = primary_actor.global_position
		return

	# Calculate bounds of discovered area in map coordinates
	var bounds := calculate_bounds(discovered_coords, layers[0] if layers.size() > 0 else null)

	# Get viewport container size
	var viewport_size: Vector2 = $Overlay/CenterContainer/PanelContainer/VBox/SubViewportContainer.size

	# Calculate zoom to fit bounds
	var bounds_size_world := bounds.size
	var zoom_x: float = viewport_size.x / bounds_size_world.x if bounds_size_world.x > 0 else 1.0
	var zoom_y: float = viewport_size.y / bounds_size_world.y if bounds_size_world.y > 0 else 1.0
	var zoom_level: float = min(zoom_x, zoom_y) * 0.9  # 0.9 for padding

	# Clamp zoom to reasonable values
	zoom_level = clamp(zoom_level, 0.1, 10.0)

	viewport_camera.zoom = Vector2(zoom_level, zoom_level)
	viewport_camera.position = bounds.get_center()

func calculate_bounds(coords: Array[Vector2i], reference_layer: TileMapLayer) -> Rect2:
	if coords.is_empty() or reference_layer == null:
		return Rect2(0, 0, 100, 100)

	# Convert tile coordinates to world positions
	var world_positions: Array[Vector2] = []
	for coord in coords:
		var world_pos = reference_layer.map_to_local(coord)
		world_positions.append(world_pos)

	# Find min/max bounds in world space
	var min_x := INF
	var max_x := -INF
	var min_y := INF
	var max_y := -INF

	for pos in world_positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)
		min_y = min(min_y, pos.y)
		max_y = max(max_y, pos.y)

	# Add tile size to bounds to account for tile dimensions
	min_x -= TILE_SIZE.x
	max_x += TILE_SIZE.x
	min_y -= TILE_SIZE.y
	max_y += TILE_SIZE.y

	return Rect2(
		Vector2(min_x, min_y),
		Vector2(max_x - min_x, max_y - min_y)
	)

func _process(delta: float) -> void:
	if not visible:
		return

	# Update at reduced FPS
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0

		# Update player marker position
		var primary_actor: Actor = Finder.get_primary_actor()
		if primary_actor:
			position_player_marker(primary_actor)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("toggle_map_view"):
		close_view()
		get_viewport().set_input_as_handled()

func _draw_player_marker() -> void:
	# This is called by PlayerMarker node
	pass
