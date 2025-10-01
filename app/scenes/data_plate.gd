extends Widget

const resource_block_packed_scene: PackedScene = preload("res://scenes/resource_block.tscn")

func _ready() -> void:
	add_to_group(Group.UI_DATA_PLATE)

func load_actor_data() -> void:
	for resource_block: Widget in $Grid.get_children():
		resource_block.queue_free()
	var actor: Actor = Finder.get_primary_actor()
	var actor_ent: Entity = Repo.select(actor.actor)
	var icon_texture = AssetLoader.builder()\
		.key(actor_ent.icon)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$HBox/TextureRect.set_texture(icon_texture)
	set_label(actor.display_name)
	if actor_ent.private != null:
		for private_resource_key: String in actor_ent.public.keys():
			add_private_resource(private_resource_key)
	add_to_group(Group.UI_FOCUS_PLATE)
	add_to_group(actor.name)

func set_label(value: String) -> void:
	$HBox/Label.set_text(value)
	
func add_private_resource(resource_key: String) -> void:
	var resource_block: Widget = resource_block_packed_scene.instantiate()
	resource_block.set_resource_key(resource_key)
	$Grid.add_child(resource_block)
