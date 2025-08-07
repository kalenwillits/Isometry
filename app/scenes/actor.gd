extends CharacterBody2D
class_name Actor

enum SubState {
	IDLE,
	START,
	USE,
	END
}

const BASE_TILE_SIZE: float = 32.0
const BASE_ACTOR_SPEED: float = 10.0
const SPEED_NORMAL: float = 500.0
const DESTINATION_PRECISION: float = 1.1
const VIEW_SPEED: float = 4

# Navigation constants
#const NAV_AGENT_RADIUS: float = 16.0  # Half tile size for collision radius
const NAV_NEIGHBOR_DISTANCE: float = 32.0
const NAV_PATH_DESIRED_DISTANCE: float = 8.0  # Quarter tile for path points
const NAV_TARGET_DESIRED_DISTANCE: float = DESTINATION_PRECISION  # Use existing precision
const NAV_PATH_MAX_DISTANCE: float = 32.0  # 4x tile size for path recalculation

@export var token: PackedByteArray
@export var display_name: String
@export var origin: Vector2
@export var destination: Vector2
@export var fix: Vector2
@export var speed: float = 1.0
@export var heading: String = "S"
@export var state: String = "idle"
@export var substate: SubState  # TODO - use to get status of current state loop
@export var sprite: String = ""
@export var base: int = 0
@export var actor: String = ""
@export var hitbox: String = ""
@export var map: String = ""
@export var target: String = ""
@export var resources: Dictionary = {}

var fader: Fader
var peer_id: int = 0
var view: int = -1
var target_queue: Array = []
var target_groups: Array = []
var target_group_index: int = 0
var speed_cache_value: float # Used to store speed value inbetween temporary changes
var target_groups_counter: Dictionary
var in_view: Dictionary # A Dictionary[StringName, Integer] of actors that are currently in view of this actor. The value is the total number of actors in the view when entered.
var track_index: int = 0 # Identifies what index in a npc's track array to follow
var discovery: Dictionary = {}
var measures: Dictionary = {
	"distance_to_target": _built_in_measure__distance_to_target,
	"distance_to_destination": _built_in_measure__distance_to_destination,
	"has_target": _built_in_measure__has_target,
	"speed": _built_in_measure__speed,
	"line_of_sight": _built_in_measure__line_of_sight,
}
var strategy: Strategy
# Without these, the viewshape only moves while the actor is moving.
var last_viewshape_destination: Vector2 
var last_viewshape_origin: Vector2
# Path management for navigation (simplified - NavigationAgent2D handles path internally)

signal on_touch(actor)
signal on_view(actor)
signal line_of_sight_entered(actor)
signal line_of_sight_exited(actor)
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
	var _username: String
	var _password: String
	var this: Actor = Scene.actor.instantiate()
	
	func username(value: String) -> ActorBuilder:
		_username = value
		return self

	func password(value: String) -> ActorBuilder:
		_password = value
		return self
		
	func token(value: PackedByteArray) -> ActorBuilder:
		this.set_token(value)
		return self
	
	func peer_id(value: int) -> ActorBuilder:
		this.peer_id = value
		return self
		
	func display_name(value: String) -> ActorBuilder:
		this.display_name = value
		return self

	func map(value: String) -> ActorBuilder:
		this.map = value
		return self
	
	func view(value: int) -> ActorBuilder:
		this.view = value
		return self
		
	func base(value: int) -> ActorBuilder:
		this.base = value
		return self

	func location(value: Vector2) -> ActorBuilder:
		this.set_location(value)
		return self

	func actor(value: String) -> ActorBuilder:
		this.actor = value
		return self
		
	func resources(value: Dictionary) -> ActorBuilder:
		this.resources = value
		return self
		
	func discovery(value: Dictionary) -> ActorBuilder:
		this.discovery = value
		return self
		
	func speed(value: float) -> ActorBuilder:
		this.speed = value
		return self

	func build() -> Actor:
		var actor_ent = Repo.query([this.actor]).pop_front()
		if actor_ent:
			this.build_viewbox(actor_ent.view)
			this.view = actor_ent.view
			this.base = actor_ent.base
			if actor_ent.groups: this.build_target_groups(actor_ent.groups.lookup())
			if actor_ent.sprite: this.sprite = actor_ent.sprite.key()
			if actor_ent.hitbox: this.hitbox = actor_ent.hitbox.key()
			if actor_ent.on_touch: this.build_on_touch_action(actor_ent.on_touch.key())
			if actor_ent.on_view: this.build_on_view_action(actor_ent.on_view.key())
			for n in range(1, 10):
				var action_name: String = "action_%d" % n
				if actor_ent.get(action_name): this.build_action(actor_ent.get(action_name).key(), n)
			# build resources
			for resource_ent in Repo.query([Group.RESOURCE_ENTITY]):
				this.resources[resource_ent.key()] = this.resources.get(resource_ent.key(), resource_ent.default)
			# build measures
			for measure_ent in Repo.query([Group.MEASURE_ENTITY]):
				this.measure[measure_ent.key()] = this.build_measure(measure_ent)
			if _username and _password:
				this.username = _username
				this.set_token(Secret.encrypt("%s.%s" % [_username, _password]))
			this.set_display_name(this.display_name)
		return this
		
