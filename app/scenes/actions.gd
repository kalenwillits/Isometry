extends Node

var OperatorSymbolMap: Dictionary = {
	"=": OP_EQUAL,
	"==": OP_EQUAL,
	">": OP_GREATER,
	"<": OP_LESS,
	"!=": OP_NOT_EQUAL,
	"<>": OP_NOT_EQUAL,
	">=": OP_GREATER_EQUAL,
	"<=": OP_LESS_EQUAL
}

func _ready() -> void:
	add_to_group(Group.ACTIONS)

# Utils ------------------------------------------------------------------------- #
func get_target(target_name: String) -> Actor:
	return get_parent().get_node_or_null(target_name)

func make_params(action_ent: Entity) -> Dictionary:
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	return params

func calculate_radial_position(reference_position: Vector2, radial: int, distance: float) -> Vector2:
	# Convert degrees to radians
	var angle_rad: float = deg_to_rad(radial)

	# Create direction vector
	var direction: Vector2 = Vector2(cos(angle_rad), sin(angle_rad))

	# Apply isometric adjustment to Y component
	var iso_factor: float = std.isometric_factor(angle_rad)
	direction.y *= iso_factor

	# Normalize after adjustment
	direction = direction.normalized()

	# Calculate final position
	return reference_position + (direction * distance)

func can_teleport_to(actor: Actor, destination: Vector2) -> bool:
	# Check if destination is on navigable terrain
	if not actor.is_point_on_navigation_region(destination):
		return false

	# Check for wall collisions using physics query
	var space_state = actor.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = actor.base
	query.shape = circle
	query.transform.origin = destination
	query.collision_mask = 1 << (Layer.WALL - 1)  # Check walls only

	var results = space_state.intersect_shape(query)
	if not results.is_empty():
		return false

	return true

func get_actors_in_area(center: Vector2, radius: float) -> Array[Actor]:
	var actors_found: Array[Actor] = []

	# Create elliptical shape for query (x=2, y=1 ratio for isometric)
	var space_state = get_tree().root.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	query.shape = circle
	query.transform.origin = center
	query.transform.scale = Vector2(2.0, 1.0)  # Ellipse: wider horizontally
	query.collision_mask = 1 << (Layer.HITBOX - 1)  # Check hitboxes only

	# Execute shape query
	var results = space_state.intersect_shape(query)

	# Extract actors from results
	for result in results:
		var collider = result.collider  # This is the Area2D (HitBox)
		var actor = collider.get_parent()  # Get the Actor parent
		if actor is Actor:
			actors_found.append(actor)

	return actors_found

func handle_move_actor(actor_name: String, map: String) -> void:
	var actor = Finder.get_actor(actor_name)
	if actor: 
		if actor.map == map:
			Logger.warn("Attempting to move actor to the same map...")
		else:
			actor.queue_free()

#  ------------------------------------------------------------------------ Utils #
# Actions ----------------------------------------------------------------------- #
## ACTION SIGNATURE MUST ALWAYS BE (String action_key, int caller_peer_id, int target_peer_id, Dict...params)
@rpc("any_peer", "reliable", "call_local")
func invoke_action(action_key: String, self_name: String, target_name: String) -> void:
	var start_time = Time.get_ticks_usec()
	Logger.trace("[ACTION START] action=%s caller=%s target=%s" % [action_key, self_name, target_name])

	var action_ent = Repo.select(action_key)
	var condition_key = Optional.of_nullable(action_ent.if_).map(func(key_ref): return key_ref.key()).or_else("")

	if condition_key:
		Logger.trace("[ACTION] action=%s has_condition=true condition_key=%s" % [action_key, condition_key])
	else:
		Logger.trace("[ACTION] action=%s has_condition=false (auto-pass)" % action_key)

	var condition_result = ConditionEvaluator.evaluate(
		ConditionEvaluator.EvaluateParams.builder()
		.caller_name(self_name)
		.target_name(target_name)
		.condition_key(condition_key)
		.build()
	)

	if condition_result:
		Logger.trace("[ACTION] action=%s condition_passed=true executing_do=%s" % [action_key, action_ent.do != null])
		var params := make_params(action_ent)
		if action_ent.do != null: call(action_ent.do, self_name, target_name, params)
		if action_ent.then != null:
			Logger.trace("[ACTION] action=%s chaining_to_then=%s" % [action_key, action_ent.then.key()])
			invoke_action(action_ent.then.key(), self_name, target_name)
	else:
		Logger.trace("[ACTION] action=%s condition_passed=false" % action_key)
		if action_ent.else_ != null:
			Logger.trace("[ACTION] action=%s chaining_to_else=%s" % [action_key, action_ent.else_.key()])
			invoke_action(action_ent.else_.key(), self_name, target_name)

	var elapsed_usec = Time.get_ticks_usec() - start_time
	Logger.trace("[ACTION END] action=%s elapsed_usec=%d" % [action_key, elapsed_usec])
