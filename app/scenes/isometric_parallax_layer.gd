extends CanvasLayer

## Custom parallax implementation for isometric viewports.
## Uses dynamic tile spawning to ensure full viewport coverage regardless of camera position.
## Applies isometric Y-compression to parallax motion for proper perspective matching.

const SCALAR: float = 100.0  # User-facing effect scale (allows whole numbers)
const TILE_MARGIN: float = 400.0  # Extra coverage beyond viewport edges
const ISOMETRIC_RATIO: float = 2.0  # Y-axis compression ratio for isometric perspective

# State
var _texture: Texture2D = null
var _effect_value: float = 1.0
var _camera: Camera2D = null
var _tiles: Dictionary = {}  # Key: Vector2i grid coord, Value: Sprite2D
var _tile_pool: Array[Sprite2D] = []
var _last_camera_pos: Vector2 = Vector2.ZERO
var _initialized: bool = false
var is_static_view: bool = false  # When true, disables dynamic updates for map view

func _ready() -> void:
	Logger.debug("Isometric parallax layer initialized: %s" % name)
	add_to_group(Group.PARALLAX)

	# Get camera reference (unless already set via set_camera)
	if not _camera:
		_camera = Finder.select(Group.CAMERA)
		if not _camera:
			Logger.warn("No camera found for parallax layer: %s" % name)
			return

	_initialized = true

func load_texture(path_to_asset: String) -> void:
	Logger.debug("Loading texture for parallax layer %s: %s" % [name, path_to_asset])
	_texture = AssetLoader.builder()\
		.key(path_to_asset)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()

	if _initialized:
		_update_tiles()

func set_effect(value: float) -> void:
	Logger.trace("Setting parallax effect for %s: %s" % [name, value])
	_effect_value = value / SCALAR

func set_visibility(effect: bool) -> void:
	Logger.debug("Setting parallax visibility for %s: %s" % [name, effect])
	visible = effect

func set_camera(camera: Camera2D) -> void:
	## Sets the camera reference for parallax calculations.
	## Useful for map view which uses a different camera.
	_camera = camera

func _process(_delta: float) -> void:
	if not _initialized or not _camera or not _texture or is_static_view:
		return

	var camera_pos = _camera.get_screen_center_position()

	# Update tiles if camera moved
	if camera_pos != _last_camera_pos:
		_last_camera_pos = camera_pos
		_update_tiles()
		_update_tile_positions()

func _calculate_parallax_offset() -> Vector2:
	## Calculates the parallax offset based on camera position and effect value.
	## Applies isometric Y-compression to match the visual perspective.
	## Returns zero offset for static views (map view).
	if not _camera or is_static_view:
		return Vector2.ZERO

	var camera_pos = _camera.get_screen_center_position()

	# Apply effect with isometric Y-compression
	return Vector2(
		camera_pos.x * _effect_value,
		camera_pos.y * _effect_value / ISOMETRIC_RATIO
	)

func _calculate_viewport_bounds() -> Rect2:
	## Calculates the world-space bounds that need to be covered with tiles.
	## Includes margin for seamless spawning/despawning.
	if not _camera:
		return Rect2()

	var viewport_size = get_viewport().get_visible_rect().size
	var parallax_offset = _calculate_parallax_offset()

	# Calculate bounds in parallax space with margin
	var top_left = parallax_offset - viewport_size / 2.0 - Vector2(TILE_MARGIN, TILE_MARGIN)
	var size = viewport_size + Vector2(TILE_MARGIN * 2, TILE_MARGIN * 2)

	return Rect2(top_left, size)

func _calculate_required_tiles(bounds: Rect2) -> Array[Vector2i]:
	## Determines which tile grid coordinates are needed to cover the viewport bounds.
	if not _texture:
		return []

	var texture_size = _texture.get_size()
	var required_tiles: Array[Vector2i] = []

	# Calculate grid range
	var start_x = int(floor(bounds.position.x / texture_size.x))
	var start_y = int(floor(bounds.position.y / texture_size.y))
	var end_x = int(ceil(bounds.end.x / texture_size.x))
	var end_y = int(ceil(bounds.end.y / texture_size.y))

	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			required_tiles.append(Vector2i(x, y))

	return required_tiles

func _update_tiles() -> void:
	## Spawns and despawns tiles to ensure viewport coverage.
	if not _texture:
		return

	var bounds = _calculate_viewport_bounds()
	var required_tiles = _calculate_required_tiles(bounds)
	var required_set = {}

	# Mark required tiles
	for coord in required_tiles:
		required_set[coord] = true

	# Remove tiles no longer needed
	var to_remove: Array[Vector2i] = []
	for coord in _tiles.keys():
		if not required_set.has(coord):
			to_remove.append(coord)

	for coord in to_remove:
		_despawn_tile(coord)

	# Spawn new tiles
	for coord in required_tiles:
		if not _tiles.has(coord):
			_spawn_tile(coord)

func _update_tile_positions() -> void:
	## Updates all tile positions based on current parallax offset.
	var parallax_offset = _calculate_parallax_offset()
	var texture_size = _texture.get_size()

	for coord in _tiles.keys():
		var tile = _tiles[coord]
		# Position in parallax space minus the parallax offset for proper scrolling
		tile.position = Vector2(coord) * texture_size - parallax_offset

func _spawn_tile(grid_coord: Vector2i) -> void:
	## Spawns a new tile at the specified grid coordinate.
	## Uses pooling for performance.
	var tile: Sprite2D

	# Try to get from pool
	if _tile_pool.size() > 0:
		tile = _tile_pool.pop_back()
	else:
		tile = Sprite2D.new()
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tile.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tile.centered = false
		add_child(tile)

	tile.texture = _texture
	tile.visible = true

	_tiles[grid_coord] = tile

func _despawn_tile(grid_coord: Vector2i) -> void:
	## Despawns a tile and returns it to the pool.
	if not _tiles.has(grid_coord):
		return

	var tile = _tiles[grid_coord]
	tile.visible = false
	_tile_pool.append(tile)
	_tiles.erase(grid_coord)

func initialize_static_view(viewport_size: Vector2) -> void:
	## Initializes the parallax layer for static view (map view).
	## Spawns all tiles needed to cover the given viewport size.
	if not _texture:
		Logger.warn("Cannot initialize static view: no texture loaded for %s" % name)
		return

	is_static_view = true
	_initialized = true

	# Calculate bounds to cover the entire viewport (no margin needed for static)
	var bounds = Rect2(Vector2.ZERO, viewport_size)
	var required_tiles = _calculate_required_tiles(bounds)

	# Spawn all tiles at once
	for coord in required_tiles:
		_spawn_tile(coord)

	# Position tiles with zero offset (static background)
	_update_tile_positions()

	Logger.debug("Static view initialized for %s with %d tiles" % [name, _tiles.size()])
