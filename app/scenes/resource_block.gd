extends Widget

@export var actor: String
@export var resource_key: String

func _ready() -> void:
	var resource_ent: Entity = Repo.select(resource_key)
	var resource_icon_texture: ImageTexture = AssetLoader.builder()\
		.key(resource_ent.icon)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$Button/Icon.set_texture(resource_icon_texture)
	
func _process(_delta: float) -> void:
	# TODO - make this not run every frame. (Optimization)
	$Button/Label.set_text(format_resource_value(get_resource_value()))
	
func format_resource_value(value: int) -> String:
	# TODO for claude
	return str(value) # TODO
	
func get_resource_value() -> int:
	return Finder.get_actor(actor).resources.get(resource_key)
	
func set_actor(value: String) -> void:
	actor = value
	
func set_resource_key(value: String) -> void:
	resource_key = value
