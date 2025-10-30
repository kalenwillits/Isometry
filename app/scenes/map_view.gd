extends CanvasLayer

const ActorEllipseMarker = preload("res://scenes/actor_ellipse_marker.gd")
const WaypointMarker = preload("res://scenes/waypoint_marker.gd")

@onready var viewport: SubViewport = $Overlay/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport
@onready var viewport_camera: Camera2D = $Overlay/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport/Camera
@onready var player_marker: Node2D = $Overlay/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport/PlayerMarker
@onready var camera_viewport_indicator: Node2D = $Overlay/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport/CameraViewportIndicator
@onready var title_label: Label = $Overlay/CenterContainer/PanelContainer/VBox/Title

const TILE_SIZE: Vector2 = Vector2(32, 16)  # Isometric tile size from Map.gd
const PLAYER_MARKER_RADIUS: float = 8.0
const UPDATE_FPS: int = 10

var update_timer: float = 0.0
var update_interval: float = 1.0 / UPDATE_FPS
var actor_markers: Dictionary = {}  # Dictionary[String, Node2D] - actor name to marker node
var waypoint_markers: Dictionary = {}  # Dictionary[String, Node2D] - waypoint key to marker node
var discovered_waypoint_keys: Array[String] = []  # Ordered list of discovered waypoints
var selected_waypoint_index: int = -1  # Currently selected waypoint (-1 = none)

func _ready() -> void:
	visible = false
	add_to_group(Group.MAP_VIEW)

	# Set viewport to use NEAREST texture filtering for pixel-perfect rendering
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		var theme_mgr = get_node_or_null("/root/ThemeManager")
		if theme_mgr:
			theme_mgr._apply_theme_recursive(self)

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

	# Set title from map entity name
	var map_entity = Repo.select(map_key)
	if map_entity and map_entity.get("name_"):
		title_label.text = map_entity.name_
	else:
		title_label.text = map_key  # Fallback to key if no name

	# Clear previous map content
	clear_viewport()

	# Set player marker size from base
	player_marker.set_size(primary_actor.base)

	# Set player marker color from group
	var marker_color: Color = primary_actor.group_outline_color
	if marker_color == Color.BLACK or marker_color.a == 0.0:
		marker_color = Color.WHITE  # Default to white if no group color
	player_marker.set_color(marker_color)

	# Clone map layers with only discovered tiles
	clone_map_layers(map_node, primary_actor)

	# Calculate zoom to fit discovered area (this also calculates map center)
	var map_center = calculate_and_set_zoom(primary_actor)

	# Clone parallax backgrounds and position them at map center
	clone_parallax_backgrounds(map_node, map_center)

	# Position player marker
	position_player_marker(primary_actor)

	# Render actor markers
	render_actor_markers(primary_actor)

	# Render waypoint markers
	render_waypoint_markers(primary_actor)

	Logger.info("Map view opened successfully", self)
	visible = true

func close_view() -> void:
	visible = false
	clear_viewport()

func clear_viewport() -> void:
	# Remove all children except camera, player marker, and camera viewport indicator
	for child in viewport.get_children():
		if child != viewport_camera and child != player_marker and child != camera_viewport_indicator:
			child.queue_free()

	# Clear actor markers dictionary
	actor_markers.clear()

	# Clear waypoint markers dictionary
	waypoint_markers.clear()

	# Reset selection
	discovered_waypoint_keys.clear()
	selected_waypoint_index = -1

func update_waypoint_selection() -> void:
	# Reset all waypoint markers to not selected
	for marker in waypoint_markers.values():
		marker.set_selected(false)

	# Set selected waypoint
	if selected_waypoint_index >= 0 and selected_waypoint_index < discovered_waypoint_keys.size():
		var selected_key = discovered_waypoint_keys[selected_waypoint_index]
		if waypoint_markers.has(selected_key):
			waypoint_markers[selected_key].set_selected(true)

