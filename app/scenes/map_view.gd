extends CanvasLayer

const ActorEllipseMarker = preload("res://scenes/actor_ellipse_marker.gd")
const WaypointMarker = preload("res://scenes/waypoint_marker.gd")

@onready var viewport: SubViewport = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport
@onready var viewport_camera: Camera2D = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport/Camera
@onready var player_marker: Node2D = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport/PlayerMarker
@onready var camera_viewport_indicator: Node2D = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/SubViewportContainer/SubViewport/CameraViewportIndicator
@onready var title_label: Label = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/Title
@onready var pagination_label: Label = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/PaginationLabel
@onready var description_label: RichTextLabel = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/DescriptionLabel

const TILE_SIZE: Vector2 = Vector2(32, 16)  # Isometric tile size from Map.gd
const PLAYER_MARKER_RADIUS: float = 8.0
const UPDATE_FPS: int = 10

var update_timer: float = 0.0
var update_interval: float = 1.0 / UPDATE_FPS
var actor_markers: Dictionary = {}  # Dictionary[String, Node2D] - actor name to marker node
var waypoint_markers: Dictionary = {}  # Dictionary[String, Node2D] - waypoint key to marker node
var discovered_waypoint_keys: Array[String] = []  # Ordered list of discovered waypoints
var selected_waypoint_index: int = -1  # Currently selected waypoint (-1 = none)
var all_discovered_maps: Array[String] = []  # All discovered map keys
var current_map_page: int = 0  # Current map page being viewed
var current_map_key: String = ""  # Current map being displayed

func _ready() -> void:
	visible = false
	add_to_group(Group.MAP_VIEW)

	# Set viewport to use NEAREST texture filtering for pixel-perfect rendering
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		ThemeManager._apply_theme_recursive(self)

func open_view() -> void:
	Logger.info("Opening map view")

	var primary_actor: Actor = Finder.get_primary_actor()
	if not primary_actor:
		Logger.warn("Cannot open map view: primary actor not found")
		return

	# Discover all maps with discovered waypoints
	discover_all_maps(primary_actor)

	# Get the primary actor's current map
	var map_key: String = primary_actor.map
	Logger.debug("Primary actor map key: %s" % map_key)

	if map_key.is_empty():
		Logger.warn("Cannot open map view: primary actor has no map")
		return

	# Set current page to the primary actor's map
	current_map_page = 0
	if all_discovered_maps.has(map_key):
		current_map_page = all_discovered_maps.find(map_key)

	# Set current map key
	current_map_key = all_discovered_maps[current_map_page] if all_discovered_maps.size() > 0 else map_key

	# Load the current map page
	load_map_page(primary_actor)

	Logger.info("Map view opened successfully")
	visible = true

func discover_all_maps(primary_actor: Actor) -> void:
	# Get all waypoints and collect unique map keys that have been discovered
	all_discovered_maps.clear()
	var all_waypoints = Repo.query([Group.WAYPOINT_ENTITY])

	for waypoint_ent in all_waypoints:
		if is_waypoint_discovered(waypoint_ent, primary_actor):
			var waypoint_map_key = waypoint_ent.map.key() if waypoint_ent.map else ""
			if not waypoint_map_key.is_empty() and not all_discovered_maps.has(waypoint_map_key):
				all_discovered_maps.append(waypoint_map_key)

	Logger.info("Discovered maps: %s" % str(all_discovered_maps))

func load_map_page(primary_actor: Actor) -> void:
	# Clear previous map content
	clear_viewport()

	# Update pagination label
	update_pagination_label()

	# Try multiple methods to find the map node
	var map_node = Finder.select(current_map_key) as Map
	if not map_node:
		# Try getting it from World node
		var world = Finder.select(Group.WORLD)
		if world:
			map_node = world.get_node_or_null(current_map_key) as Map
			Logger.debug("Tried getting map from World node")

	if not map_node:
		# Try using get_tree to find it in the group
		map_node = get_tree().get_first_node_in_group(current_map_key) as Map
		Logger.debug("Tried getting map from tree group")

	if not map_node:
		Logger.warn("Cannot load map page: map node not found: %s" % current_map_key)
		Logger.warn("Available groups: %s" % str(get_tree().get_nodes_in_group(Group.MAP)))
		return

	Logger.debug("Found map node: %s" % map_node.name)

	# Set title from map entity name
	var map_entity = Repo.select(current_map_key)
	if map_entity and map_entity.get("name_"):
		title_label.text = map_entity.name_
	else:
		title_label.text = current_map_key  # Fallback to key if no name

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

	# Render waypoint markers for current map
	render_waypoint_markers(primary_actor)

func update_pagination_label() -> void:
	if all_discovered_maps.size() > 1:
		pagination_label.text = "Map %d/%d" % [current_map_page + 1, all_discovered_maps.size()]
		pagination_label.visible = true
	else:
		pagination_label.visible = false