static func builder() -> ActorBuilder:
	return ActorBuilder.new()
	
func pack_discovery() -> Dictionary:
	var results: Dictionary = {}
	for map_layer_node in Finder.query([Group.MAP_LAYER]):
		var map_node: Map = map_layer_node.get_parent()
		if results.get(map_node.get_name()) == null: results[map_node.get_name()] = {}
		results[map_node.get_name()][map_layer_node.get_name()] = map_layer_node.pack_discovered_tiles()
	return results
	
func unpack_discovery() -> void:
	for map_layer_node in Finder.query([Group.MAP_LAYER]): 
		var map_node: Map = map_layer_node.get_parent()
		if discovery.get(map_node.get_name()) == null: continue
		if discovery[map_node.get_name()].get(map_layer_node.get_name()) == null: continue
		map_layer_node.unpack_discovered_tiles(discovery[map_node.get_name()][map_layer_node.get_name()])
	discovery.clear()

func pack() -> Dictionary:
	var results: Dictionary = {
		"token": token,
		"peer_id": peer_id,
		"name": display_name,
		"location/x": position.x,
		"location/y": position.y,
		"actor": actor,
		"map": map,
		"resources": resources,
		"speed": speed,
	}
	if !is_npc():
		results["discovery"] = pack_discovery()
	return results
	
func get_outline_color() -> Color:
	return $Sprite.material.get_shader_parameter("color")

func set_outline_color(value: Color) -> void:
	$Sprite.material.set_shader_parameter("color", value)
	
func is_primary() -> bool:
	return peer_id > 0 and is_multiplayer_authority() and multiplayer.get_unique_id() == peer_id
	
func add_sound_as_child_node(sound_ent: Entity, state_key: String) -> void:
	if sound_ent == null: return
	var audio: AudioStreamFader2D = AudioStreamFader2D.new()
	Optional.of_nullable(sound_ent.scale).if_present(func(scale): audio.set_scale_expression(scale))
	audio.name = state_key
	audio.add_to_group(sound_ent.key())
	audio.add_to_group(name) # Add to this actor's group
	audio.add_to_group(Group.AUDIO)
	var stream: AudioStream = AssetLoader.builder()\
								.key(sound_ent.source)\
								.type(AssetLoader.derive_type_from_path(sound_ent.source).get_value())\
								.archive(Cache.campaign)\
								.loop(sound_ent.loop)\
								.build()\
								.pull()
	audio.set_stream(stream)
	add_child(audio)

func build_audio() -> void:
	Finder.query([Group.AUDIO, name]).map(func(audio): audio.queue_free())
	Optional.of_nullable(Repo.select(actor))\
		.map(func(actor_ent): return actor_ent.sprite)\
		.map(func(sprite_key): return sprite_key.lookup())\
		.map(func(sprite_ent): return sprite_ent.animation)\
		.map(func(animation_key): return animation_key.lookup())\
		.if_present(
			func(animation_ent):
				for state_name in KeyFrames.list():
					Optional.of_nullable(animation_ent.get(state_name))\
					.map(func(key_frame_key): return key_frame_key.lookup())\
					.map(func(key_frame_ent): return key_frame_ent.sound)\
					.map(func(sound_key): return sound_key.lookup()
				).if_present(func(sound_ent): add_sound_as_child_node(sound_ent, state_name)))

func promote_substate() -> void:
	if is_multiplayer_authority() or (is_npc() and (Cache.network == Network.Mode.SERVER or Cache.network == Network.Mode.HOST)):
		substate = clamp(SubState.IDLE, SubState.END, substate + 1)
		
func set_substate(value: SubState) -> void:
	if is_multiplayer_authority() or (is_npc() and (Cache.network == Network.Mode.SERVER or Cache.network == Network.Mode.HOST)):
		substate = value

func _enter_tree():
	set_name(str(peer_id) if peer_id > 0 else str(-randi_range(1, 9_999_999)))
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

func save() -> void:
	var auth = Secret.Auth.builder().token(token).build()
	var data = pack()
	if !OS.has_feature("trial"): 
		io.save_json(auth.get_path(), data)

func save_and_exit() -> void:
	if OS.has_feature("trial"): return
	if !std.is_host_or_server(): return
	Queue.enqueue(
		Queue.Item.builder()
			.comment("Saving actor %s to disk" % name)
			.task(save)
			.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
			.comment("Actor exiting tree %s" % name)
			.task(queue_free)
			.build()
	)

