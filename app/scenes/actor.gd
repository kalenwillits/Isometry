extends CharacterBody2D
class_name Actor

enum KeyFrames {
	idle,
	run
}

const BASE_ACTOR_SPEED: float = 10.0
const SPEED_NORMAL: float = 500.0
const DESTINATION_PRECISION: float = 1.1


@export var origin: Vector2
@export var destination: Vector2
@export var speed_mod: float = 1.0
@export var heading: String = "S"
@export var state: String = "idle"
@export var sprite: String = ""
@export var polygon: String = ""
@export var actor: String = ""
@export var hitbox: String = ""
@export var on_touch_action: String = ""
@export var map: String = ""
@export var resources: Dictionary = {}

var peer_id: int = 0

signal on_touch(actor)
signal heading_change(heading)

class ActorBuilder extends Object:
	var obj: = Scene.actor.instantiate()
	
	func peer_id(value: int) -> ActorBuilder:
		obj.peer_id = value
		return self
		
	func name(value: String) -> ActorBuilder:
		obj.name = value
		return self

	func map(value: String) -> ActorBuilder:
		obj.map = value
		return self

	func location(value: Vector2) -> ActorBuilder:
		obj.set_location(value)
		return self

	func actor(value: String) -> ActorBuilder:
		obj.actor = value
		return self

	func build() -> Actor:
		var actor_ent = Repo.query([obj.actor]).pop_front()
		if actor_ent:
			if actor_ent.sprite: obj.sprite = actor_ent.sprite.key()
			if actor_ent.hitbox: obj.hitbox = actor_ent.hitbox.key()
			if actor_ent.polygon: obj.polygon = actor_ent.polygon.key()
			if actor_ent.on_touch: obj.set_on_touch_action(actor_ent.on_touch.key())
			if actor_ent.resources:
				for resource_ent in actor_ent.resources.lookup():
					obj.resources[resource_ent.key()] = resource_ent.default
		return obj
		
static func builder() -> ActorBuilder:
	return ActorBuilder.new()

func pack() -> Dictionary:
	## Pack's the actor's data for transfer across peers
	return {
		"peer_id": peer_id,
		"name": name,
		"location/x": position.x,
		"location/y": position.y,
		"actor": actor,
		"map": map
	}
	
func get_actor_group_name() -> String:
	return "%s_%s" % [Group.ACTOR, actor]
	
func is_primary() -> bool:
	return is_multiplayer_authority() and peer_id > 0 and multiplayer.get_unique_id() == peer_id
	

func _enter_tree():
	add_to_group(get_actor_group_name())
	add_to_group(str(peer_id))
	add_to_group(Group.ACTOR)
	add_to_group(map)
	if peer_id > 0: # PLAYER
		add_to_group(Group.PLAYER)
		set_multiplayer_authority(str(name).to_int())
		if is_primary():
			add_to_group(Group.PRIMARY)
	else: # NPC
		add_to_group(Group.NPC)

func _ready() -> void:
	disable()
	Trigger.new().arm("heading").action(func(): heading_change.emit(heading)).deploy(self)
	Trigger.new().arm("polygon").action(build_polygon).deploy(self)
	Trigger.new().arm("hitbox").action(build_hitbox).deploy(self)
	Trigger.new().arm("sprite").action(build_sprite).deploy(self)
	$Label.set_text(name) # TODO - Replace label with real name
	$Sprite.set_sprite_frames(SpriteFrames.new())
	if is_primary():
		get_parent().get_node("Camera").set_target(self)
		
func enable() -> void:
	visible = true
	collisions(true)
	set_process(true)
	set_physics_process(true)
	
func disable() -> void:
	visible = false
	collisions(false)
	set_process(false)
	set_physics_process(false)

func _physics_process(delta) -> void:
	use_state()
	use_animation()
	if is_primary():
		use_movement(delta)
		click_to_move()
		use_move_directly(delta)

func click_to_move() -> void:
	if Input.is_action_pressed("action"):
		set_destination(get_global_mouse_position())

func despawn() -> void:
	set_process(false)
	set_physics_process(false)
	queue_free()

func move(coordinates: Vector2) -> void:
	set_position(coordinates)
	origin = coordinates
	destination = coordinates


func clear_footprint():
	for node in get_children().filter(func(node): return node.is_class("CollisionPolygon2D")):
		node.queue_free()
		

func set_polygon(value: String) -> void:
	polygon = value
	
func set_hitbox(value: String) -> void:
	hitbox = value
	
