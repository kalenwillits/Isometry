extends Widget

@export var action_id: int

func _ready() -> void:
	add_to_group(Group.UI_ACTION_BLOCK_N % action_id)
	
func render(key: String) -> void:
	var entity: Entity = Repo.select(key)
	if !entity:
		return

	if entity.icon:
		load_texture(entity.icon)

func load_texture(path_to_asset: String) -> void:
	var texture: ImageTexture = AssetLoader.builder()\
		.key(path_to_asset)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	texture.set_size_override(Style.ICON_SIZE)
	$Button/VBox/HBox/Button.icon = texture
	
func press_button() -> void:
	$Button/VBox/HBox/Button.button_pressed = true
	
func release_button() -> void:
	$Button/VBox/HBox/Button.button_pressed = false
	
func get_action_code() -> String:
	return "action_%s" % action_id
			