## ACTION SIGNATURE... ------------------------------------------------------------- #

func echo(_self_name: String, _target_name: String, params: Dictionary) -> void:
	## message: String
	Logger.info(params["message"])

func wait(_self_name: String, _target_name: String, _params: Dictionary) -> void:
	## No parameters required
	## Duration specified via action.time field
	## Pauses action chain execution. Useful for timing/sequencing effects.
	## Note: This is essentially a no-op that relies on the time field.
	pass
	
func set_destination_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## destination: Vertex Key
	var vertex_ent = Repo.select(params.destination)
	Finder.get_actor(self_name).set_destination(Vector2(vertex_ent.x, vertex_ent.y))

func change_map_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## map: KeyRef to Map.
	## location: KeyRef to Vertex where the target actor's new position will be.
	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: 
		Logger.warn("Attempted to move null actor [%s]" % target_name)
		return
	if target_actor.is_npc():
		Logger.warn("change_map_target on an NPC is unsupported." % target_name)
		return
	var pack: Dictionary = target_actor.pack()
	pack["map"] = params.get("map")
	pack["location"] = params.get("location")
	Cache.pack(Cache.Pack.builder().key(target_name).ref(func(): return pack).expiry(60).build())
	Queue.enqueue(
		Queue.Item.builder()
		.comment("change_map_target -> handle_move_actor")
		.task(func(): handle_move_actor(target_name, pack.map))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("change_map_target -> ask controller to fade and render map")
		.task(func(): Controller.fade_and_render_map.rpc_id(target_name.to_int(), target_name.to_int(), params.map))
		.build()
	)
	
func change_map_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## map: KeyRef to Map.
	## location: KeyRef to Vertex where the target actor's new position will be.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: 
		Logger.warn("Attempted to move null actor [%s]" % self_name)
		return
	if self_actor.is_npc():
		Logger.warn("change_map_self on an NPC is unsupported." % self_name)
		return
	var pack: Dictionary = self_actor.pack()
	pack["map"] = params.get("map")
	pack["location"] = params.get("location")
	Cache.pack(Cache.Pack.builder().key(self_name).ref(func(): return pack).expiry(60).build())
	Queue.enqueue(
		Queue.Item.builder()
		.comment("change_map_self -> handle_move_actor")
		.task(func(): handle_move_actor(self_name, pack.map))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("change_map_self -> spawn actor")
		.condition(func(): return get_tree().get_first_node_in_group(self_name) == null)
		.task(func(): get_tree().get_first_node_in_group(Group.SPAWNER).spawn(pack))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("change_map_self -> render map")
		.task(func(): Controller.render_map.rpc_id(self_name.to_int(), params.map))
		.build()
	)

func minus_resource_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: KeyRef to Resource entity
	## expression: Dice algebra to be subtracted from the target's resource
	Logger.trace("[RESOURCE OP] minus_resource_target target=%s resource=%s expression=%s" % [target_name, params.get("resource"), params.expression])
	if target_name == "": return
	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(
	func(ent):
		return ent.key() == params.get("resource")
	).pop_front()
		).if_present(
	func(resource: Entity):
		var before_value = Finder.get_actor(target_name).resources.get(resource.key(), 0)
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(target_name).resource(resource).build().minus(value).get_value()
		var after_value = result
		Logger.trace("[RESOURCE CHANGE] actor=%s resource=%s operation=minus delta=%d before=%d after=%d" % [target_name, resource.key(), value, before_value, after_value])
	)

func minus_resource_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## resource: KeyRef to Resource entity
	## expression: Dice algebra to be subtracted from caller's resource
	Logger.trace("[RESOURCE OP] minus_resource_self caller=%s resource=%s expression=%s" % [self_name, params.get("resource"), params.expression])
	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(
	func(ent):
		return ent.key() == params.get("resource")
	).pop_front()
		).if_present(
	func(resource: Entity):
		var before_value = Finder.get_actor(self_name).resources.get(resource.key(), 0)
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(self_name).resource(resource).build().minus(value).get_value()
		var after_value = result
		Logger.trace("[RESOURCE CHANGE] actor=%s resource=%s operation=minus delta=%d before=%d after=%d" % [self_name, resource.key(), value, before_value, after_value])
	)
	
