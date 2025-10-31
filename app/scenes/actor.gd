extends CharacterBody2D
class_name Actor

# Action signals for skills
signal action_1_start(target_actor: Actor)
signal action_1_end(target_actor: Actor)
signal action_2_start(target_actor: Actor)
signal action_2_end(target_actor: Actor)
signal action_3_start(target_actor: Actor)
signal action_3_end(target_actor: Actor)
signal action_4_start(target_actor: Actor)
signal action_4_end(target_actor: Actor)
signal action_5_start(target_actor: Actor)
signal action_5_end(target_actor: Actor)
signal action_6_start(target_actor: Actor)
signal action_6_end(target_actor: Actor)
signal action_7_start(target_actor: Actor)
signal action_7_end(target_actor: Actor)
signal action_8_start(target_actor: Actor)
signal action_8_end(target_actor: Actor)
signal action_9_start(target_actor: Actor)
signal action_9_end(target_actor: Actor)

enum SubState {
	IDLE,
	START,
	USE,
	END
}

const BASE_TILE_SIZE: float = 32.0
const BASE_ACTOR_SPEED: float = 10.0
const SPEED_NORMAL: float = 500.0
const DESTINATION_PRECISION: float = 8.0  # Increased for better isometric handling
const VIEW_SPEED: float = 4

# Navigation constants - improved for isometric movement
const NAV_AGENT_RADIUS: float = 12.0  # Slightly smaller than tile for smooth movement
const NAV_NEIGHBOR_DISTANCE: float = 48.0  # Increased for better pathfinding
const NAV_PATH_DESIRED_DISTANCE: float = 4.0  # Smaller for more precise following
const NAV_TARGET_DESIRED_DISTANCE: float = 6.0  # Separate from DESTINATION_PRECISION
const NAV_PATH_MAX_DISTANCE: float = 64.0  # Increased recalculation distance

@export var token: PackedByteArray
@export var display_name: String
@export var origin: Vector2
@export var destination: Vector2
@export var fix: Vector2
@export var speed: float = 1.0
@export var heading: String = "S"
@export var state: String = "idle"
@export var substate: SubState 
@export var sprite: String = ""
@export var base: int = 0
@export var actor: String = ""
@export var hitbox: String = ""
@export var map: String = ""
@export var target: String = ""
@export var resources: Dictionary = {}

var fader: Fader
var peer_id: int = 0
var perception: int = -1
var salience: int = -1
var target_queue: Array = []
var target_group: String = ""
var target_group_index: int = 0
var group_outline_color: Color = Color.WHITE  # Stores RGB from group, alpha modified for states
var speed_cache_value: float # Used to store speed value inbetween temporary changes
var in_view: Dictionary # A Dictionary[StringName, Integer] of actors that are currently in view of this actor. The value is the total number of actors in the view when entered.
var visible_groups: Dictionary = {} # A Dictionary[String, Integer] tracking count of visible actors per group
var track_index: int = 0 # Identifies what index in a npc's track array to follow
var discovery: Dictionary = {}
var discovered_waypoints: Array[String] = [] # Array of waypoint keys that have been discovered by this actor
# Focus slot storage - 4 corner saved targets
var focus_top_left: String = ""
var focus_top_right: String = ""
var focus_bot_left: String = ""
var focus_bot_right: String = ""
# Navigation loop protection
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var path_recalculation_attempts: int = 0
const MAX_STUCK_TIME: float = 3.0
const MAX_PATH_ATTEMPTS: int = 10
# Movement mode tracking
var is_direct_movement_active: bool = false
var current_input_strength: float = 0.0
# Area targeting mode tracking
var is_area_targeting: bool = false
var area_targeting_action: String = ""
var area_targeting_overlay: Node2D = null
var area_targeting_start_pos: Vector2 = Vector2.ZERO
var measures: Dictionary = {
	"distance_to_target": _built_in_measure__distance_to_target,
	"distance_to_destination": _built_in_measure__distance_to_destination,
	"has_target": _built_in_measure__has_target,
	"speed": _built_in_measure__speed,
	"perception": _built_in_measure__perception,
	"salience": _built_in_measure__salience,
	"line_of_sight": _built_in_measure__line_of_sight,
}
var strategy: Strategy
# Without these, the viewshape only moves while the actor is moving.
var last_viewshape_destination: Vector2 
var last_viewshape_origin: Vector2
# Path management for navigation (simplified - NavigationAgent2D handles path internally)

signal on_touch(actor)
signal on_view(actor)
signal on_map_entered()
signal on_map_exited()
signal line_of_sight_entered(actor)
signal line_of_sight_exited(actor)
# Dynamic skill signals will be created at runtime
var skill_signals: Dictionary = {}

signal heading_change(heading)
signal visible_groups_changed(visible_groups: Dictionary)
signal target_group_changed(group_key: String)