func _ready() -> void:
	build_fader()
	is_awake(false)
	visible_to_primary(false)
	Trigger.new().arm("heading").action(func(): heading_change.emit(heading)).deploy(self)
	Trigger.new().arm("base").action(build_base).deploy(self)
	Trigger.new().arm("hitbox").action(build_hitbox).deploy(self)
	Trigger.new().arm("sprite").action(build_sprite).deploy(self)
	Trigger.new().arm("map").action(update_client_visibility).deploy(self)
	Trigger.new().arm("state").action(_on_state_change).deploy(self)
	$Sprite.set_sprite_frames(SpriteFrames.new())
	$HitBox.area_entered.connect(_on_hit_box_body_entered)
	$ViewBox.area_entered.connect(_on_view_box_area_entered)
	
	# Configure NavigationAgent2D for all actors (primary and NPCs)
	var actor_ent: Entity = Repo.select(actor)
	$NavigationAgent.radius = actor_ent.base
	
	if is_primary():
		$NavigationAgent.debug_enabled = true
		$NavigationAgent.debug_use_custom = true
		build_discoverybox(view)
		$DiscoveryBox.body_entered.connect(_on_discovery_box_body_entered)
		line_of_sight_entered.connect(_on_line_of_sight_entered)
		line_of_sight_exited.connect(_on_line_of_sight_exited)
		$ViewBox.area_exited.connect(_on_view_box_area_exited)
		fader.fade()
		set_camera_target()
		Transition.appear()
		build_target_groups_counter()
		is_awake(true)
		visible_to_primary(true)
		schedule_render_this_actors_map()
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Set actor to awake %s" % name)
			.task(func(): Finder.query([Group.ACTOR, map]).map(func(a): a.is_awake(true)))
			.build()
		)
		Queue.enqueue(
			Queue.Item.builder()
			.comment("unpack discovery")
			.task(unpack_discovery)
			.build()
		)

func schedule_render_this_actors_map() -> void:
	Queue.enqueue(
		Queue.Item.builder()
			.comment("schedule render actors called by %s" % name)
			.task(func(): Controller.render_map(map))
			.condition(func(): return get_tree().get_first_node_in_group(str(multiplayer.get_unique_id())) != null)
			.build()
		)

func is_awake(effect: bool) -> void:
	# TODO -- This could be renamed to make more sense
	use_collisions(effect)
	
func update_client_visibility() -> void:
	Optional.of_nullable(Finder.get_primary_actor()).map(func(primary_actor: Actor): return primary_actor.get("map")).if_present(func(primary_map: String): is_awake(primary_map == map))

func _physics_process(delta) -> void:
	use_state()
	use_animation()
	use_strategy()
	use_move_view(delta)
	if is_primary():
		use_move_discovery()
		use_pathing(delta)
		click_to_move()
		use_move_directly(delta)
		use_actions()
		use_target()
		use_line_of_sight()
	if is_npc() and std.is_host_or_server():
		use_pathing(delta)
		
func _built_in_measure__line_of_sight() -> int:
	var target_actor: Actor = Finder.select(target)
	if target_actor != null:
		if is_primary():
			# Primary players use actual line-of-sight checking
			if line_of_sight_to_point(target_actor.get_position()):
				return 1
		else:
			# NPCs only use viewbox detection (if target is in view, they can "see" it)
			if target_actor.get_name() in in_view:
				return 1
	return 0

func _built_in_measure__distance_to_target() -> int:
	var target_actor: Actor = Finder.select(target)
	if target_actor != null:
		return isometric_distance_to_actor(target_actor)
	return -1
	
func _built_in_measure__distance_to_destination() -> int:
	return isometric_distance_to_point(destination) * BASE_TILE_SIZE
	
func _built_in_measure__has_target() -> int:
	if target != "":
		return 1
	return 0
	
func _built_in_measure__speed() -> float:
	return speed
	
func resolve_target() -> Actor:
	var target_set: Array = Finder.query([map, target])
	if target_set.size() > 0:
		return target_set.pop_at(0)
	set_target("")  # Clear target if it no longer exists
	return null
	
func use_track(track: Array) -> void:
	var track_vectors: Array = []
	for vertex_key in track:
		var track_vector_ent: Entity = Repo.query([Group.VERTEX_ENTITY, vertex_key]).pop_front()
		var vector: Vector2 = std.vec2_from([track_vector_ent.x, track_vector_ent.y])
		track_vectors.append(vector)
	if track_vectors.size() == 0: 
		return
	var next: Vector2 = track_vectors[track_index % track_vectors.size()]
	set_destination(next)
	if isometric_distance_to_point(destination) < DESTINATION_PRECISION:
		track_index += 1
		
