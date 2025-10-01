extends Widget

@export var actor: String
@export var resource_key: String

var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.1

func _ready() -> void:
	var resource_ent: Entity = Repo.select(resource_key)
	if resource_ent == null: return
	var resource_icon_texture: ImageTexture = AssetLoader.builder()\
		.key(resource_ent.icon)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$Button/Icon.set_texture(resource_icon_texture)
	
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
		
		var resource_value = get_resource_value()
		if resource_value != null:
			label.set_text(format_resource_value(resource_value))
	
func format_resource_value(value: int) -> String:
	return std.format_number(value)
	
func get_resource_value():
	if actor == null or actor.is_empty():
		return null
	if resource_key == null or resource_key.is_empty():
		return null
		
	var actor_obj = Finder.get_actor(actor)
	if actor_obj == null:
		return null
	if actor_obj.resources == null:
		return null
		
	return actor_obj.resources.get(resource_key)
	
func set_actor(value: String) -> void:
	actor = value
	
func set_resource_key(value: String) -> void:
	resource_key = value