class ActorBuilder extends Object:
	var _username: String
	var _password: String
	var _group_outline_color: Color = Color.WHITE
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
	
	func perception(value: int) -> ActorBuilder:
		this.perception = value
		return self

	func salience(value: int) -> ActorBuilder:
		this.salience = value
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

	func discovered_waypoints(value: Array) -> ActorBuilder:
		this.discovered_waypoints = value if value else []
		return self

	func speed(value: float) -> ActorBuilder:
		this.speed = value
		return self

	func build() -> Actor:
		var actor_ent = Repo.query([this.actor]).pop_front()
		if actor_ent:
			if this.perception == -1:
				this.perception = actor_ent.perception
			this.build_viewbox(this.perception)
			if this.salience == -1:
				this.salience = actor_ent.salience
			this.build_saliencebox(this.salience)
			this.base = actor_ent.base
			if actor_ent.group:
				this.target_group = actor_ent.group.key()
				this.add_to_group(this.target_group)
				# Store outline color from group to apply after sprite setup
				var group_ent = actor_ent.group.lookup()
				if group_ent and group_ent.color:
					_group_outline_color = this.parse_hex_color(group_ent.color)
			if actor_ent.sprite: this.sprite = actor_ent.sprite.key()
			if actor_ent.hitbox: this.hitbox = actor_ent.hitbox.key()
			if actor_ent.on_touch: this.build_on_touch_action(actor_ent.on_touch.key())
			if actor_ent.on_view: this.build_on_view_action(actor_ent.on_view.key())
			if actor_ent.on_map_entered: this.build_on_map_entered_action(actor_ent.on_map_entered.key())
			if actor_ent.on_map_exited: this.build_on_map_exited_action(actor_ent.on_map_exited.key())
			if actor_ent.skills:
				var skills_list = actor_ent.skills.lookup()
				if skills_list:
					var max_skills = min(skills_list.size(), 9)  # Limit to 9 skills
					for i in range(max_skills):
						var skill_ent = skills_list[i]
						if skill_ent:
							this.build_skill(skill_ent, i + 1)
			# build resources
			for resource_ent in Repo.query([Group.RESOURCE_ENTITY]):
				this.resources[resource_ent.key()] = this.resources.get(resource_ent.key(), resource_ent.default)
			# build measures
			for measure_ent in Repo.query([Group.MEASURE_ENTITY]):
				this.measure[measure_ent.key()] = this.build_measure(measure_ent)
			if _username and _password:
				this.username = _username
				this.set_token(Secret.encrypt("%s.%s" % [_username, _password]))
			this.set_speed(this.speed)  # Copy builder speed to actor instance
			this.group_outline_color = _group_outline_color  # Transfer group color to instance
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
		"perception": perception,
		"salience": salience,
	}
	if !is_npc():
		results["discovery"] = pack_discovery()
		results["discovered_waypoints"] = discovered_waypoints
	return results
	
func get_outline_color() -> Color:
	return $Sprite.material.get_shader_parameter("color")

func set_outline_color(value: Color) -> void:
	$Sprite.material.set_shader_parameter("color", value)

func set_outline_opacity(opacity: float) -> void:
	var current_color = get_outline_color()
	current_color.a = opacity
	set_outline_color(current_color)

func get_outline_opacity() -> float:
	return get_outline_color().a

func parse_hex_color(hex_string: String) -> Color:
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
	
func is_primary() -> bool:
	return peer_id > 0 and is_multiplayer_authority() and multiplayer.get_unique_id() == peer_id
	
func add_sound_as_child_node(sound_ent: Entity, state_key: String) -> void:
	if sound_ent == null: return
	var audio: AudioStreamFader2D = AudioStreamFader2D.new()
	Optional.of_nullable(sound_ent.scale).if_present(func(scale_value): audio.set_scale_expression(scale_value))
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
				if animation_ent.keyframes:
					var keyframes_list = animation_ent.keyframes.lookup()
					if keyframes_list:
						for keyframe_ref in keyframes_list:
							var keyframe_ent = keyframe_ref
							if keyframe_ent and keyframe_ent.key():
								var state_name = keyframe_ent.key()
								Optional.of_nullable(keyframe_ent.sound)\
								.map(func(sound_key): return sound_key.lookup())\
								.if_present(func(sound_ent): add_sound_as_child_node(sound_ent, state_name)))

func promote_substate() -> void:
	if is_primary() or (is_npc() and (Cache.network == Network.Mode.SERVER or Cache.network == Network.Mode.HOST)):
		substate = clamp(SubState.IDLE, SubState.END, substate + 1)
		
func set_substate(value: SubState) -> void:
	var can_change = is_primary() or (is_npc() and (Cache.network == Network.Mode.SERVER or Cache.network == Network.Mode.HOST))
	if is_primary():
		Logger.debug("set_substate: %s -> %s, can_change=%s, is_auth=%s, peer_id=%s" % [substate, value, can_change, is_multiplayer_authority(), peer_id], self)
	if can_change:
		substate = value
	elif is_primary():
		Logger.debug("set_substate: BLOCKED - cannot change substate!", self)

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
	if OS.has_feature("trial"): return   # The trial version will not save data
	if !std.is_host_or_server(): return
	on_map_exited.emit()
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
	Trigger.new().arm("salience").action(func(): build_saliencebox(salience)).deploy(self)
	Trigger.new().arm("map").action(update_client_visibility).deploy(self)
	Trigger.new().arm("state").action(_on_state_change).deploy(self)
	$Sprite.set_sprite_frames(SpriteFrames.new())
	$HitBox.area_entered.connect(_on_hit_box_body_entered)
	$ViewBox.area_entered.connect(_on_view_box_area_entered)
	
	# Configure NavigationAgent2D for all actors (primary and NPCs)
	var _actor_ent: Entity = Repo.select(actor)
	$NavigationAgent.radius = NAV_AGENT_RADIUS
	$NavigationAgent.neighbor_distance = NAV_NEIGHBOR_DISTANCE
	$NavigationAgent.path_desired_distance = NAV_PATH_DESIRED_DISTANCE
	$NavigationAgent.target_desired_distance = NAV_TARGET_DESIRED_DISTANCE
	$NavigationAgent.path_max_distance = NAV_PATH_MAX_DISTANCE
	var actor_ent: Entity = Repo.select(actor)
	if is_primary():
		visible_groups = {}  # Initialize group tracking for primary actor

		# Add primary actor's own group to visible groups
		if target_group != "" and target_group != Group.DEFAULT_TARGET_GROUP:
			visible_groups[target_group] = 1
			visible_groups_changed.emit(visible_groups)

		if actor_ent and actor_ent.skills:
			var skills_list = actor_ent.skills.lookup()
			if skills_list:
				var max_skills = min(skills_list.size(), 9)  # Limit to 9 for UI compatibility
				for i in range(max_skills):
					var skill_ent = skills_list[i]
					if skill_ent and skill_ent.key():
						var slot_number = i + 1
						Queue.enqueue(
							Queue.Item.builder()
							.comment("Schedule render new skill_%s for actor %s" % [slot_number, name])
							.task(func(): Finder.select(Group.UI_ACTION_BLOCK_N % slot_number).render(skill_ent.key()))
							.build()
						)
		$NavigationAgent.debug_enabled = true
		$NavigationAgent.debug_use_custom = true
		build_discoverybox(perception)
		$DiscoveryBox.body_entered.connect(_on_discovery_box_body_entered)
		line_of_sight_entered.connect(_on_line_of_sight_entered)
		line_of_sight_exited.connect(_on_line_of_sight_exited)
		$ViewBox.area_exited.connect(_on_view_box_area_exited)
		fader.fade()
		set_camera_target()
		Transition.appear()
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
		if std.is_host_or_server():
			Queue.enqueue(
				Queue.Item.builder()
				.comment("emit on_map_entered signal for actor %s" % name)
				.task(func(): on_map_entered.emit())
				.build()
			)
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Sync data plate in ui to primary actor")
			.task(func(): Finder.select(Group.UI_DATA_PLATE).load_actor_data())
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
		if is_area_targeting:
			update_area_targeting(delta)
		else:
			use_pathing(delta)
			click_to_move()
			use_move_directly(delta)
		use_actions()
		use_target()
		#use_line_of_sight() # Temp disabled save incase we need this later
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
	var target_actor: Actor = Finder.get_actor(target)
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