func use_move_discovery() -> void:
	var view_shape: CollisionShape2D = $ViewBox.get_node_or_null("ViewShape")
	if view_shape:
		var discovery_shape: CollisionShape2D = $DiscoveryBox.get_node_or_null("DiscoveryShape")
		if discovery_shape:
			discovery_shape.position = view_shape.position



func use_move_view(delta: float) -> void:
	var view_shape: CollisionShape2D = $ViewBox.get_node_or_null("ViewShape")
	if origin.distance_to(destination) > 0: 
		last_viewshape_destination = destination
		last_viewshape_origin = origin
	if view_shape:
		var direction: Vector2 = last_viewshape_destination.direction_to(last_viewshape_origin) 
		var offset_distance: float = view * VIEW_SPEED
		var viewpoint: Vector2 = -direction * offset_distance
		viewpoint.y *= std.isometric_factor(origin.angle_to(destination)) / 2
		var viewshape_distance_to_viewpoint: float = view_shape.position.distance_to(viewpoint)
		var acceleration: float = viewshape_distance_to_viewpoint * delta * VIEW_SPEED
		view_shape.position.x = move_toward(view_shape.position.x, viewpoint.x, acceleration)
		view_shape.position.y = move_toward(view_shape.position.y, viewpoint.y, acceleration)

func use_strategy() -> void:
	if strategy == null: return
	if std.is_host_or_server():
		strategy.use(
			ActorInteraction.builder()
			.caller(self)
			.target(resolve_target())
			.build())

func use_actions() -> void:
	if Input.is_action_just_released("action_1"):
		set_state(KeyFrames.ACTION_1)
		emit_signal("action_1", resolve_target())
	if Input.is_action_just_released("action_2"):
		set_state(KeyFrames.ACTION_2)
		emit_signal("action_2", resolve_target())
	if Input.is_action_just_released("action_3"):
		set_state(KeyFrames.ACTION_3)
		emit_signal("action_3", resolve_target())
	if Input.is_action_just_released("action_4"):
		set_state(KeyFrames.ACTION_4)
		emit_signal("action_4", resolve_target())
	if Input.is_action_just_released("action_5"):
		set_state(KeyFrames.ACTION_5)
		emit_signal("action_5", resolve_target())
	if Input.is_action_just_released("action_6"):
		set_state(KeyFrames.ACTION_6)
		emit_signal("action_6", resolve_target())
	if Input.is_action_just_released("action_7"):
		set_state(KeyFrames.ACTION_7)
		emit_signal("action_7", resolve_target())
	if Input.is_action_just_released("action_8"):
		set_state(KeyFrames.ACTION_8)
		emit_signal("action_8", resolve_target())
	if Input.is_action_just_released("action_9"):
		set_state(KeyFrames.ACTION_9)
		emit_signal("action_9", resolve_target())

func use_target() -> void:
	if Input.is_action_just_pressed("increment_target"):
		set_target(find_next_target())
	if Input.is_action_just_pressed("decrement_target"):
		set_target(find_prev_target())
	if Input.is_action_just_pressed("clear_target"):
		set_target("")
		target_queue.clear()
	if Input.is_action_just_pressed("increment_target_group"):
		target_group_index = increment_target_group()
	if Input.is_action_just_pressed("decrement_target_group"):
		target_group_index = decrement_target_group()

func _handle_target_is_no_longer_targeted(old_target_name: String) -> void:
	if is_primary():
		Optional.of_nullable(Finder.get_actor(old_target_name)).if_present(
			func(old_actor):
				old_actor.set_outline_color(Palette.OUTLINE_CLEAR)
				old_actor.get_node("Label").visible = false
		)
	
func _handle_new_target(new_target_name: String) -> void:
	if is_primary():
		Optional.of_nullable(Finder.get_actor(new_target_name)).if_present(
			func(new_actor):
				new_actor.set_outline_color(Palette.OUTLINE_SELECT)
				new_actor.get_node("Label").visible = true
		)
	
func get_target() -> String:
	return target
		
func set_target(value: String) -> void:
	_handle_target_is_no_longer_targeted(target)
	target = value
	_handle_new_target(value)	

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
	var actors = Finder.query([map, Group.IS_VISIBLE, get_target_group()])
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
	var actors = Finder.query([map, Group.IS_VISIBLE, get_target_group()])
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
	
func line_of_sight_to_point(point: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query: LineOfSightQueryParameters = LineOfSightQueryParameters.builder()\
	.from(position)\
	.to(point)\
	.build()
	var result: Dictionary = space_state.intersect_ray(query)
	return result.is_empty()

func click_to_move() -> void:
	if Input.is_action_pressed("interact"):
		set_destination(get_global_mouse_position())

func despawn() -> void:
	set_process(false)
	set_physics_process(false)
	queue_free()

func move(coordinates: Vector2) -> void:
	set_position(coordinates)
	origin = coordinates
	destination = coordinates 
	
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
	on_touch.connect(func(target_actor): _local_passive_action_handler(target_actor, func(target_actor): Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, value, name, target_actor.name)))


