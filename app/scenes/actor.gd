extends CharacterBody2D
class_name Actor

# TODO - actions should still be requested even if the target is null

enum KeyFrames {
	idle,
	run
}

const BASE_TILE_SIZE: float = 32.0
const BASE_ACTOR_SPEED: float = 10.0
const SPEED_NORMAL: float = 500.0
const DESTINATION_PRECISION: float = 1.1

@export var origin: Vector2
@export var destination: Vector2
@export var speed: float = 1.0
@export var heading: String = "S"
@export var state: String = "idle"
@export var sprite: String = ""
@export var polygon: String = ""
@export var actor: String = ""
@export var hitbox: String = ""
@export var map: String = ""
@export var target: String = ""
@export var resources: Dictionary = {}

var peer_id: int = 0
var view: int = -1
var target_queue: Array = []
var target_groups: Array = []
var target_group_index: int = 0
var target_groups_counter: Dictionary
var measures: Dictionary = {
	"distance_to_target": _built_in_measure__distance_to_target,
	"distance_to_destination": _built_in_measure__distance_to_destination,
}
var strategy: Strategy

signal on_touch(actor)
signal primary(actor)
signal action_1(actor)
signal action_2(actor)
signal action_3(actor)
signal action_4(actor)
signal action_5(actor)
signal action_6(actor)
signal action_7(actor)
signal action_8(actor)
signal action_9(actor)

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
	
	func view(value: String) -> ActorBuilder:
		obj.view = value
		return self

	func location(value: Vector2) -> ActorBuilder:
		obj.set_location(value)
		return self

	func actor(value: String) -> ActorBuilder:
		obj.actor = value
		return self
		
	func resources(value: Dictionary) -> ActorBuilder:
		obj.resources = value
		return self

	func build() -> Actor:
		var actor_ent = Repo.query([obj.actor]).pop_front()
		if actor_ent:
			obj.build_viewbox(actor_ent.view)
			if actor_ent.groups: obj.build_target_groups(actor_ent.groups.lookup())
			if actor_ent.sprite: obj.sprite = actor_ent.sprite.key()
			if actor_ent.hitbox: obj.hitbox = actor_ent.hitbox.key()
			if actor_ent.polygon: obj.polygon = actor_ent.polygon.key()
			if actor_ent.on_touch: obj.build_on_touch_action(actor_ent.on_touch.key())
			if actor_ent.primary_action: obj.build_primary_action(actor_ent.primary_action.key())
			for n in range(1, 10):
				var action_name: String = "action_%d" % n
				if actor_ent.get(action_name): obj.build_action(actor_ent.get(action_name).key(), n)
			# build resources
			for resource_ent in Repo.query([Group.RESOURCE_ENTITY]):
				obj.resources[resource_ent.key()] = obj.resources.get(resource_ent.key(), resource_ent.default)
			# build measures
			for measure_ent in Repo.query([Group.MEASURE_ENTITY]):
				obj.measure[measure_ent.key()] = obj.build_measure(measure_ent)
		return obj
		
static func builder() -> ActorBuilder:
	return ActorBuilder.new()

func pack() -> Dictionary:
	return {
		"peer_id": peer_id,
		"name": name,
		"location/x": position.x,
		"location/y": position.y,
		"actor": actor,
		"map": map,
		"resources": resources
	}
	
func is_primary() -> bool:
	return is_multiplayer_authority() and peer_id > 0 and multiplayer.get_unique_id() == peer_id

func _enter_tree():
	add_to_group(Group.ACTOR)
	add_to_group(map)
	add_to_group(name)
	add_to_group(Group.DEFAULT_TARGET_GROUP)
	build_triggers()
	build_timers()
	build_strategy()
	if peer_id > 0: # PLAYER
		add_to_group(Group.PLAYER)
		set_multiplayer_authority(str(name).to_int())
		if is_primary():
			add_to_group(Group.PRIMARY)
	else: # NPC
		add_to_group(Group.NPC)
		
func _exit_tree() -> void:
	if is_primary():
		Finder.query([Group.ACTOR]).map(
			func(a): 
				a.is_awake(false)
				a.visible_to_primary(false)
		)