func plus_resource_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## resource: KeyRef to Resource entity
	## expression: Dice algebra to be added to caller's resource
	Logger.trace("[RESOURCE OP] plus_resource_self caller=%s resource=%s expression=%s" % [self_name, params.get("resource"), params.expression])
	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(
	func(ent):
		return ent.key() == params.get("resource")
	).pop_front()
		).if_present(
	func(resource: Entity):
		var before_value = Finder.get_actor(self_name).resources.get(resource.key(), 0)
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(self_name).resource(resource).build().plus(value).get_value()
		var after_value = result
		Logger.trace("[RESOURCE CHANGE] actor=%s resource=%s operation=plus delta=%d before=%d after=%d" % [self_name, resource.key(), value, before_value, after_value])
	)

func plus_resource_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: String - KeyRef to Resource entity (required)
	## expression: String - Dice algebra expression (e.g., "2d6+3") (required)
	## Adds to target's resource value. Useful for healing, buffs, giving resources to allies.
	Logger.trace("[RESOURCE OP] plus_resource_target target=%s resource=%s expression=%s" % [target_name, params.get("resource"), params.expression])
	if target_name.is_empty():
		return

	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(func(ent): return ent.key() == params.get("resource"))
		.pop_front()
	).if_present(
		func(resource: Entity):
			var before_value = Finder.get_actor(target_name).resources.get(resource.key(), 0)
			var value: int = Dice.builder().expression(params.expression).build().evaluate()
			var result: int = ResourceOperator.builder().actor(target_name).resource(resource).build().plus(value).get_value()
			var after_value = result
			Logger.trace("[RESOURCE CHANGE] actor=%s resource=%s operation=plus delta=%d before=%d after=%d" % [target_name, resource.key(), value, before_value, after_value])
	)

func set_resource_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## resource: String - KeyRef to Resource entity (required)
	## value: int - Absolute value to set (required)
	## Sets caller's resource to exact value (still respects min/max bounds).
	Logger.trace("[RESOURCE OP] set_resource_self caller=%s resource=%s value=%d" % [self_name, params.get("resource"), params.get("value", 0)])
	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(func(ent): return ent.key() == params.get("resource"))
		.pop_front()
	).if_present(
		func(resource: Entity):
			var before_value = Finder.get_actor(self_name).resources.get(resource.key(), 0)
			var value: int = params.get("value", 0)
			var result: int = ResourceOperator.builder().actor(self_name).resource(resource).build().set_value(value).get_value()
			var after_value = result
			Logger.trace("[RESOURCE CHANGE] actor=%s resource=%s operation=set value=%d before=%d after=%d" % [self_name, resource.key(), value, before_value, after_value])
	)

func set_resource_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: String - KeyRef to Resource entity (required)
	## value: int - Absolute value to set (required)
	## Sets target's resource to exact value (still respects min/max bounds).
	Logger.trace("[RESOURCE OP] set_resource_target target=%s resource=%s value=%d" % [target_name, params.get("resource"), params.get("value", 0)])
	if target_name.is_empty():
		return

	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(func(ent): return ent.key() == params.get("resource"))
		.pop_front()
	).if_present(
		func(resource: Entity):
			var before_value = Finder.get_actor(target_name).resources.get(resource.key(), 0)
			var value: int = params.get("value", 0)
			var result: int = ResourceOperator.builder().actor(target_name).resource(resource).build().set_value(value).get_value()
			var after_value = result
			Logger.trace("[RESOURCE CHANGE] actor=%s resource=%s operation=set value=%d before=%d after=%d" % [target_name, resource.key(), value, before_value, after_value])
	)

func transfer_resource(self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: String - KeyRef to Resource entity (required)
	## expression: String - Dice algebra for amount to transfer (required)
	## Subtracts from target's resource and adds same amount to caller's resource.
	## Example: Drain 10 health from enemy and heal self for same amount.
	Logger.trace("[RESOURCE OP] transfer_resource caller=%s target=%s resource=%s expression=%s" % [self_name, target_name, params.get("resource"), params.expression])
	if target_name.is_empty():
		return

	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(func(ent): return ent.key() == params.get("resource"))
		.pop_front()
	).if_present(
		func(resource: Entity):
			var transfer_amount: int = Dice.builder().expression(params.expression).build().evaluate()

			# Subtract from target
			var target_operator = ResourceOperator.builder().actor(target_name).resource(resource).build()
			var target_before: int = target_operator.get_value()
			target_operator.minus(transfer_amount)
			var target_after: int = target_operator.get_value()
			var actual_transfer: int = target_before - target_after

			# Add same amount to caller
			var self_before: int = Finder.get_actor(self_name).resources.get(resource.key(), 0)
			var self_result: int = ResourceOperator.builder().actor(self_name).resource(resource).build().plus(actual_transfer).get_value()
			var self_after: int = self_result

			Logger.trace("[RESOURCE TRANSFER] resource=%s requested=%d actual=%d target=%s(%d->%d) caller=%s(%d->%d)" % [
				resource.key(),
				transfer_amount,
				actual_transfer,
				target_name,
				target_before,
				target_after,
				self_name,
				self_before,
				self_after
			])
	)

