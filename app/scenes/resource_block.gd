extends Widget

@export var actor: String
@export var key: String
@export var check_in_view: bool = false  ## If true, show "---" when out of view

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
	$Button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	var entity: Entity = Repo.select(key)
	if entity and entity.menu:
		Finder.select(Group.INTERFACE).open_selection_menu_for_entity(key, actor)

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
			# Check if actor is in view if enabled
			if check_in_view and not is_actor_in_view():
				label.set_text("---")
			else:
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

func set_check_in_view(value: bool) -> void:
	check_in_view = value

func is_actor_in_view() -> bool:
	if actor == null or actor.is_empty():
		return false

	var primary_actor: Actor = Finder.get_primary_actor()
	if primary_actor == null:
		return false

	var target_actor: Actor = Finder.get_actor(actor)
	if target_actor == null:
		return false

	# Always in view if targeting self
	if actor == primary_actor.name:
		return true

	# Check if the target actor is in the primary actor's view (within ViewBox)
	return actor in primary_actor.in_view