func cycle_waypoint_selection(direction: int) -> void:
	if discovered_waypoint_keys.size() == 0:
		return

	selected_waypoint_index = (selected_waypoint_index + direction) % discovered_waypoint_keys.size()
	if selected_waypoint_index < 0:
		selected_waypoint_index = discovered_waypoint_keys.size() - 1

	update_waypoint_selection()
	Logger.info("Selected waypoint: %s (%d/%d)" % [discovered_waypoint_keys[selected_waypoint_index], selected_waypoint_index + 1, discovered_waypoint_keys.size()], self)

func activate_selected_waypoint() -> void:
	if selected_waypoint_index >= 0 and selected_waypoint_index < discovered_waypoint_keys.size():
		var selected_key = discovered_waypoint_keys[selected_waypoint_index]
		if waypoint_markers.has(selected_key):
			waypoint_markers[selected_key].activate_waypoint()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Arrow key navigation
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		cycle_waypoint_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		cycle_waypoint_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		activate_selected_waypoint()
		get_viewport().set_input_as_handled()

func clone_parallax_backgrounds(map_node: Map, center_position: Vector2) -> void:
	# Get all ParallaxBackground children from the map
	var parallax_bgs = map_node.get_children().filter(func(child): return child is ParallaxBackground)

	for original_parallax_bg in parallax_bgs:
		# Clone the entire ParallaxBackground node structure
		var cloned_parallax_bg = original_parallax_bg.duplicate()
		cloned_parallax_bg.name = original_parallax_bg.name + "_Clone"

		# Set scroll offset to 0 for static view
		cloned_parallax_bg.scroll_offset = Vector2.ZERO
		cloned_parallax_bg.scroll_base_offset = Vector2.ZERO

		# Set texture filter to NEAREST on all ParallaxLayer children and their sprite children
		for parallax_layer in cloned_parallax_bg.get_children():
			if parallax_layer is ParallaxLayer:
				# Set on the ParallaxLayer itself
				parallax_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				# Also set on all sprite/texture children within the layer
				for sprite in parallax_layer.get_children():
					if sprite is CanvasItem:
						sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		viewport.add_child(cloned_parallax_bg)

		# Move to back
		viewport.move_child(cloned_parallax_bg, 0)

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
		cloned_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # Pixel-perfect rendering

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

func should_show_actor(actor: Actor, primary_actor: Actor) -> bool:
	# Don't show primary actor (has its own marker)
	if actor == primary_actor:
		return false

	# Only show actors on the same map
	if actor.map != primary_actor.map:
		return false

	# Always show actors in same group
	if not actor.target_group.is_empty() and actor.target_group == primary_actor.target_group:
		return true

	# Show actors in primary actor's view
	if primary_actor.in_view.has(actor.name):
		return true

	return false

func render_actor_markers(primary_actor: Actor) -> void:
	# Get all actors from the scene
	var all_actors = get_tree().get_nodes_in_group(Group.ACTOR)

	for actor in all_actors:
		var actor_node = actor as Actor
		if not actor_node:
			continue

		if should_show_actor(actor_node, primary_actor):
			# Create marker for this actor
			var marker = Node2D.new()
			marker.set_script(ActorEllipseMarker)
			marker.name = "ActorMarker_" + actor_node.name
			marker.z_index = 99  # Below player marker (100)

			# Set size from actor base
			marker.set_size(actor_node.base)

			# Set color from group
			var marker_color: Color = actor_node.group_outline_color
			if marker_color == Color.BLACK or marker_color.a == 0.0:
				marker_color = Color.WHITE  # Default to white if no group color
			marker.set_color(marker_color)

			# Set position
			marker.global_position = actor_node.global_position

			# Add to viewport
			viewport.add_child(marker)

			# Track in dictionary
			actor_markers[actor_node.name] = marker

