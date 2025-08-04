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
	var primary_actor_cell: Vector2i = local_to_map(to_local(primary_actor.global_position))
	var distance: float = primary_actor_cell.distance_to(coords)
	var viewbox_area: Area2D = primary_actor.get_node("ViewBox")
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
	var tile_render_state_update_params: TileRenderState.UpdateParams = calculate_distance_and_radius(coords)
	tile_render_states[coords].update(tile_render_state_update_params)		
	tile_data.modulate = tile_render_states[coords].get_modulate()
	tile_render_states[coords].tick(process_delta)
		
func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true
	
func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	get_tile_render_state(coords)
	use_render_tile(coords, tile_data)

func _process(delta: float) -> void: # TODO - consider slowing down this class
	process_delta = delta
	notify_runtime_tile_data_update()

func _on_visibility_changed() -> void:
	set_process(visible)