func _built_in_measure__perception() -> int:
	return perception

func _built_in_measure__salience() -> int:
	return salience

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
		var offset_distance: float = perception * VIEW_SPEED
		var viewpoint: Vector2 = -direction * offset_distance
		# Apply isometric factor but clamp it to prevent extreme distortion
		var viewpoint_isometric_factor = std.isometric_factor(origin.angle_to(destination))
		viewpoint_isometric_factor = max(viewpoint_isometric_factor, 0.5)  # Prevent too much Y compression
		viewpoint.y *= viewpoint_isometric_factor / 2
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
	# Block input if UI state machine says player input should be blocked
	# EXCEPT when in area targeting mode, allow input for that
	if get_node("/root/UIStateMachine").should_block_player_input() and !is_area_targeting:
		return

	var actor_ent: Entity = Repo.select(actor)
	if !actor_ent or !actor_ent.skills: return

	# Limit to 9 skills maximum to maintain action_1-9 compatibility
	var skills_list: Array = actor_ent.skills.lookup()
	if !skills_list: return

	var max_skills: int = min(skills_list.size(), 9)

	for i in range(max_skills):
		var skill_ent: Entity = skills_list[i]
		if !skill_ent: continue

		var skill_key: String = skill_ent.key()
		if !skill_key: continue

		var action_name: String = "action_%d" % (i + 1)
		var ui_action_block: String = Group.UI_ACTION_BLOCK_N % (i + 1)

		# Handle skill start (button press)
		if Input.is_action_just_pressed(action_name) and skill_ent.start:
			# Check if this is an area action
			var start_action_ent = skill_ent.start.lookup()
			if start_action_ent and start_action_ent.area:
				# Enter area targeting mode
				enter_area_targeting(skill_ent.start.key(), start_action_ent)
				Finder.select(ui_action_block).press_button()
			else:
				# Normal action
				var start_signal = "action_%d_start" % (i + 1)
				Finder.select(ui_action_block).press_button()
				emit_skill_signal(start_signal, resolve_target())

		# Handle skill end (button release)
		if Input.is_action_just_released(action_name):
			# Check if we're in area targeting mode for this action
			if is_area_targeting and area_targeting_action == (skill_ent.start.key() if skill_ent.start else ""):
				execute_area_action()
				Finder.select(ui_action_block).release_button()
			elif skill_ent.end:
				var end_signal = "action_%d_end" % (i + 1)
				emit_skill_signal(end_signal, resolve_target())
				Finder.select(ui_action_block).release_button()

func emit_skill_signal(skill_event: String, target_actor: Actor) -> void:
	# Emit the appropriate static signal
	match skill_event:
		"action_1_start":
			action_1_start.emit(target_actor)
		"action_1_end":
			action_1_end.emit(target_actor)
		"action_2_start":
			action_2_start.emit(target_actor)
		"action_2_end":
			action_2_end.emit(target_actor)
		"action_3_start":
			action_3_start.emit(target_actor)
		"action_3_end":
			action_3_end.emit(target_actor)
		"action_4_start":
			action_4_start.emit(target_actor)
		"action_4_end":
			action_4_end.emit(target_actor)
		"action_5_start":
			action_5_start.emit(target_actor)
		"action_5_end":
			action_5_end.emit(target_actor)
		"action_6_start":
			action_6_start.emit(target_actor)
		"action_6_end":
			action_6_end.emit(target_actor)
		"action_7_start":
			action_7_start.emit(target_actor)
		"action_7_end":
			action_7_end.emit(target_actor)
		"action_8_start":
			action_8_start.emit(target_actor)
		"action_8_end":
			action_8_end.emit(target_actor)
		"action_9_start":
			action_9_start.emit(target_actor)
		"action_9_end":
			action_9_end.emit(target_actor)

func use_target() -> void:
	# Handle cancel during area targeting mode
	if is_area_targeting and Input.is_action_just_pressed("cancel"):
		cancel_area_targeting()
		return

	# Block input if UI state machine says player input should be blocked
	if get_node("/root/UIStateMachine").should_block_player_input():
		return

	# Handle cancel action for clearing target (only in GAMEPLAY state)
	if Input.is_action_just_pressed("cancel"):
		set_target("")
		target_queue.clear()
		return

	if Input.is_action_just_pressed("increment_target"):
		var next = find_next_target()
		if next != target:  # Only set if different to avoid plate deletion bug
			set_target(next)
	if Input.is_action_just_pressed("decrement_target"):
		var prev = find_prev_target()
		if prev != target:  # Only set if different to avoid plate deletion bug
			set_target(prev)
	if Input.is_action_just_pressed("clear_target"):
		set_target("")
		target_queue.clear()
	if Input.is_action_just_pressed("increment_target_group"):
		target_group_index = increment_target_group()
		target_group_changed.emit(get_target_group())
	if Input.is_action_just_pressed("decrement_target_group"):
		target_group_index = decrement_target_group()
		target_group_changed.emit(get_target_group())
	if Input.is_action_just_pressed("open_selection_menu"):
		if target and target != "":
			Finder.select(Group.INTERFACE).open_selection_menu_for_actor(target)
		else:
			Logger.warn("No target selected, cannot open menu", self)

	# Focus slot handling - top left
	if Input.is_action_just_pressed("clear_focus_top_left"):
		clear_focus_slot("top_left")
	elif Input.is_action_just_pressed("focus_top_left"):
		var stored = get_focus_slot("top_left")
		if stored != "":
			select_focus_from_slot("top_left")
		elif target != "":
			store_focus_in_slot("top_left")

	# Focus slot handling - top right
	if Input.is_action_just_pressed("clear_focus_top_right"):
		clear_focus_slot("top_right")
	elif Input.is_action_just_pressed("focus_top_right"):
		var stored = get_focus_slot("top_right")
		if stored != "":
			select_focus_from_slot("top_right")
		elif target != "":
			store_focus_in_slot("top_right")

	# Focus slot handling - bottom left
	if Input.is_action_just_pressed("clear_focus_bot_left"):
		clear_focus_slot("bot_left")
	elif Input.is_action_just_pressed("focus_bot_left"):
		var stored = get_focus_slot("bot_left")
		if stored != "":
			select_focus_from_slot("bot_left")
		elif target != "":
			store_focus_in_slot("bot_left")

	# Focus slot handling - bottom right
	if Input.is_action_just_pressed("clear_focus_bot_right"):
		clear_focus_slot("bot_right")
	elif Input.is_action_just_pressed("focus_bot_right"):
		var stored = get_focus_slot("bot_right")
		if stored != "":
			select_focus_from_slot("bot_right")
		elif target != "":
			store_focus_in_slot("bot_right")