func render_waypoint_markers(primary_actor: Actor) -> void:
	# Get all waypoints
	var all_waypoints = Repo.query([Group.WAYPOINT_ENTITY])
	discovered_waypoint_keys.clear()

	Logger.info("Rendering waypoints: found %d total waypoints" % all_waypoints.size(), self)

	for waypoint_ent in all_waypoints:
		# Only show waypoints on the same map
		if waypoint_ent.map and waypoint_ent.map.key() != primary_actor.map:
			Logger.info("Waypoint %s skipped: wrong map (waypoint=%s, actor=%s)" % [waypoint_ent.key(), waypoint_ent.map.key(), primary_actor.map], self)
			continue

		Logger.info("Rendering waypoint %s at location %s" % [waypoint_ent.key(), waypoint_ent.location], self)

		# Check if waypoint location is discovered
		if not is_waypoint_discovered(waypoint_ent, primary_actor):
			Logger.info("Waypoint %s NOT discovered, skipping render", self)
			continue

		# Add to discovered list
		discovered_waypoint_keys.append(waypoint_ent.key())

		# Create marker control
		var marker = Control.new()
		marker.set_script(WaypointMarker)
		marker.name = "WaypointMarker_" + waypoint_ent.key()
		marker.z_index = 98  # Below actor markers (99) and player marker (100)

		# Set waypoint key first (to get the name)
		marker.set_waypoint_key(waypoint_ent.key())

		# Set position from Vertex
		if waypoint_ent.location:
			var vertex_ent = waypoint_ent.location.lookup()
			if vertex_ent:
				# Vertices are already in world coordinates
				var waypoint_coords = vertex_ent.to_vec2i()
				# Center the control on the waypoint position
				marker.position = Vector2(waypoint_coords.x - 16, waypoint_coords.y - 16)

		# Add to viewport first so _ready() is called and children are created
		viewport.add_child(marker)

		# Now set the icon after _ready() has created the TextureRect
		var icon_texture = load_waypoint_icon(waypoint_ent.icon)
		if icon_texture:
			marker.set_icon(icon_texture)

		# Set initial scale to counter camera zoom (to maintain constant screen size)
		# Scale down to 75% size
		marker.scale = (Vector2.ONE / viewport_camera.zoom) * 0.75

		# Track in dictionary
		waypoint_markers[waypoint_ent.key()] = marker

	# Initialize selection to first waypoint if any exist
	if discovered_waypoint_keys.size() > 0:
		selected_waypoint_index = 0
		update_waypoint_selection()
	else:
		selected_waypoint_index = -1

func is_waypoint_discovered(waypoint_ent: Entity, primary_actor: Actor) -> bool:
	# First check if waypoint already discovered (persisted)
	var waypoint_key = waypoint_ent.get_name()
	if primary_actor.discovered_waypoints.has(waypoint_key):
		Logger.info("Waypoint %s already discovered (persisted)" % waypoint_key, self)
		return true

	# Get waypoint's vertex location
	if not waypoint_ent.location:
		Logger.warn("Waypoint %s has no location" % waypoint_key, self)
		return false

	var vertex_ent = waypoint_ent.location.lookup()
	if not vertex_ent:
		Logger.warn("Waypoint %s vertex lookup failed" % waypoint_key, self)
		return false

	# Get waypoint world position (vertices are already in world coordinates)
	var waypoint_coords = vertex_ent.to_vec2i()
	var waypoint_world_pos = Vector2(waypoint_coords.x, waypoint_coords.y)

	# Get primary actor world position
	var actor_world_pos = primary_actor.position

	# Calculate distance
	var distance = actor_world_pos.distance_to(waypoint_world_pos)

	# Check if within perception range
	# ViewBox uses CircleShape2D (default radius 10) scaled by (1 * perception, 0.5 * perception)
	# So actual radius is: 10 * perception horizontally, 10 * 0.5 * perception vertically
	# We'll use the average for a circular approximation
	var perception_range = 10.0 * primary_actor.perception * 0.75  # Average of 1.0 and 0.5 scales

	Logger.info("Waypoint %s: pos=%s, actor_pos=%s, distance=%.1f, perception_range=%.1f, discovered=%s" % [
		waypoint_key, waypoint_world_pos, actor_world_pos, distance, perception_range, distance <= perception_range
	], self)

	if distance <= perception_range:
		# Mark as discovered for persistence
		if not primary_actor.discovered_waypoints.has(waypoint_key):
			primary_actor.discovered_waypoints.append(waypoint_key)
			Logger.info("Waypoint %s newly discovered!" % waypoint_key, self)
		return true

	return false

