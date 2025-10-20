extends Widget

const resource_block_packed_scene: PackedScene = preload("res://scenes/resource_block.tscn")

@export var actor: String ## The actor's name that this plate represents
@export var check_in_view: bool = false ## If true, resource blocks will show "---" when out of view

var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	if actor == null: return
	if actor == "": return
	var actor_node: Actor = Finder.get_actor(actor)
	if actor_node == null:
		queue_free()
		return
	var actor_ent: Entity = Repo.select(actor_node.actor)
	set_label(actor_node.display_name)

	# Set group label with color
	if actor_node.target_group != "" and actor_node.target_group != Group.DEFAULT_TARGET_GROUP:
		var group_ent: Entity = Repo.select(actor_node.target_group)
		if group_ent != null:
			var group_name: String = ""
			var group_color_hex: String = ""

			if group_ent.name != null:
				group_name = group_ent.name
			if group_ent.color != null:
				group_color_hex = group_ent.color

			if group_name != "" and group_color_hex != "":
				set_group_label(group_name, _parse_hex_color(group_color_hex))
			else:
				hide_group_label()
		else:
			hide_group_label()
	else:
		hide_group_label()

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
	resource_block.set_check_in_view(check_in_view)
	$Grid.add_child(resource_block)

func set_check_in_view(value: bool) -> void:
	check_in_view = value
	# Update existing resource blocks
	for child in $Grid.get_children():
		if child.has_method("set_check_in_view"):
			child.set_check_in_view(value)

func set_group_label(group_name: String, color: Color) -> void:
	$GroupLabel.set_text(group_name)
	$GroupLabel.add_theme_color_override("font_color", color)
	# Add outline effect
	$GroupLabel.add_theme_color_override("font_outline_color", color)
	$GroupLabel.add_theme_constant_override("outline_size", 2)
	$GroupLabel.visible = true

func hide_group_label() -> void:
	$GroupLabel.visible = false

func _parse_hex_color(hex_string: String) -> Color:
	# Parse hex color string (e.g., "#FF0000" or "FF0000")
	if hex_string == "":
		return Color.WHITE

	var hex = hex_string.strip_edges()
	if hex.begins_with("#"):
		hex = hex.substr(1)

	# Validate hex string length
	if hex.length() != 6:
		return Color.WHITE

	# Parse RGB components
	var r = hex.substr(0, 2).hex_to_int()
	var g = hex.substr(2, 2).hex_to_int()
	var b = hex.substr(4, 2).hex_to_int()

	# Check if parsing was successful
	if r < 0 or g < 0 or b < 0 or r > 255 or g > 255 or b > 255:
		return Color.WHITE

	return Color(r / 255.0, g / 255.0, b / 255.0, 1.0)

func _process(delta: float) -> void:
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		if check_in_view:
			var primary_actor: Actor = Finder.get_primary_actor()
			var is_self: bool = primary_actor and actor == primary_actor.name
			modulate.a = 0.5 if primary_actor and not is_self and not actor in primary_actor.in_view else 1.0