func _handle_target_is_no_longer_targeted(old_target_name: String) -> void:
	if is_primary():
		Optional.of_nullable(Finder.get_actor(old_target_name)).if_present(
			func(old_actor):
				old_actor.set_outline_opacity(0.0)
		)
		if old_target_name != "":
			Finder.select(Group.UI_TARGET_WIDGET).remove_plate(old_target_name)
	
func _handle_new_target(new_target_name: String) -> void:
	if is_primary():
		Optional.of_nullable(Finder.get_actor(new_target_name)).if_present(
			func(new_actor):
				new_actor.set_outline_opacity(0.666)
		)
		if new_target_name != "":
			var target_widget = Finder.select(Group.UI_TARGET_WIDGET)
			target_widget.set_check_in_view(true)  # Enable in-view checking for target widget
			target_widget.append_plate(new_target_name)

func get_target() -> String:
	return target
		
func set_target(value: String) -> void:
	_handle_target_is_no_longer_targeted(target)
	target = value
	_handle_new_target(value)	

func get_targetable_groups() -> Array:
	var targetable: Array = [Group.DEFAULT_TARGET_GROUP]  # Always include default

	# Add groups that have visible actors
	for group_key in visible_groups.keys():
		if visible_groups[group_key] > 0:
			targetable.append(group_key)

	return targetable

func increment_target_group() -> int:
	return min(target_group_index + 1, max(get_targetable_groups().size() - 1, 0))

func decrement_target_group() -> int:
	return max((target_group_index - 1), 0)
	
func get_target_group_index() -> int:
	return min(target_group_index, get_targetable_groups().size() - 1)
	
func get_target_group() -> String:
	var target_group_index: int = get_target_group_index()
	var targetable_groups: Array = get_targetable_groups()
	if targetable_groups.is_empty(): return ""
	return targetable_groups[target_group_index]

# Focus slot management
func store_focus_in_slot(slot: String) -> void:
	if not is_primary(): return
	if target == "": return  # Can't store empty target

	# Don't overwrite if slot already has a target
	if get_focus_slot(slot) != "": return

	match slot:
		"top_left":
			focus_top_left = target
			Finder.select(Group.UI_FOCUS_WIDGET_TOP_LEFT).append_plate(target)
		"top_right":
			focus_top_right = target
			Finder.select(Group.UI_FOCUS_WIDGET_TOP_RIGHT).append_plate(target)
		"bot_left":
			focus_bot_left = target
			Finder.select(Group.UI_FOCUS_WIDGET_BOT_LEFT).append_plate(target)
		"bot_right":
			focus_bot_right = target
			Finder.select(Group.UI_FOCUS_WIDGET_BOT_RIGHT).append_plate(target)

func select_focus_from_slot(slot: String) -> void:
	if not is_primary(): return

	var stored_target: String = ""
	match slot:
		"top_left":
			stored_target = focus_top_left
		"top_right":
			stored_target = focus_top_right
		"bot_left":
			stored_target = focus_bot_left
		"bot_right":
			stored_target = focus_bot_right

	if stored_target != "":
		# Check if the stored actor still exists and is visible
		var stored_actor = Finder.query([map, Group.IS_VISIBLE, stored_target]).pop_front()
		if stored_actor != null and stored_target != target:  # Only set if different
			set_target(stored_target)
		# If actor is out of view, do nothing (keep focus stored but don't change target)

func clear_focus_slot(slot: String) -> void:
	if not is_primary(): return

	var old_target: String = ""
	match slot:
		"top_left":
			old_target = focus_top_left
			focus_top_left = ""
			if old_target != "":
				Finder.select(Group.UI_FOCUS_WIDGET_TOP_LEFT).remove_plate(old_target)
		"top_right":
			old_target = focus_top_right
			focus_top_right = ""
			if old_target != "":
				Finder.select(Group.UI_FOCUS_WIDGET_TOP_RIGHT).remove_plate(old_target)
		"bot_left":
			old_target = focus_bot_left
			focus_bot_left = ""
			if old_target != "":
				Finder.select(Group.UI_FOCUS_WIDGET_BOT_LEFT).remove_plate(old_target)
		"bot_right":
			old_target = focus_bot_right
			focus_bot_right = ""
			if old_target != "":
				Finder.select(Group.UI_FOCUS_WIDGET_BOT_RIGHT).remove_plate(old_target)

func get_focus_slot(slot: String) -> String:
	match slot:
		"top_left":
			return focus_top_left
		"top_right":
			return focus_top_right
		"bot_left":
			return focus_bot_left
		"bot_right":
			return focus_bot_right
	return ""

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
	# If no actors available, keep current target (don't untarget)
	return target

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
	# If no actors available, keep current target (don't untarget)
	return target

func isometric_distance_to_actor(other: Actor) -> float:
	if other == null: return 0.0
	return position.distance_to(other.position) * std.isometric_factor(position.angle_to(other.position))
	
