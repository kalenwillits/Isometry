extends Widget

@export var action_id: int

func _ready() -> void:
	add_to_group(Group.UI_ACTION_BLOCK_N % action_id)
	$Background/VBox/HBox/ColorRect.color = Style.UI_BACKGROUND
	
func render(action_key: String) -> void:
	var action_ent: Entity = Repo.select(action_key)
	if action_ent.icon:
		load_texture(action_ent.icon)

func load_texture(path_to_asset: String) -> void:
	var texture = AssetLoader.builder()\
		.key(path_to_asset)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$Icon/VBox/HBox/Texture.texture = texture
