extends Node2D
class_name Map

const TILEMAP_TILESIZE: Vector2i = Vector2i(32, 16)
const TILESET_TILESIZE: Vector2i = Vector2i(32, 32)

const TILESET_TILESHAPE: TileSet.TileShape = TileSet.TILE_SHAPE_ISOMETRIC
const TILESET_LAYOUT: TileSet.TileLayout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
const TILESET_OFFSET_AXIS: TileSet.TileOffsetAxis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL

const INVALID_TILE_SYMBOLS: Array[String] = ["", " ", "\t", "\n"]

var map_key: String
var _build_complete: bool = false

class MapBuilder:
	var obj = Scene.map.instantiate()
	
	func map(value: String) ->  MapBuilder:
		obj.map_key = value
		return self

	func build() -> Map: 
		obj.name = obj.map_key
		return obj
		
static func builder() -> MapBuilder:
	return MapBuilder.new()

func _ready() -> void:
	Logger.info("Initializing map: %s" % name, self)
	add_to_group(Group.MAP)
	add_to_group(name)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("build parallax layers for map %s" % name)
		.task(build_parallax_layers)
		.build()
	)
	Logger.debug("Queued parallax layer build for map: %s" % name, self)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("build isometric tilemap in map %s" % name)
		.task(build_isometric_tilemap)
		.condition(func(): return Repo.get_child_count() != 0)
		.build()
	)
	Logger.debug("Queued tilemap build for map: %s" % name, self)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("build sound on map %s audio stream" % name)
		.task(build_audio)
		.build()
	)
	Logger.debug("Queued audio build for map: %s" % name, self)
	
func build_complete() -> bool:
	return _build_complete
	
func build_parallax_layers() -> void:
	Logger.debug("Building parallax layers for map: %s" % name, self)
	var map_ent = Repo.query([name]).pop_front()
	Optional.of_nullable(map_ent.background).if_present(
		func(key_ref_array):
			for parallax_ent in key_ref_array.lookup():
				Logger.trace("Creating parallax layer: %s for map: %s" % [parallax_ent.name, name], self)
				var parallax_scene = Scene.parralax.instantiate()
				parallax_scene.name = parallax_ent.name
				parallax_scene.load_texture(parallax_ent.texture)
				parallax_scene.set_effect(parallax_ent.effect)
				parallax_scene.add_to_group(name) # Add to this map's group
				add_child(parallax_scene)
	)
	
func build_audio() -> void:
	Logger.debug("Building audio for map: %s" % name, self)
	var map_ent = Repo.query([name]).pop_front()
	Optional.of_nullable(map_ent.audio).if_present(
		func(key_ref_array):
			for sound_ent in key_ref_array.lookup():
				Logger.trace("Creating audio stream: %s for map: %s" % [sound_ent.key(), name], self)
				var audio: AudioStreamFader = AudioStreamFader.new()
				Optional.of_nullable(sound_ent.scale)\
					.if_present(func(scale_value): audio.set_scale_expression(scale_value))
				audio.name = sound_ent.key()
				audio.add_to_group(name) # Add to this map's group
				audio.add_to_group(Group.AUDIO)
				var stream: AudioStream = AssetLoader.builder()\
					.key(sound_ent.source)\
					.type(AssetLoader.derive_type_from_path(sound_ent.source).get_value())\
					.archive(Cache.campaign)\
					.loop(sound_ent.loop)\
					.build()\
					.pull()
				audio.set_stream(stream)
				add_child(audio)
	)