func build_on_view_action(value: String) -> void:
	var action_ent = Repo.select(value)
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	on_view.connect(func(target_actor): _local_passive_action_handler(target_actor, func(target_actor): Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, value, name, target_actor.name)))


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
		action_ent))

func build_measure(value: String) -> Callable:
	return Optional.of(Repo.select(value))\
		.map(func(e): return func(interaction: ActorInteraction): _local_measure_handler(interaction.get_caller().get_name(), interaction.get_target().get_name(), e.expression))\
		.get_value()
		
func build_strategy() -> void:
	if std.is_host_or_server():
		Optional.of(Repo.select(actor))\
			.map(func(e): return e.strategy)\
			.map(func(e): return e.lookup())\
			.if_present(set_strategy)
			
func interrupt_strategy() -> void:
	strategy.stop()
	strategy = null
	set_destination(position)
	set_origin(position)
	set_target("")

func set_strategy(value: Entity) -> void:
	var behaviors: Array[Behavior] = []
	for behavior_ent in value.behaviors.lookup():
		behaviors.append(
			Behavior.builder().goals(behavior_ent.goals.keys())
				.action(
					func(interaction): 
						_local_action_handler(interaction.target, func(t): 
							Finder.select(Group.ACTIONS)\
							.invoke_action\
							.rpc_id(1, behavior_ent.action.key(), name, Optional.of_nullable(t)\
							.map(func(t): 
								return t.get_name())\
								.or_else("")), behavior_ent.action\
								.lookup()))
						.build()
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
							func(_target_actor):
								Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, trigger_ent.action.key(), name, name),
								trigger_ent.action.lookup()
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
										Optional.of_nullable(resolve_target()).or_else(self), 
										func(target_actor): get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, timer_ent.action.key(), name, target_actor.name),
										timer_ent.action.lookup())
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

func _local_passive_action_handler(target: Actor, function: Callable) -> void:
	# Passive becuase this will not "snap" the caller to the attention of it's target
	# Because only one client should allow the trigger, this acts as a filter
	if target.is_primary(): 
		function.call(target)
		
func _local_action_handler(target_actor: Actor, function: Callable, action_ent: Entity) -> void:
	match substate:
		SubState.IDLE, SubState.START:  # Cooldowns mechanic
			function.call(target_actor)
			look_at_target()
			root(action_ent.time)
			get_tree().create_timer(action_ent.time).timeout.connect(func(): set_substate(SubState.END))

func _local_primary_handler(target_actor: Actor, function: Callable) -> void:
	# Because only one client should allow the trigger, this acts as a filter
	if target_actor.is_primary(): 
		Logger.info("%s primary activated by %s" % [name, target_actor.name])
		function.call(target_actor)

func build_viewbox(value: int) -> void:
	if value > 0:
		for node in $ViewBox.get_children(): node.queue_free()
		var view_shape: CollisionShape2D = CollisionShape2D.new()
		view_shape.name = "ViewShape"
		view_shape.shape = CircleShape2D.new()
		view_shape.apply_scale(Vector2(1 * value, 0.5 * value))
		$ViewBox.add_child(view_shape)
		
		
func build_discoverybox(value: int) -> void:
	for node in $DiscoveryBox.get_children(): node.queue_free()
	var discovery_shape: CollisionShape2D = CollisionShape2D.new()
	discovery_shape.name = "DiscoveryShape"
	discovery_shape.shape = CircleShape2D.new()
	discovery_shape.apply_scale(Vector2(1 * value, 0.5 * value))
	$DiscoveryBox.add_child(discovery_shape)
	
func get_relative_camera_position() -> Vector2:
	var view_shape: CollisionShape2D = $ViewBox.get_node_or_null("ViewShape")
	if view_shape:
		return global_position + view_shape.position
	return global_position

func set_camera_target():
	Finder.select(Group.CAMERA).set_target(self)

func build_base() -> void:
	if base <= 0: return
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = base
	collision_shape.set_shape(circle_shape)
	collision_shape.scale = Vector2(1.0, 0.5)
	var base_name: String = "BaseShape"
	var existing_base = get_node_or_null(base_name)
	if existing_base != null:
		existing_base.queue_free()
		remove_child(existing_base)
	collision_shape.set_name(base_name)
	add_child(collision_shape)
	
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

func set_speed(value: float) -> void:
	speed = value
	
func set_token(value: PackedByteArray) -> void:
	token = value