func _ready() -> void:
	is_awake(false)
	visible_to_primary(false)
	Trigger.new().arm("heading").action(func(): heading_change.emit(heading)).deploy(self)
	Trigger.new().arm("polygon").action(build_polygon).deploy(self)
	Trigger.new().arm("hitbox").action(build_hitbox).deploy(self)
	Trigger.new().arm("sprite").action(build_sprite).deploy(self)
	$Label.set_text(name) # TODO - Replace label with real name
	$Sprite.set_sprite_frames(SpriteFrames.new())
	if is_primary():
		Transition.appear()
		build_target_groups_counter()
		is_awake(true)
		visible_to_primary(true)
		get_parent().get_node("Camera").set_target(self)
		$HitBox.area_entered.connect(_on_hit_box_body_entered)
		$ViewBox.area_entered.connect(_on_view_box_area_entered)
		$ViewBox.area_exited.connect(_on_view_box_area_exited)
		schedule_render_this_actors_map()
		Queue.enqueue(
			Queue.Item.builder()
			.task(func(): Finder.query([Group.ACTOR, map]).map(func(a): a.is_awake(true)))
			.build()
		)

func schedule_render_this_actors_map() -> void:
	Queue.enqueue(
		Queue.Item.builder()
			.task(func(): get_parent().render_map(map))
			.condition(func(): return get_tree().get_first_node_in_group(str(multiplayer.get_unique_id())))
			.build()
		)

func is_awake(effect: bool) -> void:
	use_collisions(effect)

func _physics_process(delta) -> void:
	use_state()
	use_animation()
	use_strategy()
	if is_primary():
		use_movement(delta)
		click_to_move()
		use_move_directly(delta)
		use_actions()
		use_target()
	if is_npc() and std.is_host_or_server():
		use_movement(delta)

func _built_in_measure__distance_to_target() -> int:
	Optional.of_nullable(Finder.select(target))\
		.map(func(t): return isometric_distance_to_actor(t) * BASE_TILE_SIZE)\
		.get_value()
	return -1
	
func _built_in_measure__distance_to_destination() -> int:
	return isometric_distance_to_point(destination) * BASE_TILE_SIZE

func use_strategy() -> void:
	if strategy == null: return
	if std.is_host_or_server():
		strategy.use(
			ActorInteraction.builder()
			.caller(self)
			.target(Finder.select(target))
			.build())

func use_actions() -> void:
	if Input.is_action_just_released("action_1"):
		emit_signal("action_1", get_parent().get_node_or_null(target))
	if Input.is_action_just_released("action_2"):
		emit_signal("action_2", get_parent().get_node_or_null(target))
	if Input.is_action_just_released("action_3"):
		emit_signal("action_3", get_parent().get_node_or_null(target))
	if Input.is_action_just_released("action_4"):
		emit_signal("action_4", get_parent().get_node_or_null(target))
	if Input.is_action_just_released("action_5"):
		emit_signal("action_5", get_parent().get_node_or_null(target))
	if Input.is_action_just_released("action_6"):
		emit_signal("action_6", get_parent().get_node_or_null(target))
	if Input.is_action_just_released("action_7"):
		emit_signal("action_7", get_parent().get_node_or_null(target))
	if Input.is_action_just_released("action_8"):
		emit_signal("action_8", get_parent().get_node_or_null(target))
	if Input.is_action_just_released("action_9"):
		emit_signal("action_9", get_parent().get_node_or_null(target))

func use_target() -> void:
	if Input.is_action_just_pressed("increment_target"):
		target = find_next_target()
		print("TARGET: %s" % target)
	if Input.is_action_just_pressed("decrement_target"):
		target = find_prev_target()
		print("TARGET: %s" % target)
	if Input.is_action_just_pressed("clear_target"):
		target = ""
		target_queue.clear()
	if Input.is_action_just_pressed("increment_target_group"):
		target_group_index = increment_target_group()
		print("TARGET_GROUP: %s" % get_target_group())
	if Input.is_action_just_pressed("decrement_target_group"):
		print("TARGET_GROUP: %s" % get_target_group())
		target_group_index = decrement_target_group()
		
func get_targetable_groups() -> Array:
	var targetable_keys: Array = []
	for key in target_groups_counter.keys():
		if target_groups_counter[key] > 0: targetable_keys.append(key)
	return targetable_keys

func increment_target_group() -> int:
	return (target_group_index + 1) % get_targetable_groups().size()

func decrement_target_group() -> int:
	return max((target_group_index - 1), 0)
	
func get_target_group() -> String:
	return get_targetable_groups()[target_group_index]

