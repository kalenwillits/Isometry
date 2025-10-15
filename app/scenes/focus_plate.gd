extends Widget

const resource_block_packed_scene: PackedScene = preload("res://scenes/resource_block.tscn")

@export var actor: String ## The actor's name that this plate represents
@export var check_line_of_sight: bool = false ## If true, resource blocks will show "---" when out of LOS

func _ready() -> void:
	if actor == null: return
	if actor == "": return
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
	resource_block.set_check_line_of_sight(check_line_of_sight)
	$Grid.add_child(resource_block)

func set_check_line_of_sight(value: bool) -> void:
	check_line_of_sight = value
	# Update existing resource blocks
	for child in $Grid.get_children():
		if child.has_method("set_check_line_of_sight"):
			child.set_check_line_of_sight(value)
