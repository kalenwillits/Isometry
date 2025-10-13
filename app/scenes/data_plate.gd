extends Widget

const resource_block_packed_scene: PackedScene = preload("res://scenes/resource_block.tscn")

func _ready() -> void:
	add_to_group(Group.UI_DATA_PLATE)

func load_actor_data() -> void:
	for resource_block: Widget in $Grid.get_children():
		resource_block.queue_free()
	var actor: Actor = Finder.get_primary_actor()
	var actor_ent: Entity = Repo.select(actor.actor)
	if actor_ent.private != null:
		for private_resource_key: String in actor_ent.private.keys():
			add_private_resource(private_resource_key)
	# Add private measures
	if actor_ent.measures != null:
		for measure_key: String in actor_ent.measures.keys():
			var measure_ent: Entity = Repo.select(measure_key)
			if measure_ent != null and measure_ent.get("private") == true:
				add_private_resource(measure_key)
	add_to_group(Group.UI_FOCUS_PLATE)
	add_to_group(actor.name)
	
func add_private_resource(resource_key: String) -> void:
	var resource_block: Widget = resource_block_packed_scene.instantiate()
	resource_block.set_actor(Finder.get_primary_actor().get_name())
	resource_block.set_key(resource_key)
	$Grid.add_child(resource_block)
