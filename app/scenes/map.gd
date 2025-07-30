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
	add_to_group(Group.MAP)
	add_to_group(name)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("build parallax layers for map %s" % name)
		.task(build_parallax_layers)
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("build isometric tilemap in map %s" % name)
		.task(build_isometric_tilemap)
		.condition(func(): return Repo.get_child_count() != 0)
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("build sound on map %s audio stream" % name)
		.task(build_audio)
		.build()
	)
	
func build_complete() -> bool:
	return _build_complete
	
func build_parallax_layers() -> void:
	var map_ent = Repo.query([name]).pop_front()
	Optional.of_nullable(map_ent.background).if_present(
		func(key_ref_array):
			for parallax_ent in key_ref_array.lookup():
				var parallax_scene = Scene.parralax.instantiate()
				parallax_scene.name = parallax_ent.name
				parallax_scene.load_texture(parallax_ent.texture)
				parallax_scene.set_effect(parallax_ent.effect)
				parallax_scene.add_to_group(name) # Add to this map's group
				add_child(parallax_scene)
	)
	
func build_audio() -> void:
	var map_ent = Repo.query([name]).pop_front()
	Optional.of_nullable(map_ent.audio).if_present(
		func(key_ref_array):
			for sound_ent in key_ref_array.lookup():
				var audio: AudioStreamFader = AudioStreamFader.new()
				Optional.of_nullable(sound_ent.scale)\
					.if_present(func(scale): audio.set_scale_expression(scale))
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
	var map_ent = Repo.query([name]).pop_front()
	var tilemap_ent = map_ent.tilemap.lookup()
	var tileset_ent = tilemap_ent.tileset.lookup()
	var tileset: TileSet = TileSet.new()
	tileset.set_tile_shape(TILESET_TILESHAPE)
	tileset.set_tile_layout(TILESET_LAYOUT)
	tileset.set_tile_offset_axis(TILESET_OFFSET_AXIS)
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, Layer.WALL)  # set the second int as value, not bit or index.
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
		atlas_tile.modulate = Color(Style.UNDISCOVERED_TILE_TINT, Style.UNDISCOVERED_TILE_TINT, Style.UNDISCOVERED_TILE_TINT, Style.UNDISCOVERED_TILE_TINT)
		atlas.set("%s:%s/0/y_sort_origin" % [coords.x, coords.y], tile_ent.origin)
		var navigation_polygon: NavigationPolygon = NavigationPolygon.new()
		navigation_polygon.add_outline(std.generate_isometric_shape(TILEMAP_TILESIZE.x, Vector2i(0, -TILEMAP_TILESIZE.y/2)))
		navigation_polygon.make_polygons_from_outlines()
		atlas_tile.set_navigation_polygon(0, navigation_polygon)
		if tile_ent.polygon != null:
			var polygon_ent = tile_ent.polygon.lookup()
			var vectors: PackedVector2Array = []
			for vertex_ent in polygon_ent.vertices.lookup():
				vectors.append(vertex_ent.to_vec2i())
			atlas_tile.set("physics_layer_0/polygon_0/points", vectors)
	var layers_ent_array = tilemap_ent.layers.lookup()
	for layer_index in range(layers_ent_array.size()):
		var tilemap_layer := FadingTileMapLayer.new()
		tilemap_layer.add_to_group(name)
		tilemap_layer.enabled = false # Sets visibilty and collisions off by default
		var layer_ent = layers_ent_array[layer_index]
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
		.comment("Set build complete in map")
		.task(func(): _build_complete = true)
		.build()
	)