func isometric_distance_to_point(point: Vector2) -> float:
	var base_distance = position.distance_to(point)
	if base_distance < 0.1:  # Avoid calculation issues with very small distances
		return base_distance
	return base_distance * std.isometric_factor(position.angle_to(point))
	
func line_of_sight_to_point(point: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query: LineOfSightQueryParameters = LineOfSightQueryParameters.builder()\
	.from(position)\
	.to(point)\
	.build()
	var result: Dictionary = space_state.intersect_ray(query)
	return result.is_empty()

func click_to_move() -> void:
	# Block input if UI state machine says player input should be blocked
	if get_node("/root/UIStateMachine").should_block_player_input():
		return

	if Input.is_action_pressed("interact"):
		is_direct_movement_active = false  # Switch to pathfinding mode
		current_input_strength = 0.0  # Reset input strength
		var mouse_pos = get_global_mouse_position()
		if is_primary():
			Logger.debug("click_to_move: setting dest to %s" % mouse_pos, self)
		set_destination(mouse_pos)

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
	on_touch.connect(func(target_actor): _local_passive_action_handler(target_actor, func(target_entity): Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, value, name, target_entity.name)))


func build_on_view_action(value: String) -> void:
	var action_ent = Repo.select(value)
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	on_view.connect(func(target_actor): _local_passive_action_handler(target_actor, func(target_entity): Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, value, name, target_entity.name)))

func build_on_map_entered_action(value: String) -> void:
	var action_ent = Repo.select(value)
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	on_map_entered.connect(func(): _local_passive_action_handler(self, func(_target_actor): Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, value, name, name)))

func build_on_map_exited_action(value: String) -> void:
	var action_ent = Repo.select(value)
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	on_map_exited.connect(func(): _local_passive_action_handler(self, func(_target_actor): Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, value, name, name)))

func build_skill(skill_ent: Entity, slot_number: int) -> void:
	if !skill_ent:
		return
	
	var skill_key = skill_ent.key()
	if !skill_key:
		return
	
	# Use static signals based on slot number
	var start_signal_name = "action_%d_start" % slot_number
	var end_signal_name = "action_%d_end" % slot_number
	
	# Connect start action
	if skill_ent.start:
		var start_action_ent = skill_ent.start.lookup()
		if start_action_ent:
			connect(start_signal_name, func(target_actor): 
				_local_action_handler(
					target_actor, 
					func(target_entity): 
						var target_name: String = target_entity.name if target_entity else ""
						
						# Set animation keyframe from action entity
						var keyframe = "tool"  # default
						if "keyframe" in start_action_ent and start_action_ent.keyframe:
							keyframe = start_action_ent.keyframe
						
						# Set animation state and configure SubState lifecycle
						set_state(keyframe)
						use_animation()
						
						# Configure ActionTimer with action duration
						var action_time = 1.0
						if "time" in start_action_ent and start_action_ent.time:
							action_time = start_action_ent.time
						$ActionTimer.wait_time = action_time
						$ActionTimer.start()
						
						# Set SubState to USE for proper lifecycle management
						substate = SubState.USE
						get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, skill_ent.start.key(), name, target_name),
					start_action_ent))
	
	# Connect end action
	if skill_ent.end:
		var end_action_ent = skill_ent.end.lookup()
		if end_action_ent:
			connect(end_signal_name, func(target_actor):
				_local_action_handler(
					target_actor, 
					func(target_entity): 
						var target_name: String = target_entity.name if target_entity else ""
						get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, skill_ent.end.key(), name, target_name),
					end_action_ent))

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
							.map(func(resolved_target): 
								return resolved_target.get_name())\
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
		
func _local_measure_handler(caller_name: String, target_name: String, _expression: String) -> int:
	return Dice.builder()\
		.target_name(target_name)\
		.caller_name(caller_name)\
		.build()\
		.evaluate()

func _local_passive_action_handler(target_actor: Actor, function: Callable) -> void:
	# Passive becuase this will not "snap" the caller to the attention of it's target
	# Because only one client should allow the trigger, this acts as a filter
	if target_actor.is_primary(): 
		function.call(target_actor)
		
func _local_action_handler(target_actor: Actor, function: Callable, action_ent: Entity) -> void:
	if is_primary():
		Logger.debug("_local_action_handler: substate=%s, ActionTimer.stopped=%s" % [substate, $ActionTimer.is_stopped()], self)
	match substate:
		SubState.IDLE, SubState.START:  # Cooldowns mechanic
			# Prevent concurrent skill actions by checking if we're already processing one
			if $ActionTimer.is_stopped():  # Only allow if no action timer is running
				if is_primary():
					Logger.debug("_local_action_handler: executing action", self)
				function.call(target_actor)
				look_at_target()
				root(action_ent.time)
				var timer = get_tree().create_timer(action_ent.time)
				timer.timeout.connect(func(): set_substate(SubState.END), CONNECT_ONE_SHOT)
			elif is_primary():
				Logger.debug("_local_action_handler: blocked by running ActionTimer", self)
		_:
			if is_primary():
				Logger.debug("_local_action_handler: blocked by substate %s" % substate, self)

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

func build_saliencebox(value: int) -> void:
	if value > 0:
		for node in $SalienceBox.get_children(): node.queue_free()
		var salience_shape: CollisionShape2D = CollisionShape2D.new()
		salience_shape.name = "SalienceShape"
		salience_shape.shape = CircleShape2D.new()
		salience_shape.apply_scale(Vector2(1 * value, 0.5 * value))
		$SalienceBox.add_child(salience_shape)

func get_relative_camera_position() -> Vector2:
	# During area targeting, camera follows the overlay
	if is_area_targeting and area_targeting_overlay:
		return area_targeting_overlay.global_position

	# Normal behavior - follow actor with viewshape offset
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
		remove_child(existing_base)
		existing_base.queue_free()
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
		$HitBox.remove_child(existing_polygon)
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

func set_salience(value: int) -> void:
	salience = value
	build_saliencebox(value)

func get_salience() -> int:
	return salience

func set_token(value: PackedByteArray) -> void:
	token = value