func load_waypoint_icon(icon_path: String) -> ImageTexture:
	if icon_path.is_empty():
		return null

	return AssetLoader.builder()\
		.key(icon_path)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()

func calculate_and_set_zoom(primary_actor: Actor) -> Vector2:
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
		return primary_actor.global_position

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
		return primary_actor.global_position

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

	var center_position = bounds.get_center()
	viewport_camera.zoom = Vector2(zoom_level, zoom_level)
	viewport_camera.position = center_position

	return center_position

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
			update_actor_markers(primary_actor)
			update_camera_viewport_indicator()

func update_actor_markers(primary_actor: Actor) -> void:
	# Get all actors
	var all_actors = get_tree().get_nodes_in_group(Group.ACTOR)

	# Track which actors should be visible
	var actors_to_show: Dictionary = {}

	for actor in all_actors:
		var actor_node = actor as Actor
		if not actor_node:
			continue

		if should_show_actor(actor_node, primary_actor):
			actors_to_show[actor_node.name] = actor_node

	# Remove markers for actors that should no longer be visible
	for actor_name in actor_markers.keys():
		if not actors_to_show.has(actor_name):
			var marker = actor_markers[actor_name]
			if marker and is_instance_valid(marker):
				marker.queue_free()
			actor_markers.erase(actor_name)

	# Update existing markers or create new ones
	for actor_name in actors_to_show.keys():
		var actor_node = actors_to_show[actor_name]

		if actor_markers.has(actor_name):
			# Update existing marker position
			var marker = actor_markers[actor_name]
			if marker and is_instance_valid(marker):
				marker.global_position = actor_node.global_position
		else:
			# Create new marker
			var marker = Node2D.new()
			marker.set_script(ActorEllipseMarker)
			marker.name = "ActorMarker_" + actor_node.name
			marker.z_index = 99  # Below player marker (100)

			# Set size from actor base
			marker.set_size(actor_node.base)

			# Set color from group
			var marker_color: Color = actor_node.group_outline_color
			if marker_color == Color.BLACK or marker_color.a == 0.0:
				marker_color = Color.WHITE  # Default to white if no group color
			marker.set_color(marker_color)

			# Set position
			marker.global_position = actor_node.global_position

			# Add to viewport
			viewport.add_child(marker)

			# Track in dictionary
			actor_markers[actor_node.name] = marker

func update_camera_viewport_indicator() -> void:
	# Check if indicator exists and is valid
	if not camera_viewport_indicator or not is_instance_valid(camera_viewport_indicator):
		return

	# Get the main game camera
	var game_camera = Finder.select(Group.CAMERA) as Camera2D
	if not game_camera:
		return

	# Get the actual viewport size in world coordinates
	var game_viewport = game_camera.get_viewport()
	if not game_viewport:
		return

	var viewport_size = game_viewport.get_visible_rect().size
	var camera_zoom = game_camera.zoom

	# Calculate the visible area size in world space
	var visible_width = viewport_size.x / camera_zoom.x
	var visible_height = viewport_size.y / camera_zoom.y

	# Get camera position
	var camera_position = game_camera.global_position

	# Create rect centered on camera position
	var rect = Rect2(
		camera_position.x - visible_width / 2.0,
		camera_position.y - visible_height / 2.0,
		visible_width,
		visible_height
	)

	camera_viewport_indicator.set_viewport_rect(rect)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("toggle_map_view"):
		close_view()
		get_viewport().set_input_as_handled()

func _draw_player_marker() -> void:
	# This is called by PlayerMarker node
	pass
