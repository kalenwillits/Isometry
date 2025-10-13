extends Widget

@export var actor: String
@export var key: String

var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	var entity: Entity = Repo.select(key)
	if entity == null: return
	var icon_texture: ImageTexture = AssetLoader.builder()\
		.key(entity.icon)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$Button/Icon.set_texture(icon_texture)

func _process(_delta: float) -> void:
	update_timer += _delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0

		if not has_node("Button"):
			return
		var button = $Button
		if not button.has_node("Label"):
			return
		var label = button.get_node("Label")

		var value = get_value()
		if value != null:
			label.set_text(format_value(value))

		# Handle visibility based on reveal threshold
		var entity: Entity = Repo.select(key)
		if entity != null:
			var reveal_threshold: int = entity.get("reveal") if entity.get("reveal") != null else 0
			visible = (value != null and value >= reveal_threshold)

func format_value(value: int) -> String:
	return std.format_number(value)

func get_value():
	if actor == null or actor.is_empty():
		return null
	if key == null or key.is_empty():
		return null

	var actor_obj = Finder.get_actor(actor)
	if actor_obj == null:
		return null

	# Determine if this is a Resource or Measure
	var entity: Entity = Repo.select(key)
	if entity == null:
		return null

	if entity.is_in_group(Group.RESOURCE_ENTITY):
		if actor_obj.resources == null:
			return null
		return actor_obj.get_resource(key)
	elif entity.is_in_group(Group.MEASURE_ENTITY):
		return actor_obj.get_measure(key)

	return null

func set_actor(value: String) -> void:
	actor = value

func set_key(value: String) -> void:
	key = value

func set_resource_key(value: String) -> void:
	# Backward compatibility
	key = value