func root(time: float) -> void:
	for dict in $ActionTimer.timeout.get_connections():
		$ActionTimer.timeout.disconnect(dict.callable)
	if time <= 0.0: return
	if is_primary():
		Logger.debug("root: caching speed %s and setting to 0 for time %s" % [speed, time], self)
	speed_cache_value = speed
	set_speed(0)
	$ActionTimer.wait_time = time
	$ActionTimer.timeout.connect(unroot)
	$ActionTimer.start()

func unroot() -> void:
	$ActionTimer.stop()
	# Defensive check to prevent speed corruption from overlapping calls
	if speed_cache_value > 0:
		if is_primary():
			Logger.debug("unroot: restoring speed from %s to %s" % [speed, speed_cache_value], self)
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
		modulate.a = 1.0
		add_to_group(Group.IS_VISIBLE)
	else:
		modulate.a = 0.0
		remove_from_group(Group.IS_VISIBLE)
	visible = effect
	
func handle_resource_change(_resource: String) -> void:
	pass
	
func handle_target() -> void:
	Optional.of_nullable(Finder.get_actor(target))\
	.if_present(
		func(target_actor):
			target_actor.set_outline_opacity(0.666)
	)
	
func build_fader() -> void:
	Fader.builder().target(self).build().deploy(self)
	fader = get_node("Fader")

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
	
	# Build animations from dynamic keyframes array
	if animation_ent.keyframes:
		var keyframes_list = animation_ent.keyframes.lookup()
		if keyframes_list:
			for keyframe_ref in keyframes_list:
				var key_frame_ent = keyframe_ref
				if key_frame_ent and key_frame_ent.key():
					var key_frame_name = key_frame_ent.key()
					for radial in std.RADIALS.keys():
						var animation_radial_name: String = "%s:%s" % [key_frame_name, radial]
						sprite_frames.add_animation(animation_radial_name)
						if key_frame_ent.get(radial):  # Check if radial direction exists
							for frame in key_frame_ent.get(radial):
								sprite_frames.add_frame(
									animation_radial_name, 
										build_frame(
											frame,
											get_sprite_size(),
											sprite_ent.texture,
										)
									)
		setup_sprite.call_deferred(sprite_frames)
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Build audio tracks for actor %s" % name)
			.task(build_audio)
			.build()
		)
		
func get_resource(resource_name: String) -> int:
	## Returns 0 if resource does not exist
	return resources.get(resource_name, 0)
	
func get_measure(measure_name: String) -> int:
	## Returns 0 if measure does not exist
	var measure_func: Callable = measures.get(measure_name)
	if measure_func == null: return 0
	var measure_result: int = measure_func.call()
	if measure_result == null: return 0
	return measure_result
		
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
	var nearest_actor = distances.keys().filter(func(actor_name): return distances[actor_name] == min_distance).front()
	return Optional.of_nullable(Finder.get_actor(nearest_actor))

func find_furthest_actor_in_view() -> Optional:
	var distances = map_relative_distance_to_in_view_actors()
	if distances.is_empty():
		return Optional.of_nullable(null)
	var max_distance = distances.values().max()
	var furthest_actor = distances.keys().filter(func(actor_name): return distances[actor_name] == max_distance).front()
	return Optional.of_nullable(Finder.get_actor(furthest_actor))

func find_actor_in_view_with_highest_resource(resource_name: String) -> Optional:
	var actor_resource_map = map_resource_of_in_view_actors(resource_name)
	if actor_resource_map.is_empty():
		return Optional.of_nullable(null)
	var max_resource = actor_resource_map.values().max()
	var actor_with_max_resource = actor_resource_map.keys().filter(func(actor_name): return actor_resource_map[actor_name] == max_resource).front()
	return Optional.of_nullable(Finder.get_actor(actor_with_max_resource))

func find_actor_in_view_with_lowest_resource(resource_name: String) -> Optional:
	var actor_resource_map = map_resource_of_in_view_actors(resource_name)
	if actor_resource_map.is_empty():
		return Optional.of_nullable(null)
	var min_resource = actor_resource_map.values().min()
	var actor_with_min_resource = actor_resource_map.keys().filter(func(actor_name): return actor_resource_map[actor_name] == min_resource).front()
	return Optional.of_nullable(Finder.get_actor(actor_with_min_resource))
	
func find_actor_in_view_with_highest_measure(measure_name: String) -> Optional:
	var actor_measure_map = map_measure_of_in_view_actors(measure_name)
	if actor_measure_map.is_empty():
		return Optional.of_nullable(null)
	var max_measure = actor_measure_map.values().max()
	var actor_with_max_measure = actor_measure_map.keys().filter(func(actor_name): return actor_measure_map[actor_name] == max_measure).front()
	return Optional.of_nullable(Finder.get_actor(actor_with_max_measure))