func target_nearest(self_name: String, _target_name: String, _params: Dictionary) -> void:
	## Sets caller's target to the nearest actor in view. No parameters required.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	self_actor.set_target(
		self_actor.find_nearest_actor_in_view()
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_furthest(self_name: String, _target_name: String, _params: Dictionary) -> void:
	## Sets caller's target to the furthest actor in view. No parameters required.
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_furthest_actor_in_view()
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_random(self_name: String, _target_name: String, _params: Dictionary) -> void:
	## Sets caller's target to a random actor in view. No parameters required.
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_random_actor_in_view()
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_lowest_resource(self_name: String, _target_name: String, params: Dictionary) -> void:
	## resource: Name of resource to filter on
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_actor_in_view_with_lowest_resource(params.get("resource"))
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_highest_resource(self_name: String, _target_name: String, params: Dictionary) -> void:
	## resource: Name of resource to filter on
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_actor_in_view_with_highest_resource(params.get("resource"))
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_lowest_measure(self_name: String, _target_name: String, params: Dictionary) -> void:
	## measure: Name of measure to filter on
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_actor_in_view_with_lowest_measure(params.get("measure"))
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_highest_measure(self_name: String, _target_name: String, params: Dictionary) -> void:
	## measure: Name of measure to filter on
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_actor_in_view_with_highest_measure(params.get("measure"))
		.map(func(a): return a.get_name())
		.or_else("")
	)

func target_nearest_in_group(self_name: String, _target_name: String, params: Dictionary) -> void:
	## group: String - KeyRef to Group entity (required)
	## Targets nearest actor in view that belongs to specified group.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null:
		return

	var group_key: String = params.get("group", "")
	if group_key.is_empty():
		return

	# Get all actors in view
	var actors_in_view: Array = self_actor.get_actors_in_view()

	# Filter by group and find nearest
	var nearest_actor: Actor = null
	var nearest_distance: float = INF

	for actor in actors_in_view:
		if actor is Actor and actor.actor_ent and actor.actor_ent.group:
			if actor.actor_ent.group.key() == group_key:
				var distance: float = self_actor.get_position().distance_to(actor.get_position())
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_actor = actor

	if nearest_actor != null:
		self_actor.set_target(nearest_actor.get_name())
	else:
		self_actor.set_target("")

func target_random_in_group(self_name: String, _target_name: String, params: Dictionary) -> void:
	## group: String - KeyRef to Group entity (required)
	## Targets a random actor in view that belongs to specified group.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null:
		return

	var group_key: String = params.get("group", "")
	if group_key.is_empty():
		return

	# Get all actors in view
	var actors_in_view: Array = self_actor.get_actors_in_view()

	# Filter by group
	var group_actors: Array[Actor] = []
	for actor in actors_in_view:
		if actor is Actor and actor.actor_ent and actor.actor_ent.group:
			if actor.actor_ent.group.key() == group_key:
				group_actors.append(actor)

	# Pick random actor from filtered list
	if group_actors.size() > 0:
		var random_actor: Actor = group_actors[randi() % group_actors.size()]
		self_actor.set_target(random_actor.get_name())
	else:
		self_actor.set_target("")

func clear_target_self(self_name: String, _target_name: String, _params: Dictionary) -> void:
	## No parameters required
	## Clears caller's current target, setting it to empty string.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null:
		return
	self_actor.set_target("")

func move_to_target(self_name: String, target_name: String, _params: Dictionary) -> void:
	## Sets caller's destination to target actor's position. No parameters required.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	Optional.of_nullable(Finder.get_actor(target_name))\
	.map(func(t): return t.get_position())\
	.if_present(func(pos): self_actor.set_destination(pos))

func move_away_from_target(self_name: String, target_name: String, params: Dictionary) -> void:
	## distance: float - How far to move away (required)
	## Sets caller's destination to position away from target by specified distance.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null:
		return

	if target_name.is_empty():
		return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null:
		return

	var distance: float = params.get("distance", 0.0)
	if distance <= 0.0:
		return

	# Calculate direction away from target (from target to self)
	var direction: Vector2 = (self_actor.get_position() - target_actor.get_position()).normalized()
	var destination: Vector2 = self_actor.get_position() + (direction * distance)

	self_actor.set_destination(destination)

func move_to_target_radial(self_name: String, target_name: String, params: Dictionary) -> void:
	## radial: int - Angle in degrees (0-360) relative to actor's bearing, where 0° is forward
	## distance: float - Distance in pixels from target position
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)

	# Add actor's bearing to make radial relative to facing direction
	var absolute_radial: int = (self_actor.get_bearing() + radial) % 360
	var target_position: Vector2 = calculate_radial_position(target_actor.get_position(), absolute_radial, distance)
	self_actor.set_destination(target_position)