func find_next_target() -> String:
	var actors = Finder.query([Group.IS_VISIBLE, get_target_group()])
	actors.sort_custom(func(a, b): isometric_distance_to_actor(a) > isometric_distance_to_actor(b))
	if target_queue.size() >= actors.size():
		target_queue.clear()
	while !actors.is_empty():
		var next_actor = actors.pop_front()
		if !(next_actor.name in target_queue):
			target_queue.append(next_actor.name)
			return next_actor.name
	return ""

func find_prev_target() -> String:
	var actors = Finder.query([Group.IS_VISIBLE, get_target_group()])
	actors.sort_custom(func(a, b): isometric_distance_to_actor(a) < isometric_distance_to_actor(b))
	if target_queue.size() >= actors.size():
		target_queue.clear()
	while !actors.is_empty():
		var next_actor = actors.pop_front()			
		if !(next_actor.name in target_queue):
			target_queue.append(next_actor.name)
			return next_actor.name
	return ""

func isometric_distance_to_actor(other: Actor) -> float:
	if other == null: return 0.0
	return position.distance_to(other.position) * std.isometric_factor(position.angle_to(other.position))
	
func isometric_distance_to_point(point: Vector2) -> float:
	return position.distance_to(point) * std.isometric_factor(position.angle_to(point))

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

func build_on_touch_action(value: String) -> void:
	var action_ent = Repo.select(value)
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	on_touch.connect(func(target): _local_touch_handler(target, func(target): get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, value, name, target.name)))

func build_action(value: String, n: int) -> void:
	var action_ent = Repo.select(value)
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	connect("action_%d" % n, func(target): _local_action_handler(
		target, 
		func(target): 
			var target_name: String
			if target != null: target_name = target.name
			get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, value, name, target_name),
		action_ent.range_ * BASE_TILE_SIZE))

func build_measure(value: String) -> void:
	return Optional.of(Repo.select(value))\
		.map(func(e): return func(interaction): _local_measure_handler(name, target, e.expression))\
		.get_value()
		
func build_strategy() -> void:
	if std.is_host_or_server():
		# TODO WIP - This chain is not completing
		Optional.of(Repo.select(actor))\
			.map(func(e): return e.strategy)\
			.map(func(e): return e.lookup())\
			.if_present(set_strategy)

func set_strategy(value: Entity) -> void:
	var behaviors: Array[Behavior] = []
	for behavior_ent in value.behaviors.lookup():
		behaviors.append(
			Behavior.builder().criteria(behavior_ent.criteria.key()).action(func(interaction): _local_action_handler(interaction.target, func(t): Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, behavior_ent.action.key(), name, Optional.of_nullable(t).map(func(t): return t.get_name()).or_else("")), behavior_ent.action.lookup().range_)).build()
		)
	strategy = Strategy.builder().behaviors(behaviors).build()

func build_triggers() -> void:
	if std.is_host_or_server():
			var actor_ent: Entity = Repo.select(actor)
			if actor_ent.triggers == null: return
			for trigger_ent in actor_ent.triggers.lookup():
				Trigger.new()\
				.arm("resources/%s" % trigger_ent.resource.key())\
				.action(
					func():
						_local_action_handler(
							self,  # Both caller and target for triggers is always self
							func(target):
								Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, trigger_ent.action.key(), name, name),
								trigger_ent.action.lookup().range_ * BASE_TILE_SIZE
						)
				).deploy(self)
				
func build_timers() -> void:
		if std.is_host_or_server():
			var actor_ent: Entity = Repo.select(actor)
			if actor_ent.triggers == null: return
			for timer_ent in actor_ent.timers.lookup():
				Queue.enqueue(
					Queue.Item.builder()
					.comment("Build resource timer %s on actor %s" % [timer_ent.key(), name])
					.task(
						func():
							add_child(ResourceTimer.builder().total(timer_ent.total).interval(timer_ent.interval).action(
								func(): _local_action_handler(
										Optional.of_nullable(get_parent().get_node_or_null(target)).or_else(self), 
										func(target): get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, timer_ent.action.key(), name, target.name),
										timer_ent.action.lookup().range_ * BASE_TILE_SIZE)						
							).build()))
					.build()
				)

func build_target_groups(groups: Array) -> void:
	target_groups = [Group.DEFAULT_TARGET_GROUP]
	for group in groups:
		add_to_group(group.key())
		target_groups.append(group.key())
	
func build_target_groups_counter() -> void:
	target_groups_counter = { Group.DEFAULT_TARGET_GROUP: 1 }
	for group_ent in Repo.query([Group.GROUP_ENTITY]):
		target_groups_counter[group_ent.key()] = 0
		