func find_actor_in_view_with_lowest_measure(measure_name: String) -> Optional:
	var actor_measure_map = map_resource_of_in_view_actors(measure_name)
	if actor_measure_map.is_empty():
		return Optional.of_nullable(null)
	var min_measure = actor_measure_map.values().min()
	var actor_with_min_measure = actor_measure_map.keys().filter(func(actor_name): return actor_measure_map[actor_name] == min_measure).front()
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
		# Set group color with zero opacity (will be made visible when actor enters view)
		var initial_color = group_outline_color
		initial_color.a = 0.0
		set_outline_color(initial_color)

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
	last_position = position
	
	# DEBUG: Log movement state
	if is_primary():
		Logger.debug("use_pathing: pos=%s, dest=%s, dist=%.2f, substate=%s" % [position, destination, position.distance_to(destination), substate], self)
	
	# Set navigation target when destination changes
	if position.distance_to(destination) > DESTINATION_PRECISION:
		if destination.distance_to($NavigationAgent.target_position) > 1.0:
			$NavigationAgent.target_position = destination
	
	# Check if navigation is finished (reached destination)
	if $NavigationAgent.is_navigation_finished() or position.distance_to(destination) <= DESTINATION_PRECISION:
		set_destination(position)
		velocity = Vector2.ZERO
		return
	
	# Get next navigation position and move toward it
	var next_position = $NavigationAgent.get_next_path_position()
	fix = next_position  # Update fix to current navigation target
	
	# Calculate movement WITHOUT isometric compensation (let NavigationAgent2D handle pathfinding)
	var motion = position.direction_to(next_position)
	var base_speed = get_speed(delta)
	
	# Apply input strength if in direct movement mode, otherwise use full speed
	var speed_multiplier = current_input_strength if is_direct_movement_active else 1.0
	
	# Apply minimal isometric factor only for visual smoothness, not pathfinding accuracy
	var isometric_adjustment = std.isometric_factor(motion.angle())
	# Clamp the isometric factor to prevent extreme slowdowns in diagonal movement
	isometric_adjustment = max(isometric_adjustment, 0.75)
	
	velocity = motion * base_speed * speed_multiplier * isometric_adjustment
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
	# Block input if UI state machine says player input should be blocked
	if get_node("/root/UIStateMachine").should_block_player_input():
		return

	# Get input vector - this handles both keyboard and controller
	var motion = Input.get_vector("left", "right", "up", "down")
	
	if motion.length() > 0:
		if is_primary():
			Logger.debug("use_move_directly: motion=%s, substate=%s" % [motion, substate], self)
		is_direct_movement_active = true
		
		# Calculate input strength based on motion magnitude
		# For keyboard: motion will be normalized (length = 1.0)
		# For controller: motion length varies from 0.0 to 1.0 based on stick deflection
		current_input_strength = motion.length()
		
		# Set destination based on input direction using navigation
		var direction = motion.normalized()
		var new_destination: Vector2 = position + direction * DESTINATION_PRECISION * 5
		
		# Reset stuck detection when player manually moves
		stuck_timer = 0.0
		path_recalculation_attempts = 0
		
		# Use navigation system for pathing
		set_destination(new_destination)
		$NavigationAgent.target_position = new_destination
		
	else:
		# No input - stop immediately if we were in direct movement mode
		if is_direct_movement_active:
			is_direct_movement_active = false
			current_input_strength = 0.0
			set_destination(position)  # Stop at current position


func is_point_on_navigation_region(point: Vector2) -> bool:
	var navigation_map = get_world_2d().navigation_map
	var closest_point = NavigationServer2D.map_get_closest_point(navigation_map, point)
	var distance = point.distance_to(closest_point)
	return distance < DESTINATION_PRECISION * 2

func set_destination(point: Vector2) -> void:
	## Where the actor is headed to.
	if is_primary():
		Logger.debug("set_destination: from %s to %s, speed=%s, substate=%s" % [position, point, speed, substate], self)
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
	# Support both static KeyFrames and dynamic skill animations
	var animation_key = "%s:%s" % [state, heading]
	if $Sprite.sprite_frames.has_animation(animation_key):
		$Sprite.animation = animation_key
	else:
		# Fallback to idle if animation doesn't exist
		var idle_key = "%s:%s" % [KeyFrames.IDLE, heading]
		if $Sprite.sprite_frames.has_animation(idle_key):
			$Sprite.animation = idle_key

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

func _on_heading_change(_radial):
	pass

func _on_state_change() -> void:
	set_substate(SubState.START)

func _on_hit_box_body_entered(other):
	Logger.trace("Actor %s: hitbox collision with %s" % [name, other.name if other != self else "self"], self)
	if other != self and $HitboxTriggerCooldownTimer.is_stopped():
		Logger.debug("Actor %s: triggering on_touch event for %s" % [name, other.name], self)
		$HitboxTriggerCooldownTimer.start()
		other.get_parent().on_touch.emit(self)
		
func use_collisions(effect: bool) -> void:
	set_collision_layer_value(Layer.BASE, effect)
	set_collision_mask_value(Layer.BASE, effect)
	$HitBox.set_collision_layer_value(Layer.HITBOX, effect)
	$HitBox.set_collision_mask_value(Layer.HITBOX, effect)
	$ViewBox.set_collision_layer_value(Layer.VIEWBOX, effect)
	$ViewBox.set_collision_mask_value(Layer.SALIENCE, effect)
	$DiscoveryBox.set_collision_layer_value(Layer.DISCOVERY, effect)
	$DiscoveryBox.set_collision_mask_value(Layer.DISCOVERY, effect)
	$SalienceBox.set_collision_layer_value(Layer.SALIENCE, effect)
	
func _on_sprite_animation_changed():
	$Sprite.play()  # Without this, the animation freezes
	
func _on_line_of_sight_entered(_other: Actor) -> void:
	pass
	
func _on_line_of_sight_exited(_other: Actor) -> void:
	pass

func _on_view_box_area_entered(area: Area2D) -> void:
	var other = area.get_parent()
	Logger.trace("Actor %s: view box area entered by %s" % [name, other.name if other != self else "self"], self)
	if other == self: return
	in_view[other.get_name()] = in_view.size()
	Logger.debug("Actor %s: added %s to view (total in view: %d)" % [name, other.name, in_view.size()], self)
	if is_primary():
		other.fader.fade()
		other.visible_to_primary(true)

		# Track group visibility
		if other.target_group != "":
			if not visible_groups.has(other.target_group):
				visible_groups[other.target_group] = 0
			visible_groups[other.target_group] += 1
			# Emit signal for UI updates		
			visible_groups_changed.emit(visible_groups)
	self.on_view.emit(other)

func _on_view_box_area_exited(area: Area2D) -> void:
	var other = area.get_parent()
	Logger.trace("Actor %s: view box area exited by %s" % [name, other.name if other != self else "self"], self)
	if other == self: return
	in_view.erase(other.get_name())
	Logger.debug("Actor %s: removed %s from view (remaining in view: %d)" % [name, other.name, in_view.size()], self)
	var other_name: String = other.get_name()
	var this_actor_name: String = get_name()
	other.remove_from_group(Group.LINE_OF_SIGHT)

	# Use fader callback to defer group counter decrement until visibility transition completes
	other.fader.at_next_appear(
		func():
			Optional.of_nullable(Finder.get_actor(this_actor_name))\
			.if_present(
				func(this_actor):
					# Decrement group visibility tracking
					if this_actor.is_primary() and other.target_group != "":
						if this_actor.visible_groups.has(other.target_group):
							this_actor.visible_groups[other.target_group] -= 1
							if this_actor.visible_groups[other.target_group] <= 0:
								this_actor.visible_groups.erase(other.target_group)
							# Emit signal for UI updates
							this_actor.visible_groups_changed.emit(this_actor.visible_groups)
					# Clear target if the exiting actor was targeted
					if other.get_name() == this_actor.get_target():
						this_actor.set_target("")
					other.visible_to_primary(false)
			)
	)
	other.fader.appear()