func move_to_self_radial(self_name: String, _target_name: String, params: Dictionary) -> void:
	## radial: int - Angle in degrees (0-360) relative to actor's bearing, where 0° is forward
	## distance: float - Distance in pixels from caller's current position
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)

	# Add actor's bearing to make radial relative to facing direction
	var absolute_radial: int = (self_actor.get_bearing() + radial) % 360
	var target_position: Vector2 = calculate_radial_position(self_actor.get_position(), absolute_radial, distance)
	self_actor.set_destination(target_position)

func push_target_away(self_name: String, target_name: String, params: Dictionary) -> void:
	## distance: float - How far to push the target away from caller (required)
	## Pushes target away from caller by specified distance. Direction calculated from caller to target.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null:
		return

	if target_name.is_empty():
		return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null:
		return

	var distance: float = params.get("distance", 0.0)
	if distance <= 0.0:
		return

	# Calculate direction from caller to target
	var direction: Vector2 = (target_actor.get_position() - self_actor.get_position()).normalized()
	var push_destination: Vector2 = target_actor.get_position() + (direction * distance)

	# Validate destination is valid
	if can_teleport_to(target_actor, push_destination):
		target_actor.set_location(push_destination)

func pull_target_closer(self_name: String, target_name: String, params: Dictionary) -> void:
	## distance: float - How far to pull the target toward caller (required)
	## Pulls target closer to caller by specified distance. Direction calculated from target to caller.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null:
		return

	if target_name.is_empty():
		return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null:
		return

	var distance: float = params.get("distance", 0.0)
	if distance <= 0.0:
		return

	# Calculate direction from target to caller
	var direction: Vector2 = (self_actor.get_position() - target_actor.get_position()).normalized()
	var pull_destination: Vector2 = target_actor.get_position() + (direction * distance)

	# Validate destination is valid
	if can_teleport_to(target_actor, pull_destination):
		target_actor.set_location(pull_destination)

func teleport_self_to_target(self_name: String, target_name: String, _params: Dictionary) -> void:
	## Instantly teleports caller to target's position. No parameters required.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var destination: Vector2 = target_actor.get_position()

	if can_teleport_to(self_actor, destination):
		self_actor.set_location(destination)

func teleport_target_to_self(self_name: String, target_name: String, _params: Dictionary) -> void:
	## Instantly teleports target to caller's position. No parameters required.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var destination: Vector2 = self_actor.get_position()

	if can_teleport_to(target_actor, destination):
		target_actor.set_location(destination)

func teleport_self_to_target_radial(self_name: String, target_name: String, params: Dictionary) -> void:
	## radial: int - Angle in degrees (0-360) relative to caller's bearing, where 0° is forward
	## distance: float - Distance in pixels from target position
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)

	# Add actor's bearing to make radial relative to facing direction
	var absolute_radial: int = (self_actor.get_bearing() + radial) % 360
	var destination: Vector2 = calculate_radial_position(target_actor.get_position(), absolute_radial, distance)

	if can_teleport_to(self_actor, destination):
		self_actor.set_location(destination)

func teleport_target_to_self_radial(self_name: String, target_name: String, params: Dictionary) -> void:
	## radial: int - Angle in degrees (0-360) relative to target's bearing, where 0° is forward
	## distance: float - Distance in pixels from caller's position
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)

	# Add target's bearing to make radial relative to target's facing direction
	var absolute_radial: int = (target_actor.get_bearing() + radial) % 360
	var destination: Vector2 = calculate_radial_position(self_actor.get_position(), absolute_radial, distance)

	if can_teleport_to(target_actor, destination):
		target_actor.set_location(destination)

func teleport_to_radial(self_name: String, _target_name: String, params: Dictionary) -> void:
	## radial: int - Angle in degrees (0-360) relative to caller's bearing, where 0° is forward
	## distance: float - Distance in pixels from caller's current position
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)

	# Add actor's bearing to make radial relative to facing direction
	var absolute_radial: int = (self_actor.get_bearing() + radial) % 360
	var destination: Vector2 = calculate_radial_position(self_actor.get_position(), absolute_radial, distance)

	if can_teleport_to(self_actor, destination):
		self_actor.set_location(destination)

func teleport(self_name: String, _target_name: String, params: Dictionary) -> void:
	## distance: float - Distance in pixels to teleport forward in current bearing direction
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var distance: float = params.get("distance", 0.0)

	# Use actor's current bearing (0° = forward in facing direction)
	var radial: int = self_actor.get_bearing()
	var destination: Vector2 = calculate_radial_position(self_actor.get_position(), radial, distance)

	if can_teleport_to(self_actor, destination):
		self_actor.set_location(destination)