func next_map_page() -> void:
	if all_discovered_maps.size() == 0:
		return

	var primary_actor: Actor = Finder.get_primary_actor()
	if not primary_actor:
		return

	current_map_page = (current_map_page + 1) % all_discovered_maps.size()
	current_map_key = all_discovered_maps[current_map_page]
	selected_waypoint_index = -1  # Reset waypoint selection
	load_map_page(primary_actor)
	Logger.info("Next map page: %s (%d/%d)" % [current_map_key, current_map_page + 1, all_discovered_maps.size()])

func previous_map_page() -> void:
	if all_discovered_maps.size() == 0:
		return

	var primary_actor: Actor = Finder.get_primary_actor()
	if not primary_actor:
		return

	current_map_page = (current_map_page - 1 + all_discovered_maps.size()) % all_discovered_maps.size()
	current_map_key = all_discovered_maps[current_map_page]
	selected_waypoint_index = -1  # Reset waypoint selection
	load_map_page(primary_actor)
	Logger.info("Previous map page: %s (%d/%d)" % [current_map_key, current_map_page + 1, all_discovered_maps.size()])

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

		# Update description label
		update_description_display(selected_key)
	else:
		# Clear description if no waypoint selected
		description_label.text = ""

func update_description_display(waypoint_key: String) -> void:
	var waypoint_ent = Repo.select(waypoint_key)
	if not waypoint_ent:
		description_label.text = ""
		return

	var waypoint_name = waypoint_ent.get("name_") if waypoint_ent.get("name_") else waypoint_key
	var description = waypoint_ent.get("description") if waypoint_ent.get("description") else ""

	if description and not description.is_empty():
		description_label.text = "[b]" + waypoint_name + "[/b] - " + description
	else:
		description_label.text = "[b]" + waypoint_name + "[/b]"

func cycle_waypoint_selection(direction: int) -> void:
	if discovered_waypoint_keys.size() == 0:
		return

	selected_waypoint_index = (selected_waypoint_index + direction) % discovered_waypoint_keys.size()
	if selected_waypoint_index < 0:
		selected_waypoint_index = discovered_waypoint_keys.size() - 1

	update_waypoint_selection()
	Logger.info("Selected waypoint: %s (%d/%d)" % [discovered_waypoint_keys[selected_waypoint_index], selected_waypoint_index + 1, discovered_waypoint_keys.size()])

