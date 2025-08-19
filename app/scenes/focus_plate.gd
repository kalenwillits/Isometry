extends Widget

const resource_block_packed_scene: PackedScene = preload("res://scenes/resource_block.tscn")

@export var actor: String ## The actor's name that this plate represents


func _ready() -> void:
	var actor: Actor = Finder.get_actor(actor)
	var actor_ent: Entity = Repo.select(actor.actor)
	var icon_texture = AssetLoader.builder()\
		.key(actor_ent.icon)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$HBox/TextureRect.set_texture(icon_texture)
	set_label(actor.display_name)
	if actor_ent.public != null:
		for public_resource_key: String in actor_ent.public:
			add_public_resource(public_resource_key)
	add_to_group(Group.UI_FOCUS_PLATE)
	add_to_group(actor.name)

func set_label(value: String) -> void:
	$HBox/Label.set_text(value)
	
func set_actor(value: String) -> void:
	actor = value

func add_public_resource(resource_key: String) -> void:
	var resource_block = resource_block_packed_scene.instantiate()
	resource_block.set_actor(actor)
	resource_block.set_key(resource_key)
	$Grid.add_child(resource_block)