func swap_positions(self_name: String, target_name: String, _params: Dictionary) -> void:
	## No parameters required
	## Swaps the positions of caller and target. Both actors teleport to each other's location.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null:
		return

	if target_name.is_empty():
		return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null:
		return

	# Store both positions before swapping
	var self_position: Vector2 = self_actor.get_position()
	var target_position: Vector2 = target_actor.get_position()

	# Validate both positions are teleportable
	if not can_teleport_to(self_actor, target_position):
		return
	if not can_teleport_to(target_actor, self_position):
		return

	# Perform the swap
	self_actor.set_location(target_position)
	target_actor.set_location(self_position)

func area_of_effect_at_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## radius: float - Radius of the elliptical area
	## action: String - Action key to execute on each affected actor
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var radius: float = params.get("radius", 0.0)
	var action_key: String = params.get("action", "")
	if action_key.is_empty(): return

	var center: Vector2 = self_actor.get_position()
	var actors_in_area: Array[Actor] = get_actors_in_area(center, radius)

	# Execute action on each actor in the area
	for actor in actors_in_area:
		invoke_action(action_key, self_name, actor.get_name())

func area_of_effect_at_target(self_name: String, target_name: String, params: Dictionary) -> void:
	## radius: float - Radius of the elliptical area
	## action: String - Action key to execute on each affected actor
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var radius: float = params.get("radius", 0.0)
	var action_key: String = params.get("action", "")
	if action_key.is_empty(): return

	var center: Vector2 = target_actor.get_position()
	var actors_in_area: Array[Actor] = get_actors_in_area(center, radius)

	# Execute action on each actor in the area
	for actor in actors_in_area:
		invoke_action(action_key, self_name, actor.get_name())

func area_of_effect_at_self_radial(self_name: String, _target_name: String, params: Dictionary) -> void:
	## radial: int - Angle in degrees (0-360) relative to actor's bearing
	## distance: float - Distance from caller's position
	## radius: float - Radius of the elliptical area
	## action: String - Action key to execute on each affected actor
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)
	var radius: float = params.get("radius", 0.0)
	var action_key: String = params.get("action", "")
	if action_key.is_empty(): return

	# Calculate AoE center position
	var absolute_radial: int = (self_actor.get_bearing() + radial) % 360
	var center: Vector2 = calculate_radial_position(self_actor.get_position(), absolute_radial, distance)
	var actors_in_area: Array[Actor] = get_actors_in_area(center, radius)

	# Execute action on each actor in the area
	for actor in actors_in_area:
		invoke_action(action_key, self_name, actor.get_name())

func area_of_effect_at_target_radial(self_name: String, target_name: String, params: Dictionary) -> void:
	## radial: int - Angle in degrees (0-360) relative to actor's bearing
	## distance: float - Distance from target's position
	## radius: float - Radius of the elliptical area
	## action: String - Action key to execute on each affected actor
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)
	var radius: float = params.get("radius", 0.0)
	var action_key: String = params.get("action", "")
	if action_key.is_empty(): return

	# Calculate AoE center position
	var absolute_radial: int = (self_actor.get_bearing() + radial) % 360
	var center: Vector2 = calculate_radial_position(target_actor.get_position(), absolute_radial, distance)
	var actors_in_area: Array[Actor] = get_actors_in_area(center, radius)

	# Execute action on each actor in the area
	for actor in actors_in_area:
		invoke_action(action_key, self_name, actor.get_name())

func despawn_self(self_name: String, _target_name: String, _params: Dictionary) -> void:
	## Despawns the calling actor. No parameters required.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	self_actor.despawn()

func despawn_target(_self_name: String, target_name: String, _params: Dictionary) -> void:
	## Despawns the target actor. No parameters required.
	if target_name.is_empty(): return
	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return
	target_actor.despawn()

func change_actor_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## actor: String - KeyRef to Actor entity to transform into (required)
	## Transforms the calling actor into a different actor type while preserving all resources,
	## location, and identity. Useful for polymorph, shapeshift, level up, or evolution mechanics.

	var actor_to_transform: Actor = Finder.get_actor(self_name)
	if actor_to_transform == null:
		return

	var new_actor_key: String = params.get("actor", "")
	if new_actor_key.is_empty():
		return

	# Validate new actor entity exists
	if Repo.select(new_actor_key) == null:
		return

	# Pack current state
	var spawn_data: Dictionary = actor_to_transform.pack()

	# Override actor key with new form
	spawn_data["actor"] = new_actor_key

	# Despawn current actor
	actor_to_transform.despawn()

	# Spawn new actor with preserved state (deferred to avoid peer_id conflict)
	Finder.select(Group.SPAWNER).spawn.call_deferred(spawn_data)

