extends Widget

@export var actor: String
@export var resource_key: String

func _ready() -> void:
	var resource_ent: Entity = Repo.select(resource_key)
	var resource_icon_texture = AssetLoader.builder()\
		.key(resource_ent.icon)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$Button/Icon.set_texture(resource_icon_texture)
	#$Button/Label.set_text()