func root(time: float) -> void:
	for dict in $ActionTimer.timeout.get_connections():
		$ActionTimer.timeout.disconnect(dict.callable)
	if time <= 0.0: return
	speed_cache_value = speed
	set_speed(0)
	$ActionTimer.wait_time = time
	$ActionTimer.timeout.connect(unroot)
	$ActionTimer.start()

func unroot() -> void:
	$ActionTimer.stop()
	set_speed(speed_cache_value)
	speed_cache_value = 0

func set_sprite(value: String) -> void:
	sprite = value
	
func build_frame(index: int, size: Vector2i, source: String) -> AtlasTexture:
	var external_texture: Texture
	var texture: AtlasTexture
	if Cache.textures.has(source):
		external_texture = Cache.textures[source]
	else:
		Cache.textures[source] = AssetLoader.builder()\
		.archive(Cache.campaign)\
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
		modulate.a = 0.0
		add_to_group(Group.IS_VISIBLE)
	else:
		modulate.a = 1.0
		remove_from_group(Group.IS_VISIBLE)
	visible = effect
	
func handle_resource_change(resource: String) -> void:
	pass
	
func handle_target() -> void:
	Optional.of_nullable(Finder.get_actor(target))\
	.if_present(
		func(target_actor): 
			target_actor.set_outline_color(Palette.OUTLINE_SELECT)
			$Label.visible = true
	)
	
func build_fader() -> void:
	Fader.builder().target(self).build().deploy(self)
	fader = get_node("Fader")
	
func move_label() -> void:
	$Label.position.y = -((get_sprite_size().y - get_sprite_margin().y))

func build_sprite() -> void:
	var sprite_ent = Repo.select(sprite)
	if !sprite_ent: return
	if !Cache.textures.has(sprite_ent.texture):
		Cache.textures[sprite_ent.texture] = AssetLoader.builder()\
		.archive(Cache.campaign)\
		.type(AssetLoader.Type.IMAGE)\
		.key(sprite_ent.texture)\
		.build()\
		.pull()
	var texture = Cache.textures.get(sprite_ent.texture)
	var sprite_frames: SpriteFrames = SpriteFrames.new()
	var animation_ent = sprite_ent.animation.lookup()
	sprite_frames.remove_animation("default") # default has no meaning in isometric space
	for key_frame_name in KeyFrames.list():
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
		move_label()
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Build audio tracks for actor %s" % name)
			.task(build_audio)
			.build()
		)
		
func get_resource(resource_name: String) -> int:
	## Returns -1 if resource does not exist
	return resources.get(resource_name, -1)
	
func get_measure(measure_name: String) -> int:
	## Returns -1 if measure does not exist
	return Optional.of_nullable(measures.get(measure_name)).map(func(measure): return measure.call()).or_else(-1)
		
func map_relative_distance_to_in_view_actors() -> Dictionary:
	var results: Dictionary = {}
	for actor_name in in_view.keys():
		var per_actor: Actor
		if is_primary():
			# Primary players only consider visible actors
			per_actor = Finder.query([map, Group.IS_VISIBLE, actor_name]).pop_front()
		else:
			# NPCs consider any actor in their view (no visibility requirement)
			per_actor = Finder.query([map, actor_name]).pop_front()
		if per_actor != null:
			results[actor_name] = isometric_distance_to_actor(per_actor)
	return results
	
func map_resource_of_in_view_actors(resource_name: String) -> Dictionary:
	var results: Dictionary = {}
	for actor_name in in_view.keys():
		results[actor_name] = Finder.get_actor(actor_name).get_resource(resource_name)
	return results
	
func map_measure_of_in_view_actors(measure_name: String) -> Dictionary:
	var results: Dictionary = {}
	for actor_name in in_view.keys():
		results[actor_name] = Finder.get_actor(actor_name).get_measure(measure_name)
	return results
		
func find_nearest_actor_in_view() -> Optional:
	var distances = map_relative_distance_to_in_view_actors()
	if distances.is_empty():
		return Optional.of_nullable(null)
	var min_distance = distances.values().min()
	var nearest_actor = distances.keys().filter(func(actor): return distances[actor] == min_distance).front()
	return Optional.of_nullable(Finder.get_actor(nearest_actor))

func find_furthest_actor_in_view() -> Optional:
	var distances = map_relative_distance_to_in_view_actors()
	if distances.is_empty():
		return Optional.of_nullable(null)
	var max_distance = distances.values().max()
	var furthest_actor = distances.keys().filter(func(actor): return distances[actor] == max_distance).front()
	return Optional.of_nullable(Finder.get_actor(furthest_actor))

func find_actor_in_view_with_highest_resource(resource_name: String) -> Optional:
	var actor_resource_map = map_resource_of_in_view_actors(resource_name)
	if actor_resource_map.is_empty():
		return Optional.of_nullable(null)
	var max_resource = actor_resource_map.values().max()
	var actor_with_max_resource = actor_resource_map.keys().filter(func(actor): return actor_resource_map[actor] == max_resource).front()
	return Optional.of_nullable(Finder.get_actor(actor_with_max_resource))

