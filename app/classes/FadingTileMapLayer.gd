extends TileMapLayer
class_name FadingTileMapLayer

var process_delta: float = 0.0

const SCALE_TO_VIEW: float = 5.0
var tile_render_states: Dictionary = {}

func _ready() -> void:
	add_to_group(Group.MAP_LAYER)
	visibility_changed.connect(_on_visibility_changed)

func calculate_distance_and_radius(coords: Vector2i) -> TileRenderState.UpdateParams:
	var primary_actor: Actor = Finder.get_primary_actor()
	if primary_actor == null: return TileRenderState.UpdateParams.create(INF, 0.0)
	var view_shape = primary_actor.get_node_or_null("ViewBox/PrimaryViewShape")
	if view_shape == null: return TileRenderState.UpdateParams.create(INF, 0.0)
	var tile_position = to_global(map_to_local(coords))
	var view_position = to_global(primary_actor.position + view_shape.position)
	var change_pos = tile_position - view_position
	var radius = view_shape.scale.x * SCALE_TO_VIEW
	var distance = Vector2(change_pos.x / 2, change_pos.y).length()
	return TileRenderState.UpdateParams.create(distance, radius)
	
func use_register_tile_render_state(coords: Vector2i) -> void:
	if tile_render_states.get(coords) == null:
		tile_render_states[coords] = TileRenderState.builder().build()
		
func use_render_tile(coords: Vector2i, tile_data: TileData) -> void:		
	var tile_render_state_update_params: TileRenderState.UpdateParams = calculate_distance_and_radius(coords)
	tile_render_states[coords].update(tile_render_state_update_params)		
	tile_data.modulate = tile_render_states[coords].get_modulate()
	tile_render_states[coords].tick(process_delta)
		
func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true
	
func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	use_register_tile_render_state(coords)
	use_render_tile(coords, tile_data)

func _process(delta: float) -> void: # TODO - consider slowing down this class
	process_delta = delta
	notify_runtime_tile_data_update()

func _on_visibility_changed() -> void:
	set_process(visible)