func set_actor(value: String) -> void:
	actor = value

func set_on_touch_action(value: String) -> void:
	on_touch_action = value
	Trigger.new().arm("on_touch_action").action(build_on_touch_action).deploy(self)

func build_on_touch_action() -> void:
	if on_touch_action:
		for sig in on_touch.get_connections():
			on_touch.disconnect(sig.callable)
		var action_ent = Repo.select(on_touch_action)
		if !action_ent: return Logger.warn("actor %s carries on_touch_action %s which does not exist." % [name, on_touch_action])
		var params: Dictionary = {}
		if action_ent.parameters:
			for param_ent in action_ent.parameters.lookup():
				params[param_ent.name_] = param_ent.value
		on_touch.connect(func(target): _local_touch_handler(target, func(): get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1,on_touch_action, peer_id, target.peer_id)))

func _local_touch_handler(target: Actor, function: Callable) -> void:
	# Because only one client should allow the trigger, this acts as a filter
	if target.is_primary(): 
		Logger.info("%s on_touch activated by %s" % [name, target.name])
		function.call()

func build_polygon() -> void:
	if !polygon: return
	var polygon_ent = Repo.select(polygon)
	if !polygon_ent: return
	var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
	var vector_array: PackedVector2Array = []
	for vertex in polygon_ent.vertices.lookup():
		vector_array.append(Vector2i(vertex.x, vertex.y))
	collision_polygon.set_polygon(vector_array)
	var polygon_name: String = "FootprintPolygon"
	var existing_polygon = get_node_or_null(polygon_name)
	if existing_polygon != null:
		existing_polygon.queue_free()
		remove_child(existing_polygon)
	collision_polygon.set_name(polygon_name)
	add_child(collision_polygon)
	
func build_hitbox() -> void:
	if !hitbox: return
	var polygon_ent = Repo.select(hitbox)
	if !polygon_ent: return
	var collision_polygon: CollisionPolygon2D = CollisionPolygon2D.new()
	var vector_array: PackedVector2Array = []
	for vertex in polygon_ent.vertices.lookup():
		vector_array.append(Vector2i(vertex.x, vertex.y))
	collision_polygon.set_polygon(vector_array)
	var polygon_name: String = "HitBoxPolygon"
	var existing_polygon = $HitBox.get_node_or_null(polygon_name)
	if existing_polygon != null:
		existing_polygon.queue_free()
	$HitBox.add_child(collision_polygon)
	collision_polygon.set_name(polygon_name)

func set_peer_id(value) -> void:
	if typeof(value) == TYPE_INT:
		peer_id = value
	else:
		peer_id = 0
	
func set_heading(value: String) -> void:
	heading = value

func set_speed_mod(value: float) -> void:
	speed_mod = value
	
func set_sprite(value: String) -> void:
	sprite = value
	
func build_frame(index: int, size: Vector2i, source: String) -> AtlasTexture:
	var external_texture: Texture
	var texture: AtlasTexture
	if Cache.textures.has(source):
		external_texture = Cache.textures[source]
	else:
		Cache.textures[source] = AssetLoader.builder()\
		.archive(Cache.archive)\
		.type(AssetLoader.Type.IMAGE)\
		.key(source)\
		.build()\
		.pull()
	var columns: int = external_texture.get_width() / size.x
	texture = AtlasTexture.new()
	texture.set_atlas(external_texture)
	texture.set_region(std.get_region(index, columns, size))
	return texture

func get_sprite_size() -> Vector2i:
	var sprite_ent = Repo.select(sprite)
	var sprite_size_vertex = sprite_ent.size.lookup()
	return Vector2i(sprite_size_vertex.x, sprite_size_vertex.y)
	
func get_sprite_margin() -> Vector2i:
	var sprite_ent = Repo.select(sprite)
	var sprite_margin_vertex = sprite_ent.margin.lookup()
	return Vector2i(sprite_margin_vertex.x, sprite_margin_vertex.y)