func find_actor_in_view_with_lowest_resource(resource_name: String) -> Optional:
	var actor_resource_map = map_resource_of_in_view_actors(resource_name)
	if actor_resource_map.is_empty():
		return Optional.of_nullable(null)
	var min_resource = actor_resource_map.values().min()
	var actor_with_min_resource = actor_resource_map.keys().filter(func(actor): return actor_resource_map[actor] == min_resource).front()
	return Optional.of_nullable(Finder.get_actor(actor_with_min_resource))
	
func find_actor_in_view_with_highest_measure(measure_name: String) -> Optional:
	var actor_measure_map = map_measure_of_in_view_actors(measure_name)
	if actor_measure_map.is_empty():
		return Optional.of_nullable(null)
	var max_measure = actor_measure_map.values().max()
	var actor_with_max_measure = actor_measure_map.keys().filter(func(actor): return actor_measure_map[actor] == max_measure).front()
	return Optional.of_nullable(Finder.get_actor(actor_with_max_measure))

func find_actor_in_view_with_lowest_measure(measure_name: String) -> Optional:
	var actor_measure_map = map_resource_of_in_view_actors(measure_name)
	if actor_measure_map.is_empty():
		return Optional.of_nullable(null)
	var min_measure = actor_measure_map.values().min()
	var actor_with_min_measure = actor_measure_map.keys().filter(func(actor): return actor_measure_map[actor] == min_measure).front()
	return Optional.of_nullable(Finder.get_actor(actor_with_min_measure))

func find_random_actor_in_view() -> Optional:
	if in_view.is_empty():
		return Optional.of_nullable(null)
	var random_actor_name = in_view.keys().pick_random()
	return Optional.of_nullable(Finder.get_actor(random_actor_name))

func setup_sprite(sprite_frames: SpriteFrames) -> void:
		## Setting up a sprite sheet dynamically is a touchy thing. It must be started in this order.
		$Sprite.offset = _calculate_sprite_offset()
		$Sprite.set_sprite_frames(sprite_frames)
		set_outline_color(Color(0, 0, 0, 0))
		$Label.visible = false

func _calculate_sprite_offset() -> Vector2i:
	var full_size: Vector2i = get_sprite_size()
	var margin: Vector2i = get_sprite_margin()
	var actual_size: Vector2i = full_size - margin
	var result: Vector2i = -actual_size
	result.x += ((full_size.x / 2) - (margin.x))
	return result
	
var _use_line_of_sight_tick: int = 0
func use_line_of_sight() -> void:
	if in_view.size() == 0: return
	var actor_name_per_tick: String = in_view.keys()[_use_line_of_sight_tick % in_view.size()]
	var other: Actor = Finder.select(actor_name_per_tick)
	if line_of_sight_to_point(other.get_position()):
		if !other.is_in_group(Group.LINE_OF_SIGHT):
			other.add_to_group(Group.LINE_OF_SIGHT)
			line_of_sight_entered.emit(other)
	else:
		if other.is_in_group(Group.LINE_OF_SIGHT):
			other.remove_from_group(Group.LINE_OF_SIGHT)
			line_of_sight_exited.emit(other)
	_use_line_of_sight_tick += 1

func use_pathing(delta: float) -> void:
	# Set navigation target every frame when position != destination
	if not position.is_equal_approx(destination):
		$NavigationAgent.target_position = destination
	# Check if navigation is finished (reached destination)
	if $NavigationAgent.is_navigation_finished():
		set_destination(position)
		velocity = Vector2.ZERO
		return
	
	# Get next navigation position and move toward it
	var next_position = $NavigationAgent.get_next_path_position()
	fix = next_position  # Update fix to current navigation target
	var motion = position.direction_to(next_position)
	velocity = motion * get_speed(delta) * std.isometric_factor(motion.angle())
	move_and_slide()
	
	match substate:
		SubState.IDLE, SubState.START, SubState.END:
			look_at_point(next_position)

func look_at_target() -> void:
	Optional.of_nullable(Finder.get_actor(target)).if_present(func(target_actor): look_at_point(target_actor.position))

func look_at_point(point: Vector2) -> void:
	set_heading(map_radial(point.angle_to_point(position)))
	
func map_radial(radians: float) -> String:
	return std.RADIALS.keys()[snap_radial(radians)]
	
func snap_radial(radians: float) -> int:
	return wrapi(snapped(radians, PI/4) / (PI/4), 0, 8)
	
func get_speed(delta: float) -> float:
	return BASE_ACTOR_SPEED * delta * speed * SPEED_NORMAL
	
