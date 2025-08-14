extends ParallaxBackground

const SCALAR: float = 100.0

func _ready() -> void:
	Logger.debug("Parallax layer initialized: %s" % name, self)
	add_to_group(Group.PARALLAX)

func load_texture(path_to_asset: String) -> void:
	Logger.debug("Loading texture for parallax layer %s: %s" % [name, path_to_asset], self)
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
	Logger.trace("Setting parallax effect for %s: %s" % [name, value], self)
	$Layer.motion_scale = Vector2(_format_effect(value), _format_effect(value))
	
func set_visibility(effect: bool) -> void:
	Logger.debug("Setting parallax visibility for %s: %s" % [name, effect], self)
	visible = effect
