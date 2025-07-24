extends ParallaxBackground

const SCALAR: float = 100.0

func _ready() -> void:
	add_to_group(Group.PARALLAX)

func load_texture(path_to_asset: String) -> void:
	var texture = AssetLoader.builder()\
		.key(path_to_asset)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$Layer.set_mirroring(Vector2(texture.get_width(), texture.get_height()))
	$Layer/Sprite.texture = texture
	
func _format_effect(value: float) -> float:
	## Allows users to think in whole numbers.
	return value / SCALAR

func set_effect(value: float) -> void:
	$Layer.motion_scale = Vector2(_format_effect(value), _format_effect(value))
	
func set_visibility(effect: bool) -> void:
	visible = effect
