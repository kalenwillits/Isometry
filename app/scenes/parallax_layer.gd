extends ParallaxBackground

func _ready() -> void:
	add_to_group(Group.PARALLAX)

func load_texture(path_to_asset: String) -> void:
	var texture = AssetLoader.builder()\
		.key(path_to_asset)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.archive)\
		.build()\
		.pull()
	#ImageTexture
	#texture.ti
	#$Layer.set_repeat_size(Vector2(texture.get_width(), texture.get_height()))
	$Layer.set_mirroring(Vector2(texture.get_width(), texture.get_height()))
	$Layer/Sprite.texture = texture
	
func set_effect(value: float) -> void:
	$Layer.motion_scale = Vector2(value, value)
