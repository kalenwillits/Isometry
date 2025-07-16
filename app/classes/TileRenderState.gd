extends Object
class_name TileRenderState

var is_discovered: bool = false
var is_in_view: bool = false
var tint: float = 0.0
var alpha: float = 0.0

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
	
func get_modulate() -> Color:
	if is_in_view:
		return Color(Style.VISIBLE_TILE_TINT, Style.VISIBLE_TILE_TINT, Style.VISIBLE_TILE_TINT, Style.VISIBLE_TILE_TINT)
	elif is_discovered:
		return Color(Style.DISCOVERED_TILE_TINT, Style.DISCOVERED_TILE_TINT, Style.DISCOVERED_TILE_TINT, Style.VISIBLE_TILE_TINT)
	else:
		return Color(Style.UNDISCOVERED_TILE_TINT, Style.DISCOVERED_TILE_TINT, Style.UNDISCOVERED_TILE_TINT, Style.UNDISCOVERED_TILE_TINT)
	
	
class UpdateParams: 
	var distance: float
	var radius: float
	
	static func create(distance: float, radius: float) -> UpdateParams:
		var this = UpdateParams.new()
		this.distance = distance
		this.radius = radius
		return this

func update(params: UpdateParams) -> void:
	is_in_view = params.distance <= params.radius
	if is_in_view:
		is_discovered = true