func change_actor_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## actor: String - KeyRef to Actor entity to transform target into (required)
	## Transforms the target actor into a different actor type while preserving all resources,
	## location, and identity. Useful for polymorph effects cast on other actors.

	if target_name.is_empty():
		return

	var actor_to_transform: Actor = Finder.get_actor(target_name)
	if actor_to_transform == null:
		return

	var new_actor_key: String = params.get("actor", "")
	if new_actor_key.is_empty():
		return

	# Validate new actor entity exists
	if Repo.select(new_actor_key) == null:
		return

	# Pack current state
	var spawn_data: Dictionary = actor_to_transform.pack()

	# Override actor key with new form
	spawn_data["actor"] = new_actor_key

	# Despawn current actor
	actor_to_transform.despawn()

	# Spawn new actor with preserved state (deferred to avoid peer_id conflict)
	Finder.select(Group.SPAWNER).spawn.call_deferred(spawn_data)

func spawn_actor_at_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## actor: String - KeyRef to Actor entity (required)
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var actor_key: String = params.get("actor", "")
	if actor_key.is_empty(): return

	var spawn_position: Vector2 = self_actor.get_position()
	var npc_peer_id: int = -randi_range(1, 9_999_999)

	var spawn_data := {
		"peer_id": npc_peer_id,
		"actor": actor_key,
		"map": self_actor.map,
		"location/x": spawn_position.x,
		"location/y": spawn_position.y,
		"target": self_actor.target,
	}

	get_tree().get_first_node_in_group(Group.SPAWNER).spawn(spawn_data)

func spawn_actor_at_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## actor: String - KeyRef to Actor entity (required)
	if target_name.is_empty(): return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var actor_key: String = params.get("actor", "")
	if actor_key.is_empty(): return

	var spawn_position: Vector2 = target_actor.get_position()
	var npc_peer_id: int = -randi_range(1, 9_999_999)

	var spawn_data := {
		"peer_id": npc_peer_id,
		"actor": actor_key,
		"map": target_actor.map,
		"location/x": spawn_position.x,
		"location/y": spawn_position.y,
		"target": target_actor.target,
	}

	get_tree().get_first_node_in_group(Group.SPAWNER).spawn(spawn_data)

func spawn_actor_at_self_radial(self_name: String, _target_name: String, params: Dictionary) -> void:
	## actor: String - KeyRef to Actor entity (required)
	## radial: int - Angle in degrees (0-360) relative to caller's bearing
	## distance: float - Distance from caller's position
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var actor_key: String = params.get("actor", "")
	if actor_key.is_empty(): return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)

	# Calculate spawn position using bearing-relative radial
	var absolute_radial: int = (self_actor.get_bearing() + radial) % 360
	var spawn_position: Vector2 = calculate_radial_position(self_actor.get_position(), absolute_radial, distance)
	var npc_peer_id: int = -randi_range(1, 9_999_999)

	var spawn_data := {
		"peer_id": npc_peer_id,
		"actor": actor_key,
		"map": self_actor.map,
		"location/x": spawn_position.x,
		"location/y": spawn_position.y,
		"target": self_actor.target,
	}

	get_tree().get_first_node_in_group(Group.SPAWNER).spawn(spawn_data)

func spawn_actor_at_target_radial(self_name: String, target_name: String, params: Dictionary) -> void:
	## actor: String - KeyRef to Actor entity (required)
	## radial: int - Angle in degrees (0-360) relative to caller's bearing
	## distance: float - Distance from target's position
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	if target_name.is_empty(): return
	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var actor_key: String = params.get("actor", "")
	if actor_key.is_empty(): return

	var radial: int = params.get("radial", 0)
	var distance: float = params.get("distance", 0.0)

	# Calculate spawn position using caller's bearing, but from target's position
	var absolute_radial: int = (self_actor.get_bearing() + radial) % 360
	var spawn_position: Vector2 = calculate_radial_position(target_actor.get_position(), absolute_radial, distance)
	var npc_peer_id: int = -randi_range(1, 9_999_999)

	var spawn_data := {
		"peer_id": npc_peer_id,
		"actor": actor_key,
		"map": target_actor.map,
		"location/x": spawn_position.x,
		"location/y": spawn_position.y,
		"target": self_actor.target,
	}

	get_tree().get_first_node_in_group(Group.SPAWNER).spawn(spawn_data)

func play_keyframe_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## animation: String - KeyRef to Animation entity (required)
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return

	var animation_key: String = params.get("animation", "")
	if animation_key.is_empty(): return

	# Set the animation state to the specified animation
	self_actor.set_state(animation_key)
	self_actor.use_animation()

func play_keyframe_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## animation: String - KeyRef to Animation entity (required)
	if target_name.is_empty(): return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return

	var animation_key: String = params.get("animation", "")
	if animation_key.is_empty(): return

	# Set the animation state to the specified animation
	target_actor.set_state(animation_key)
	target_actor.use_animation()