func use_move_directly(_delta) -> void:
	var motion = Input.get_vector("left", "right", "up", "down")
	if motion.length():
		var new_destination: Vector2 = position + motion * DESTINATION_PRECISION * 10  # 10 is as low as this will go and still register movement
		#if is_point_on_navigation_region(new_destination):
		set_destination(new_destination)
		$NavigationAgent.target_position = new_destination


func is_point_on_navigation_region(point: Vector2) -> bool:
	var map = get_world_2d().navigation_map
	var closest_point = NavigationServer2D.map_get_closest_point(map, point)
	var distance = point.distance_to(closest_point)
	return distance < DESTINATION_PRECISION * 2

func set_destination(point: Vector2) -> void:
	## Where the actor is headed to.
	set_origin(position)
	destination = point
	fix = point  # Set fix to destination, will be updated by NavigationAgent2D in use_pathing()
	
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

func set_remote_transform_target(node: Node) -> void:
	$RemoteTransform2D.remote_path = node.get_path()
	
func clear_remote_transform_target() -> void:
	$RemoteTransform2D.remote_path = null

func set_state(value: String) -> void:
	state = value
	
func set_animation_speed(value: float) -> void:
	$Sprite.speed_scale = value
	
func use_state() -> void:
	match substate:
		SubState.IDLE:
			pass
		SubState.START:
			Optional.of_nullable(get_node_or_null(state)).if_present(
				func(audio_fader): 
					audio_fader.play()
					promote_substate()
			)
		SubState.USE:
			if $ActionTimer.is_stopped():
				promote_substate()
		SubState.END:
			set_state(KeyFrames.IDLE)
			set_animation_speed(1.0)
			set_substate(SubState.IDLE)

	match state:
		KeyFrames.IDLE:
			if !position.is_equal_approx(destination):
				set_animation_speed(std.isometric_factor(velocity.angle()))
				if speed > 0.33:
					set_state(KeyFrames.RUN)
				else:
					set_state(KeyFrames.WALK)
		KeyFrames.WALK:
			if position.is_equal_approx(destination):
				set_state(KeyFrames.IDLE)
		KeyFrames.RUN: 
			if position.is_equal_approx(destination):
				set_state(KeyFrames.IDLE)
				
func set_display_name(new_display_name: String) -> void:
	$Label.set_text(display_name)

func _on_heading_change(_radial):
	pass

func _on_state_change() -> void:
	set_substate(SubState.START)

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
	$DiscoveryBox.set_collision_layer_value(Layer.DISCOVERY, effect)
	$DiscoveryBox.set_collision_mask_value(Layer.DISCOVERY, effect)
	
func _on_sprite_animation_changed():
	$Sprite.play()  # Without this, the animation freezes
	
func _on_line_of_sight_entered(other: Actor) -> void:
	other.fader.fade()
	other.visible_to_primary(true)
	
func _on_line_of_sight_exited(other: Actor) -> void:
	other.fader.fade()
	other.visible_to_primary(false)

func _on_view_box_area_entered(area: Area2D) -> void:
	var other = area.get_parent()
	if other == self: return
	in_view[other.get_name()] = in_view.size()
	if is_primary():
		other.fader.fade()
		other.visible_to_primary(true)
		for target_group_key in other.target_groups:
			target_groups_counter[target_group_key] = target_groups_counter[target_group_key] + 1
	self.on_view.emit(other)

func _on_view_box_area_exited(area: Area2D) -> void:
	var other = area.get_parent()
	if other == self: return
	in_view.erase(other.get_name())
	var other_name: String = other.get_name()
	var this_actor_name: String = get_name()
	other.remove_from_group(Group.LINE_OF_SIGHT)
	other.fader.at_next_appear(
		func(): 
			Optional.of_nullable(Finder.get_actor(other_name))\
			.if_present(
				func(other_actor):
					for target_group_key in other.target_groups:
						Optional.of_nullable(Finder.get_actor(this_actor_name))\
						.if_present(
							func(this_actor):
								this_actor.target_groups_counter[target_group_key] = this_actor.target_groups_counter[target_group_key] - 1
								if other_actor.name == this_actor.get_target(): this_actor.set_target("")
						)
					other_actor.visible_to_primary(false)
					)
			)
	other.fader.appear()

func is_npc() -> bool:
	return is_in_group(Group.NPC)
	
func _notification(what):
	# It is important to save on this hook because it will also save on OS notifications. i.e. alt-F4
	if what == NOTIFICATION_WM_CLOSE_REQUEST and std.is_host_or_server() and !token.is_empty() and !is_npc():
		save()

func _on_tree_exiting() -> void:
	Controller.broadcast_actor_is_despawning.rpc_id(1, peer_id, map)

func _on_discovery_box_body_entered(tileMapLayer: FadingTileMapLayer) -> void:
	if tileMapLayer is FadingTileMapLayer:
		tileMapLayer.set_discovery_source(self)