func _local_measure_handler(caller_name: String, target_name: String, expression: String) -> int:
	return Dice.builder()\
		.scene_tree(get_tree())\
		.target_name(target_name)\
		.caller_name(caller_name)\
		.build()\
		.evaluate()

func _local_touch_handler(target: Actor, function: Callable) -> void:
	# Because only one client should allow the trigger, this acts as a filter
	if target.is_primary(): 
		Logger.info("%s on_touch activated by %s" % [name, target.name])
		function.call(target)
		
func _local_action_handler(target: Actor, function: Callable, range_: int) -> void:
	var distance: float = isometric_distance_to_actor(target)
	if distance > range_:
		if target != null: Logger.info("%s action activated by %s but is out of range %d at %f" % [name, target.name, range_ / BASE_TILE_SIZE, distance / BASE_TILE_SIZE])
		# TODO - alert user that it's out of range
	else:
		if target != null: Logger.info("actor %s activated an action on target %s" % [name, target.name])
		function.call(target)
		
func build_primary_action(value: String) -> void:
	var action_ent = Repo.select(value)
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	primary.connect(func(target): _local_action_handler(
		target, 
		func(target): get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, value, peer_id, target.peer_id),
		action_ent.range_ * BASE_TILE_SIZE))

func _local_primary_handler(target: Actor, function: Callable) -> void:
	# Because only one client should allow the trigger, this acts as a filter
	if target.is_primary(): 
		Logger.info("%s primary activated by %s" % [name, target.name])
		function.call(target)

func build_viewbox(value: int) -> void:
	if value > 0:
		for node in $ViewBox.get_children(): node.queue_free()
		var view_shape: CollisionShape2D = CollisionShape2D.new()
		view_shape.name = "PrimaryViewShape"
		view_shape.shape = CircleShape2D.new()
		view_shape.apply_scale(Vector2(1 * value, 0.5 * value))
		$ViewBox.add_child(view_shape)

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
	speed = value
	
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
	
func visible_to_primary(effect: bool) -> void:
	if effect: 
		add_to_group(Group.IS_VISIBLE)
	else:
		remove_from_group(Group.IS_VISIBLE)
	visible = effect
	
func handle_resource_change(resource: String) -> void:
	print("%s resource change %s" % [name, resources.get(resource)])
	pass

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
	return BASE_ACTOR_SPEED * delta * speed * SPEED_NORMAL
	
func use_move_directly(_delta) -> void:
	var motion = Input.get_vector("left", "right", "up", "down")
	var new_destination: Vector2 = position + motion * DESTINATION_PRECISION

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
		other.get_parent().on_touch.emit(self)
		
func use_collisions(effect: bool) -> void:
	set_collision_layer_value(Layer.BASE, effect)
	set_collision_mask_value(Layer.BASE, effect)
	set_collision_mask_value(Layer.WALL, effect)
	$HitBox.set_collision_layer_value(Layer.HITBOX, effect)
	$HitBox.set_collision_mask_value(Layer.HITBOX, effect)
	$ViewBox.set_collision_layer_value(Layer.VIEWBOX, effect)
	$ViewBox.set_collision_mask_value(Layer.HITBOX, effect)
	$ViewBox.set_collision_mask_value(Layer.BASE, effect)

func _on_sprite_animation_changed():
	$Sprite.play()

func _on_mouse_entered() -> void:
	print("mouse entered %s" % name)

func _on_mouse_exited() -> void:
	print("mouse exited %s" % name)

func _on_hit_box_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action("primary_action"):
		var primary_actor = get_tree().get_first_node_in_group(str(multiplayer.get_unique_id()))
		Logger.info("primary action invoked on %s" % name)
		primary.emit(primary_actor)

func _on_hit_box_mouse_entered() -> void:
	print("mouse entered %s" % name) # TODO remove

func _on_hit_box_mouse_exited() -> void:
	print("mouse exited %s" % name) # TODO -remove

func _on_view_box_area_entered(area: Area2D) -> void:
	var other = area.get_parent()
	for target_group_key in other.target_groups:
		target_groups_counter[target_group_key] = target_groups_counter[target_group_key] + 1

	other.visible_to_primary(true)

func _on_view_box_area_exited(area: Area2D) -> void:
	var other = area.get_parent()
	for target_group_key in other.target_groups:
		target_groups_counter[target_group_key] = target_groups_counter[target_group_key] - 1
	other.visible_to_primary(false)
	
func is_npc() -> bool:
	return is_in_group(Group.NPC)