## Area Targeting Functions

func enter_area_targeting(action_key: String, action_ent: Entity) -> void:
	"""Enter area targeting mode for an AOE action"""
	if !action_ent or !action_ent.area:
		return

	# Get the polygon entity
	var polygon_ent = action_ent.area.lookup()
	if !polygon_ent:
		return

	# Build the overlay using builder pattern
	var range_limit = action_ent.range if "range" in action_ent else 10000.0
	area_targeting_overlay = AreaTargetingOverlay.builder()\
		.polygon(polygon_ent)\
		.range_limit(range_limit)\
		.start_position(global_position)\
		.build()

	# Add overlay to scene and set position
	get_parent().add_child(area_targeting_overlay)
	area_targeting_overlay.global_position = global_position

	# Set state
	is_area_targeting = true
	area_targeting_action = action_key
	area_targeting_start_pos = global_position

	# Root the player
	if "time" in action_ent and action_ent.time:
		root(action_ent.time + 60.0)  # Root for action time + large buffer

	# Set UI state
	get_node("/root/UIStateMachine").transition_to(UIStateMachine.State.AREA_TARGETING)

func update_area_targeting(delta: float) -> void:
	"""Update area targeting overlay position based on input"""
	if !is_area_targeting or !area_targeting_overlay:
		return

	var action_ent = Repo.select(area_targeting_action)
	if !action_ent:
		cancel_area_targeting()
		return

	# Get directional input
	var motion = Input.get_vector("left", "right", "up", "down")

	if motion.length() > 0:
		# Get speed from action or use default
		var targeting_speed = action_ent.speed if "speed" in action_ent else 300.0

		# Apply isometric factor to speed based on motion angle
		var isometric_adjustment = std.isometric_factor(motion.angle())
		var adjusted_speed = targeting_speed * isometric_adjustment

		# Move the overlay
		var new_position = area_targeting_overlay.global_position + motion * adjusted_speed * delta

		# Clamp to max range
		var range_limit = action_ent.range if "range" in action_ent else 10000.0
		var distance = area_targeting_start_pos.distance_to(new_position)

		if distance > range_limit:
			# Clamp to circle boundary
			var direction = (new_position - area_targeting_start_pos).normalized()
			new_position = area_targeting_start_pos + direction * range_limit
			distance = range_limit

		area_targeting_overlay.global_position = new_position
		area_targeting_overlay.update_range_indicator(distance)

func execute_area_action() -> void:
	"""Execute the area action on all targets within the polygon"""
	if !is_area_targeting or !area_targeting_overlay:
		return

	var action_ent = Repo.select(area_targeting_action)
	if !action_ent:
		cancel_area_targeting()
		return

	# Get all actors in the scene
	var all_actors = get_tree().get_nodes_in_group(Group.ACTOR)

	# Get the polygon entity to check bounds
	var polygon_ent = action_ent.area.lookup()
	if !polygon_ent:
		cancel_area_targeting()
		return

	# Build a polygon shape for collision detection
	var polygon_points: PackedVector2Array = []
	for vertex in polygon_ent.vertices.lookup():
		# Transform vertices to world space (apply isometric scale)
		var local_point = Vector2(vertex.x, vertex.y) * area_targeting_overlay.scale
		var world_point = area_targeting_overlay.global_position + local_point
		polygon_points.append(world_point)

	# Find all actors within the polygon
	var targets_in_area: Array = []
	Logger.debug("Area action: checking %d actors against polygon" % all_actors.size(), self)
	Logger.debug("Area action: polygon points = %s" % polygon_points, self)
	Logger.debug("Area action: caster position = %s" % global_position, self)

	for actor_node in all_actors:
		# Check if actor's position is inside the polygon
		var is_in_polygon = Geometry2D.is_point_in_polygon(actor_node.global_position, polygon_points)
		Logger.debug("Area action: actor %s at %s - in polygon: %s" % [actor_node.name, actor_node.global_position, is_in_polygon], self)
		if is_in_polygon:
			targets_in_area.append(actor_node)

	Logger.debug("Area action: found %d targets in area" % targets_in_area.size(), self)

	# Invoke the action on each target
	for target_actor in targets_in_area:
		Logger.debug("Area action: invoking on self=%s, target=%s" % [name, target_actor.name], self)
		get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(
			1,
			area_targeting_action,
			name,
			target_actor.name
		)

	# Exit targeting mode
	cancel_area_targeting()

func cancel_area_targeting() -> void:
	"""Cancel area targeting and clean up"""
	if area_targeting_overlay:
		area_targeting_overlay.queue_free()
		area_targeting_overlay = null

	is_area_targeting = false
	area_targeting_action = ""
	area_targeting_start_pos = Vector2.ZERO

	# Stop the ActionTimer to prevent conflict with timer-based unroot
	$ActionTimer.stop()

	# Unroot the player by resetting speed
	if speed_cache_value > 0:
		set_speed(speed_cache_value)

	# Return to gameplay state
	get_node("/root/UIStateMachine").transition_to(UIStateMachine.State.GAMEPLAY)

func is_npc() -> bool:
	return is_in_group(Group.NPC)
	
func _notification(what):
	# It is important to save on this hook because it will also save on OS notifications. i.e. alt-F4
	if what == NOTIFICATION_WM_CLOSE_REQUEST and std.is_host_or_server() and !token.is_empty() and !is_npc():
		save()

func _on_tree_exiting() -> void:
	Controller.broadcast_actor_is_despawning.rpc_id(1, peer_id, map)

func _on_discovery_box_body_entered(tileMapLayer: FadingTileMapLayer) -> void:
	Logger.trace("Actor %s: discovery box collision with tilemap layer %s" % [name, tileMapLayer.name if tileMapLayer else "unknown"], self)
	if tileMapLayer is FadingTileMapLayer:
		Logger.debug("Actor %s: setting discovery source for tilemap layer %s" % [name, tileMapLayer.name], self)
		tileMapLayer.set_discovery_source(self)