func build_isometric_tilemap() -> void:
	Logger.debug("Building isometric tilemap for map: %s" % name, self)
	var map_ent = Repo.query([name]).pop_front()
	var tilemap_ent = map_ent.tilemap.lookup()
	var tileset_ent = tilemap_ent.tileset.lookup()
	var tileset: TileSet = TileSet.new()
	tileset.set_tile_shape(TILESET_TILESHAPE)
	tileset.set_tile_layout(TILESET_LAYOUT)
	tileset.set_tile_offset_axis(TILESET_OFFSET_AXIS)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)  # WALL bit value is 1
	tileset.set_physics_layer_collision_mask(0, 0) # disable mask bit 1
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(1, 16)  # DISCOVERY BIT VALUE = 16
	tileset.set_physics_layer_collision_mask(1, 0) # disable mask bit 1
	tileset.add_navigation_layer()
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	var texture_bytes = AssetLoader.builder()\
	.key(tileset_ent.texture)\
	.type(AssetLoader.Type.IMAGE)\
	.archive(Cache.campaign)\
	.build()\
	.pull()
	atlas.set_texture(texture_bytes)
	atlas.set_texture_region_size(TILESET_TILESIZE)
	tileset.add_source(atlas)
	tileset.set_tile_size(TILEMAP_TILESIZE)
	for tile_ent in tileset_ent.tiles.lookup():
		var coords = Vector2i(tile_ent.index % tileset_ent.columns, tile_ent.index / tileset_ent.columns)
		var tile_pos: Vector2i = Vector2i(tile_ent.index % tileset_ent.columns, tile_ent.index / tileset_ent.columns)
		tileset.get_source(0).create_tile(tile_pos)
		var atlas_tile = atlas.get_tile_data(coords, 0)
		atlas.set("%s:%s/0/y_sort_origin" % [coords.x, coords.y], tile_ent.origin)

		# Navigation will be handled by a single NavigationRegion2D instead of individual tile polygons
		# This prevents overlapping polygon errors and allows proper merging of navigation areas
		if tile_ent.obstacle:
			# Use elliptical shape for smooth corner navigation (8 points for good balance of smoothness vs performance)
			atlas_tile.set("physics_layer_0/polygon_0/points", std.generate_isometric_shape(TILEMAP_TILESIZE.x, Vector2i(0, +TILEMAP_TILESIZE.y/2)))
		var discovery_vectors = std.generate_isometric_shape(TILEMAP_TILESIZE.x, Vector2i(0, +TILEMAP_TILESIZE.y/2))
		atlas_tile.set("physics_layer_1/polygon_0/points", discovery_vectors)
	var layers_ent_array = tilemap_ent.layers.lookup()
	for layer_index in range(layers_ent_array.size()):
		var layer_ent = layers_ent_array[layer_index]
		Logger.trace("Creating tilemap layer %s for map %s" % [layer_ent.key(), name], self)
		var tilemap_layer := FadingTileMapLayer.new()
		tilemap_layer.add_to_group(name)
		tilemap_layer.add_to_group(Group.MAP_LAYER)
		tilemap_layer.enabled = false # Sets visibilty and collisions off by default
		tilemap_layer.name = layer_ent.key()
		tilemap_layer.tile_set = tileset
		tilemap_layer.y_sort_enabled = layer_ent.ysort
		tilemap_layer.z_index = layer_ent.ysort			
		tilemap_layer.z_as_relative = true
		tilemap_layer.set_visibility_layer_bit(0, false) # Reset defualt state to none
		tilemap_layer.set_visibility_layer_bit(layer_index, true)
		var layer_string: String = io.load_asset(Cache.campaign + layer_ent.source, Cache.campaign)
		var coords: Vector2i = Vector2i()	
		for row in layer_string.split("\n"):
			coords.y = 0
			for tile_symbol in row:
				if !(tile_symbol in INVALID_TILE_SYMBOLS): 
					var tile_ent = Repo.query([Group.TILE_ENTITY]).filter(func(ent): return ent.symbol == tile_symbol).front()
					var atlas_coords: Vector2i = Vector2i( 
							tile_ent.index % tileset_ent.columns,
							tile_ent.index / tileset_ent.columns,
						)
					tilemap_layer.set_cell(coords, 0, atlas_coords)
				coords.y -= 1
			coords.x += 1
		add_child(tilemap_layer)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Build navigation region for map %s" % name)
		.task(func(): build_navigation_region(collect_obstacle_coordinates()))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Set build complete in map")
		.task(func(): 
			_build_complete = true
			Logger.info("Map build complete: %s" % name, self))
		.build()
	)

