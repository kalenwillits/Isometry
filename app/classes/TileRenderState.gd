extends Object
class_name TileRenderState

var is_discovered: bool = false
var is_in_view: bool = false
var tint: float = 0.0
var alpha: float = 0.0
var target_tint: float = 0.0
var target_alpha: float = 0.0
var time_left: float = 0.0

class TileRenderDataBuilder extends Object:
	var this: TileRenderState = TileRenderState.new()
	
	func is_discovered(value: bool) -> TileRenderDataBuilder:
		this.is_discovered = value
		return self
		
	func is_in_view(value: bool) -> TileRenderDataBuilder:
		this.is_in_view = value
		return self
		
	func tint(value: float) -> TileRenderDataBuilder:
		this.tint = value
		return self 
	
	func alpha(value: float) -> TileRenderDataBuilder:
		this.alpha = value
		return self

	func build() -> TileRenderState:
		return this
		
static func builder() -> TileRenderDataBuilder:
	return TileRenderDataBuilder.new()
	
#func get_modulate() -> Color:
	#if is_in_view:
		#return Color(Style.VISIBLE_TILE_TINT, Style.VISIBLE_TILE_TINT, Style.VISIBLE_TILE_TINT, Style.VISIBLE_TILE_TINT)
	#elif is_discovered:
		#return Color(Style.DISCOVERED_TILE_TINT, Style.DISCOVERED_TILE_TINT, Style.DISCOVERED_TILE_TINT, Style.VISIBLE_TILE_TINT)
	#else:
		#return Color(Style.UNDISCOVERED_TILE_TINT, Style.DISCOVERED_TILE_TINT, Style.UNDISCOVERED_TILE_TINT, Style.UNDISCOVERED_TILE_TINT)

func get_modulate() -> Color:
	return Color(tint, tint, tint, alpha)

	
class UpdateParams: 
	var distance: float
	var radius: float
	
	static func create(dist: float, rad: float) -> UpdateParams:
		var this = UpdateParams.new()
		this.distance = dist
		this.radius = rad
		return this
		
func is_active() -> bool:
	return is_in_view or time_left > 0.0

func update(params: UpdateParams) -> void:
	is_in_view = params.distance <= params.radius
	if is_in_view:
		is_discovered = true
		target_tint = Style.VISIBLE_TILE_TINT
		target_alpha = Style.VISIBLE_TILE_TINT
	elif is_discovered:
		target_tint = Style.DISCOVERED_TILE_TINT
		target_alpha = Style.VISIBLE_TILE_TINT
	else:
		target_tint = Style.UNDISCOVERED_TILE_TINT
		target_alpha = Style.UNDISCOVERED_TILE_TINT

	time_left = Fader.TRANSITION_TIME 
	
func tick(delta: float) -> void:
	if time_left > 0.0:
		time_left -= delta
		var t := 1.0 - (time_left / Fader.TRANSITION_TIME)
		alpha = lerp(alpha, target_alpha, t)
		tint = lerp(tint, target_tint, t)
	else:
		alpha = target_alpha
		tint = target_tint
