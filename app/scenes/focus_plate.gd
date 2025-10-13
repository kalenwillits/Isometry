extends Widget

const resource_block_packed_scene: PackedScene = preload("res://scenes/resource_block.tscn")

@export var actor: String ## The actor's name that this plate represents

func _ready() -> void:
	var actor_node: Actor = Finder.get_actor(actor)
	var actor_ent: Entity = Repo.select(actor_node.actor)
	set_label(actor_node.display_name)
	if actor_ent.public != null:
		for public_resource_key: String in actor_ent.public.keys():
			add_public_resource(public_resource_key)
	# Add public measures
	if actor_ent.measures != null:
		for measure_key: String in actor_ent.measures.keys():
			var measure_ent: Entity = Repo.select(measure_key)
			if measure_ent != null and measure_ent.get("public") == true:
				add_public_resource(measure_key)
	add_to_group(Group.UI_FOCUS_PLATE)
	add_to_group(actor_node.name)

func set_label(value: String) -> void:
	$HBox/Label.set_text(value)
	
func set_actor(value: String) -> void:
	actor = value

func add_public_resource(resource_key: String) -> void:
	var resource_block: Widget = resource_block_packed_scene.instantiate()
	resource_block.set_actor(actor)
	resource_block.set_key(resource_key)
	$Grid.add_child(resource_block)