func collect_obstacle_coordinates() -> Array[Vector2i]:
	var map_ent = Repo.query([name]).pop_front()
	var tilemap_ent = map_ent.tilemap.lookup()
	
	# Collect coordinates that have collision polygons on ANY layer
	var obstacle_coordinates: Array[Vector2i] = []
	var layers_ent_array = tilemap_ent.layers.lookup()
	
	for layer_index in range(layers_ent_array.size()):
		var layer_ent = layers_ent_array[layer_index]
		var layer_string: String = io.load_asset(Cache.campaign + layer_ent.source, Cache.campaign)
		var coords: Vector2i = Vector2i()
		
		for row in layer_string.split("\n"):
			coords.y = 0
			for tile_symbol in row:
				if !(tile_symbol in INVALID_TILE_SYMBOLS):
					var tile_ent = Repo.query([Group.TILE_ENTITY]).filter(func(ent): return ent.symbol == tile_symbol).front()
					if tile_ent.obstacle and coords not in obstacle_coordinates:
						obstacle_coordinates.append(coords)
				coords.y -= 1
			coords.x += 1
	
	return obstacle_coordinates

func build_navigation_region(obstacle_coordinates: Array[Vector2i] = []) -> void:
	var map_ent = Repo.query([name]).pop_front()
	var tilemap_ent = map_ent.tilemap.lookup()
	
	# Collect all navigable tile positions across all layers, excluding obstacle coordinates
	var navigable_positions: Array[Vector2i] = []
	var layers_ent_array = tilemap_ent.layers.lookup()
	
	for layer_index in range(layers_ent_array.size()):
		var layer_ent = layers_ent_array[layer_index]
		var layer_string: String = io.load_asset(Cache.campaign + layer_ent.source, Cache.campaign)
		var coords: Vector2i = Vector2i()
		
		for row in layer_string.split("\n"):
			coords.y = 0
			for tile_symbol in row:
				if !(tile_symbol in INVALID_TILE_SYMBOLS):
					var tile_ent = Repo.query([Group.TILE_ENTITY]).filter(func(ent): return ent.symbol == tile_symbol).front()
					# Only add to navigable if it has navigation AND is not blocked by an obstacle
					if tile_ent.navigation and coords not in obstacle_coordinates:
						navigable_positions.append(coords)
				coords.y -= 1
			coords.x += 1
	
	if navigable_positions.is_empty():
		return
		
	# Create NavigationRegion2D
	var navigation_region := NavigationRegion2D.new()
	navigation_region.name = "Navigation"
	navigation_region.add_to_group(name)
	navigation_region.add_to_group(Group.NAVIGATION)
	navigation_region.add_to_group(map_key)
	navigation_region.use_edge_connections = true
	
	# Create NavigationPolygon with properly spaced diamond shapes
	var navigation_polygon := NavigationPolygon.new()
	var all_vertices: PackedVector2Array = []
	var vertex_index := 0
	
	# Create diamond shapes for each navigable tile position with proper spacing
	var tilemap_layers = get_children().filter(func(child): return child is TileMapLayer)
	if not tilemap_layers.is_empty():
		var tilemap_layer = tilemap_layers[0] as TileMapLayer
		
		for pos in navigable_positions:
			var world_pos = tilemap_layer.map_to_local(pos)
			
			# Use standard offset for all navigation diamonds
			# The outset behavior only affects obstacle collision detection, not navigation shape
			# TODO if tile ent .inset = true, multiply offset by -1
			var offset: Vector2i = Vector2i(0, +TILEMAP_TILESIZE.y/2)
			var diamond = std.generate_isometric_shape(TILEMAP_TILESIZE.x, offset)
			
			# Add vertices for this diamond (offset by world position)
			var start_vertex = vertex_index
			for vertex in diamond:
				all_vertices.append(world_pos + vertex)
				vertex_index += 1
			
			# Create separate polygon for this diamond
			var diamond_indices = PackedInt32Array()
			for i in range(diamond.size()):
				diamond_indices.append(start_vertex + i)
			navigation_polygon.add_polygon(diamond_indices)
	
	# Set vertices
	navigation_polygon.vertices = all_vertices
	
	# Set the navigation polygon and add to scene
	navigation_region.navigation_polygon = navigation_polygon
	add_child(navigation_region)
