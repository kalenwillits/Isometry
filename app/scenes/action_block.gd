extends Widget

@export var action_id: int

func _ready() -> void:
	add_to_group(Group.UI_ACTION_BLOCK_N % action_id)
	$Background/VBox/HBox/ColorRect.color = Style.UI_BACKGROUND
	
func render(key: String) -> void:
	var entity: Entity = Repo.select(key)
	if !entity:
		return
		
	# Handle both Skill entities and Action entities
	if entity.has_method("tag") and entity.is_in_group(Group.SKILL_ENTITY):
		# This is a Skill entity
		if entity.icon:
			load_texture(entity.icon)
	elif entity.has_method("tag") and entity.is_in_group(Group.ACTION_ENTITY):
		# This is an Action entity  
		if entity.icon:
			load_texture(entity.icon)

func load_texture(path_to_asset: String) -> void:
	var texture = AssetLoader.builder()\
		.key(path_to_asset)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$Icon/VBox/HBox/Texture.texture = texture