func build_sprite() -> void:
	var sprite_ent = Repo.select(sprite)
	if !sprite_ent: return
	if !Cache.textures.has(sprite_ent.texture):
		Cache.textures[sprite_ent.texture] = AssetLoader.builder()\
		.archive(Cache.archive)\
		.type(AssetLoader.Type.IMAGE)\
		.key(sprite_ent.texture)\
		.build()\
		.pull()
	var texture = Cache.textures.get(sprite_ent.texture)
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	var animation_ent = sprite_ent.animation.lookup()
	for key_frame_name in KeyFrames.keys():
		if animation_ent.get(key_frame_name) == null: continue
		var key_frame_ent = animation_ent.get(key_frame_name).lookup()
		for radial in std.RADIALS.keys():
			var animation_radial_name: String = "%s:%s" % [key_frame_name, radial]
			sprite_frames.add_animation(animation_radial_name)
			for frame in key_frame_ent.get(radial):
				sprite_frames.add_frame(
					animation_radial_name, 
						build_frame(
							frame,
							get_sprite_size(),
							sprite_ent.texture,
						)
					);
		setup_sprite.call_deferred(sprite_frames)

func setup_sprite(sprite_frames: SpriteFrames) -> void:
		## Setting up a sprite sheet dynamically is a touchy thing. It must be started in this order.
		$Sprite.offset = _calculate_sprite_offset()
		$Sprite.set_sprite_frames(sprite_frames)
		$Sprite.set_animation("default")

func _calculate_sprite_offset() -> Vector2i:
	var full_size: Vector2i = get_sprite_size()
	var margin: Vector2i = get_sprite_margin()
	var actual_size: Vector2i = full_size - margin
	var result: Vector2i = -actual_size
	result.x += ((full_size.x / 2) - (margin.x))
	return result

func use_movement(delta: float) -> void:
	if position.distance_squared_to(destination) > DESTINATION_PRECISION:
		var motion = position.direction_to(destination)
		velocity = motion * get_speed(delta) * std.isometric_factor(motion.angle())
		look_at_point(destination)
		move_and_slide()
	else:
		set_destination(position)
		velocity = Vector2.ZERO

func look_at_point(point: Vector2) -> void:
	heading = map_radial(point.angle_to_point(position))
	
func map_radial(radians: float) -> String:
	return std.RADIALS.keys()[snap_radial(radians)]
	
func snap_radial(radians: float) -> int:
	return wrapi(snapped(radians, PI/4) / (PI/4), 0, 8)
	
func get_speed(delta: float) -> float:
	return BASE_ACTOR_SPEED * delta * speed_mod * SPEED_NORMAL
	
func use_move_directly(_delta) -> void:
	var motion = Input.get_vector("left", "right", "up", "down")
	var new_destination: Vector2 = position + motion

	if motion.length():
		set_destination(new_destination)
		look_at_point(new_destination)
		
	
func set_destination(point: Vector2) -> void:
	## Where the actor is headed to.
	set_origin(position)
	destination = point
	
func set_origin(point: Vector2) -> void:
	## Where the actor started before moving.
	origin = point
	
func set_location(point: Vector2) -> void:
	## Where the actor is located and is not moving.
	set_destination(point)
	set_position(point)
	set_origin(point)
	
func use_animation():
	if $Sprite.sprite_frames.has_animation("%s:%s" % [state, heading]):
		$Sprite.animation = "%s:%s" % [state, heading]
#		$Outline.animation = animation
	elif $Sprite.sprite_frames.has_animation("default:%s" % heading):
		$Sprite.animation = "default:%s" % heading
	else:
		$Sprite.animation = "default"
		
		
func set_remote_transform_target(node: Node) -> void:
	$RemoteTransform2D.remote_path = node.get_path()
	
func clear_remote_transform_target() -> void:
	$RemoteTransform2D.remote_path = null

func set_state(value: String) -> void:
	state = value
	
func set_animation_speed(value: float) -> void:
	$Sprite.speed_scale = value
	
func use_state() -> void:
	match state:
		"idle":
			if !position.is_equal_approx(destination):
				set_animation_speed(std.isometric_factor(velocity.angle()))
				set_state("run")
		# TODO -- add walking
		"run": 
			if position.is_equal_approx(destination):
				set_state("idle")

func _on_sprite_animation_finished() -> void:
	match state:
		"idle", "run", "dead":  # These are states that do not automatically resolve to idle.
			pass
		_:
			set_state("idle")
			set_animation_speed(1.0)

func _on_heading_change(_radial):
	pass

func _on_hit_box_body_entered(other):
	if other != self and $HitboxTriggerCooldownTimer.is_stopped():
		$HitboxTriggerCooldownTimer.start()
		on_touch.emit(other)
		
func collisions(enabled: bool) -> void:
	for node in get_children():
		if node.is_class("CollisionPolygon2D"):
			node.disabled = !enabled
	for node in $HitBox.get_children():
		if node.is_class("CollisionPolygon2D"):
			node.disabled = !enabled

func _on_sprite_animation_changed():
	$Sprite.play()
