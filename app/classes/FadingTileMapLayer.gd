extends TileMapLayer
class_name FadingTileMapLayer

const SCALE_TO_VIEW: float = 5.0
var discovered_tiles: Dictionary = {}
var in_view_tiles: Dictionary = {}
var tile_fade_states: Dictionary = {}

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return true # TODO - only run update on tiles that are in-view

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	if tile_fade_states.has(coords):
		var state = tile_fade_states[coords]
		var a = clamp(state.current_alpha, 0.0, 1.0)
		tile_data.modulate = Color(
			Style.DISCOVERED_TILE_TINT * a, 
			Style.DISCOVERED_TILE_TINT * a, 
			Style.DISCOVERED_TILE_TINT * a, 
			1.0)

func _process(delta: float) -> void:
	var primary_actor: Actor = Finder.get_primary_actor()
	if primary_actor == null: return

	var view_shape = primary_actor.get_node_or_null("ViewBox/PrimaryViewShape")
	if view_shape == null: return

	var view_position = to_global(primary_actor.position + view_shape.position)
	var radius = view_shape.scale.x * SCALE_TO_VIEW

	var tiles_to_fade: Dictionary = {}

	# Gather visible tiles
	for coords in get_used_cells():  # Assumes layer 0
		var tile_position = to_global(map_to_local(coords))
		var change_pos = tile_position - view_position
		var iso_distance = Vector2(change_pos.x / 2, change_pos.y).length()
		var is_visible = iso_distance <= radius

		# Reveal tile (track in fog memory)
		if is_visible:
			discovered_tiles[coords] = true

		var target_alpha: float
		if is_visible:
			target_alpha = 1.0
		elif discovered_tiles.has(coords):
			target_alpha = Style.DISCOVERED_TILE_TINT
		else:
			target_alpha = 0.0
		if not tile_fade_states.has(coords):
			tile_fade_states[coords] = {
				"current_alpha": target_alpha,
				"target_alpha": target_alpha,
				"time_left": 0.0
			}
		else:
			var state = tile_fade_states[coords]
			if abs(state.target_alpha - target_alpha) > 0.01:
				state.target_alpha = target_alpha
				state.time_left = Fader.TRANSITION_TIME

	tiles_to_fade = tile_fade_states.duplicate()

	# Animate fading
	var updated := false
	for coords in tiles_to_fade.keys():
		var state = tile_fade_states[coords]
		if state.time_left > 0.0:
			state.time_left -= delta
			var t = 1.0 - (state.time_left / Fader.TRANSITION_TIME)
			state.current_alpha = lerp(state.current_alpha, state.target_alpha, t)
			updated = true
		else:
			state.current_alpha = state.target_alpha

	# Redraw only if something changed
	if updated:
		notify_runtime_tile_data_update()