func use_track(self_name: String, _target_name: String, params: Dictionary) -> void:
	## track: String containing pipe-separated KeyRefs to Track entities (e.g., "track1|track2|track3")
	## Designed to be used as a behavior action.
	var self_actor: Actor = Finder.get_actor(self_name)
	var track_param: String = params.get("track", "")
	var track_keys: Array = track_param.split("|")
	self_actor.use_track(track_keys)

func change_strategy(self_name: String, _target_name: String, params: Dictionary) -> void:
	## strategy: KeyRef to Strategy entity
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.interrupt_strategy()
	var strategy_key: String = params.get("strategy")
	var strategy_ent: Entity
	if strategy_key != null:
		strategy_ent = Repo.query([strategy_key]).pop_front()
	if strategy_ent != null:
		self_actor.set_strategy(strategy_ent)

func set_speed_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## speed: Float value to set target's speed to
	if target_name == "": return
	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return
	var new_speed: float = params.get("speed", 1.0)
	target_actor.set_speed(new_speed)

func set_speed_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## speed: Float value to set caller's speed to
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	var new_speed: float = params.get("speed", 1.0)
	self_actor.set_speed(new_speed)

func temp_speed_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## speed: Float value to temporarily set target's speed to
	## duration: Float time in seconds for the temporary speed change
	if target_name == "": return
	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return
	var new_speed: float = params.get("speed", 1.0)
	var duration: float = params.get("duration", 1.0)
	var original_speed: float = target_actor.speed
	target_actor.set_speed(new_speed)
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func(): 
		if target_actor != null and is_instance_valid(target_actor):
			target_actor.set_speed(original_speed)
	, CONNECT_ONE_SHOT)

func temp_speed_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## speed: Float value to temporarily set caller's speed to
	## duration: Float time in seconds for the temporary speed change
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	var new_speed: float = params.get("speed", 1.0)
	var duration: float = params.get("duration", 1.0)
	var original_speed: float = self_actor.speed
	self_actor.set_speed(new_speed)
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		if self_actor != null and is_instance_valid(self_actor):
			self_actor.set_speed(original_speed)
	, CONNECT_ONE_SHOT)

func set_modulate_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## color: String - Hex color code (e.g., "#ff0000" for red) or color name (required)
	## Sets caller's color modulation/tint. Useful for visual status effects, team colors, highlighting.
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null:
		return

	var color_param: String = params.get("color", "")
	if color_param.is_empty():
		return

	# Parse color from string (supports hex codes and color names)
	var color: Color = Color(color_param) if color_param.begins_with("#") else Color.from_string(color_param, Color.WHITE)
	self_actor.modulate = color

func set_modulate_target(_self_name: String, target_name: String, params: Dictionary) -> void:
	## color: String - Hex color code (e.g., "#ff0000" for red) or color name (required)
	## Sets target's color modulation/tint. Useful for visual status effects, team colors, highlighting.
	if target_name.is_empty():
		return

	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null:
		return

	var color_param: String = params.get("color", "")
	if color_param.is_empty():
		return

	# Parse color from string (supports hex codes and color names)
	var color: Color = Color(color_param) if color_param.begins_with("#") else Color.from_string(color_param, Color.WHITE)
	target_actor.modulate = color

func open_options(_self_name: String, _target_name: String, _params: Dictionary) -> void:
	## Opens the options/settings menu. No parameters required.
	## Currently a placeholder implementation.
	Logger.info("Options menu - Placeholder")

func close_game(_self_name: String, _target_name: String, _params: Dictionary) -> void:
	## Closes/exits the game. No parameters required.
	## Currently a placeholder implementation.
	Logger.info("Close game - Placeholder")

func show_connection_info(_self_name: String, _target_name: String, _params: Dictionary) -> void:
	## Displays connection/network information. No parameters required.
	## Currently a placeholder implementation.
	Logger.info("Connection info - Placeholder")

func open_chat(_self_name: String, _target_name: String, _params: Dictionary) -> void:
	## Opens the chat interface. No parameters required.
	## Currently a placeholder implementation.
	Logger.info("Open chat - Placeholder")

func open_plate(self_name: String, target_name: String, params: Dictionary) -> void:
	## plate: KeyRef to Plate entity
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	var plate_key: String = params.get("plate", "")
	if plate_key.is_empty():
		Logger.warn("open_plate called without plate parameter")
		return

	Queue.enqueue(
		Queue.Item.builder()
		.comment("Call open_plate_on_client")
		.task(func(): Controller.open_plate_on_client.rpc_id(self_actor.peer_id, plate_key, self_name, target_name))
		.build()
	)
# ----------------------------------------------------------------------- Actions #
