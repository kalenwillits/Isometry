extends CanvasItemMaterial
class_name FogShader

## Fog shader material for efficient GPU-based visibility effects
## Replaces the expensive per-tile FadingTileMapLayer system

var shader_material: ShaderMaterial
var primary_actor: Actor

class Builder extends Object:
	var this: FogShader = FogShader.new()
	
	func target_node(value: CanvasItem) -> Builder:
		this.apply_to_node(value)
		return self
		
	func build() -> FogShader:
		return this
		
static func builder() -> Builder:
	return Builder.new()

func _init() -> void:
	shader_material = ShaderMaterial.new()
	var fog_shader = load("res://shaders/fog.gdshader")
	shader_material.shader = fog_shader
	
	# Set default values from Style constants
	shader_material.set_shader_parameter("visible_tint", Style.VISIBLE_TILE_TINT)
	shader_material.set_shader_parameter("discovered_tint", Style.DISCOVERED_TILE_TINT)
	shader_material.set_shader_parameter("undiscovered_tint", Style.UNDISCOVERED_TILE_TINT)
	shader_material.set_shader_parameter("fade_distance", 20.0)

func apply_to_node(node: CanvasItem) -> void:
	## Apply fog shader to a CanvasItem (typically a TileMapLayer)
	node.material = shader_material
	
func update_actor_position(actor: Actor) -> void:
	## Update shader uniforms with current primary actor data
	if !actor or !actor.is_primary():
		return
		
	primary_actor = actor
	var actor_pos = actor.global_position
	var view_radius = actor.perception * PI * 32.0  # Matches original BASE_TILE_SIZE calculation

	shader_material.set_shader_parameter("actor_position", actor_pos)
	shader_material.set_shader_parameter("view_radius", view_radius)

func set_fade_distance(distance: float) -> void:
	## Set the smooth fade distance at view radius edge
	shader_material.set_shader_parameter("fade_distance", distance)
	
func enable_discovery_persistence(discovery_texture: ImageTexture) -> void:
	## Enable persistent fog using a discovery texture
	shader_material.set_shader_parameter("use_discovery_texture", true)
	shader_material.set_shader_parameter("discovery_texture", discovery_texture)
	
func disable_discovery_persistence() -> void:
	## Disable persistent fog (real-time only)
	shader_material.set_shader_parameter("use_discovery_texture", false)

func update_style_values() -> void:
	## Update shader parameters to match current Style constants
	shader_material.set_shader_parameter("visible_tint", Style.VISIBLE_TILE_TINT)
	shader_material.set_shader_parameter("discovered_tint", Style.DISCOVERED_TILE_TINT)
	shader_material.set_shader_parameter("undiscovered_tint", Style.UNDISCOVERED_TILE_TINT)