func activate_selected_waypoint() -> void:
	if selected_waypoint_index >= 0 and selected_waypoint_index < discovered_waypoint_keys.size():
		var selected_key = discovered_waypoint_keys[selected_waypoint_index]
		if waypoint_markers.has(selected_key):
			waypoint_markers[selected_key].activate_waypoint()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Mouse input handling
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton

		# Left click - center camera on clicked position
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			handle_left_click(mouse_event.position)
			get_viewport().set_input_as_handled()

		# Right click - set destination for primary actor
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			handle_right_click(mouse_event.position)
			get_viewport().set_input_as_handled()

	# Map pagination with Tab/Shift+Tab
	if event.is_action_pressed(Keybinds.INCREMENT_TARGET):  # Tab
		next_map_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(Keybinds.DECREMENT_TARGET):  # Shift+Tab
		previous_map_page()
		get_viewport().set_input_as_handled()
	# Arrow key navigation
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		cycle_waypoint_selection(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		cycle_waypoint_selection(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		activate_selected_waypoint()
		get_viewport().set_input_as_handled()

func handle_left_click(screen_position: Vector2) -> void:
	# Convert screen position to viewport position
	var viewport_container = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/SubViewportContainer
	var viewport_rect = viewport_container.get_global_rect()

	# Check if click is within viewport
	if not viewport_rect.has_point(screen_position):
		return

	# Convert to local viewport coordinates
	var local_pos = screen_position - viewport_rect.position

	# Convert viewport coordinates to world coordinates
	var world_pos = viewport_to_world_position(local_pos)

	# Get the main game camera and center it on clicked position
	var game_camera = Finder.select(Group.CAMERA) as Camera2D
	if not game_camera:
		Logger.warn("Cannot move camera: main camera not found")
		return

	# Unlock camera so it doesn't follow the primary actor
	game_camera._lock = false
	game_camera.global_position = world_pos
	Logger.info("Unlocked and centered main camera on position: %s" % world_pos)

func handle_right_click(screen_position: Vector2) -> void:
	# Convert screen position to viewport position
	var viewport_container = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/SubViewportContainer
	var viewport_rect = viewport_container.get_global_rect()

	# Check if click is within viewport
	if not viewport_rect.has_point(screen_position):
		return

	# Convert to local viewport coordinates
	var local_pos = screen_position - viewport_rect.position

	# Convert viewport coordinates to world coordinates
	var world_pos = viewport_to_world_position(local_pos)

	# Get primary actor
	var primary_actor = Finder.get_primary_actor()
	if not primary_actor:
		Logger.warn("Cannot set destination: primary actor not found")
		return

	# Only allow destination setting on the actor's current map
	if current_map_key != primary_actor.map:
		Logger.info("Cannot set destination on different map (current=%s, actor=%s)" % [current_map_key, primary_actor.map])
		return

	# Set destination for primary actor
	primary_actor.set_destination(world_pos)
	Logger.info("Set destination for primary actor to: %s" % world_pos)

func viewport_to_world_position(viewport_pos: Vector2) -> Vector2:
	# Get viewport size
	var viewport_size = viewport.size

	# Calculate normalized position (-0.5 to 0.5 from center)
	var normalized_x = (viewport_pos.x / viewport_size.x) - 0.5
	var normalized_y = (viewport_pos.y / viewport_size.y) - 0.5

	# Convert to world position relative to camera
	var world_offset_x = normalized_x * viewport_size.x / viewport_camera.zoom.x
	var world_offset_y = normalized_y * viewport_size.y / viewport_camera.zoom.y

	# Add camera position to get final world position
	return viewport_camera.position + Vector2(world_offset_x, world_offset_y)

func clone_parallax_backgrounds(map_node: Map, _center_position: Vector2) -> void:
	# Get all parallax children from the map (both legacy ParallaxBackground and new CanvasLayer-based)
	var parallax_nodes = map_node.get_children().filter(func(child):
		return child is ParallaxBackground or (child is CanvasLayer and child.is_in_group(Group.PARALLAX))
	)

	for original_parallax in parallax_nodes:
		# Handle new IsometricParallaxLayer (CanvasLayer-based)
		if original_parallax is CanvasLayer:
			var cloned_parallax = original_parallax.duplicate()
			cloned_parallax.name = original_parallax.name + "_Clone"

			# Configure for static view
			cloned_parallax.is_static_view = true
			cloned_parallax.set_camera(viewport_camera)

			# Add to viewport first so it can access viewport size
			viewport.add_child(cloned_parallax)

			# Initialize static view with all tiles
			cloned_parallax.initialize_static_view(viewport.size)

			# Move to back so it renders behind tilemaps
			viewport.move_child(cloned_parallax, 0)

		# Handle legacy ParallaxBackground
		elif original_parallax is ParallaxBackground:
			var cloned_parallax_bg = original_parallax.duplicate()
			cloned_parallax_bg.name = original_parallax.name + "_Clone"

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

func clone_map_layers(map_node: Map, _primary_actor: Actor) -> void:
	# Get all TileMapLayer children from the map
	var layers = map_node.get_children().filter(func(child): return child is TileMapLayer)

	for tile_layer in layers:
		var original_layer: TileMapLayer = tile_layer as TileMapLayer

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

	Logger.info("Rendering waypoints: found %d total waypoints" % all_waypoints.size())

	for waypoint_ent in all_waypoints:
		# Only show waypoints on the current map page
		if waypoint_ent.map and waypoint_ent.map.key() != current_map_key:
			Logger.info("Waypoint %s skipped: wrong map (waypoint=%s, current=%s)" % [waypoint_ent.key(), waypoint_ent.map.key(), current_map_key])
			continue

		Logger.info("Rendering waypoint %s at location %s" % [waypoint_ent.key(), waypoint_ent.location])

		# Check if waypoint location is discovered
		if not is_waypoint_discovered(waypoint_ent, primary_actor):
			Logger.info("Waypoint %s NOT discovered, skipping render")
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
		Logger.info("Waypoint %s already discovered (persisted)" % waypoint_key)
		return true

	# Get waypoint's vertex location
	if not waypoint_ent.location:
		Logger.warn("Waypoint %s has no location" % waypoint_key)
		return false

	var vertex_ent = waypoint_ent.location.lookup()
	if not vertex_ent:
		Logger.warn("Waypoint %s vertex lookup failed" % waypoint_key)
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
	])

	if distance <= perception_range:
		# Mark as discovered for persistence
		if not primary_actor.discovered_waypoints.has(waypoint_key):
			primary_actor.discovered_waypoints.append(waypoint_key)
			Logger.info("Waypoint %s newly discovered!" % waypoint_key)
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

	for tile_layer in layers:
		if tile_layer is FadingTileMapLayer:
			var fading_layer: FadingTileMapLayer = tile_layer as FadingTileMapLayer
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
	var viewport_size: Vector2 = $Overlay/MarginContainer/CenterContainer/PanelContainer/VBox/SubViewportContainer.size

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

func _unhandled_input(_event: InputEvent) -> void:
	if not visible:
		return

	# Cancel and toggle_map_view actions are handled by UIStateMachine via interface.gd

func _draw_player_marker() -> void:
	# This is called by PlayerMarker node
	pass
