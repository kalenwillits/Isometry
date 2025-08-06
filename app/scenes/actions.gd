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

func handle_move_actor(actor_name: String, map: String) -> void:
	var actor = get_tree().get_first_node_in_group(actor_name)
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
	var action_ent = Repo.select(action_key)
	if ConditionEvaluator.evaluate(
			ConditionEvaluator.EvaluateParams.builder()
			.caller_name(self_name)
			.target_name(target_name)
			.condition_key(
				Optional.of_nullable(action_ent.if_)
				.map(func(key_ref): return key_ref.key())
				.or_else("")
				)
			.build()
		):
		var params := make_params(action_ent)
		if action_ent.do != null: call(action_ent.do, self_name, target_name, params)
		if action_ent.then != null: invoke_action(action_ent.then.key(), self_name, target_name)
	else:
		if action_ent.else_ != null: invoke_action(action_ent.else_.key(),self_name, target_name)
## ACTION SIGNATURE... ------------------------------------------------------------- #

func echo(_self_name: String, _target_name: String, params: Dictionary) -> void:
	## message: String
	Logger.info(params["message"])
	
func set_destination_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## destination: Vertex Key
	var vertex_ent = Repo.select(params.destination)
	Finder.get_actor(self_name).set_destination(Vector2(vertex_ent.x, vertex_ent.y))

func move_map_target(self_name: String, target_name: String, params: Dictionary) -> void:
	## map: KeyRef to Map.
	## location: KeyRef to Vertex where the target actor's new position will be.
	var pack: Dictionary = Finder.get_actor(target_name).pack()
	pack["map"] = params.get("map")
	pack["location"] = params.get("location")
	Cache.pack(Cache.Pack.builder().key(target_name).ref(func(): return pack).expiry(60).build())
	Queue.enqueue(
		Queue.Item.builder()
		.comment("move_map_target -> handle_move_actor")
		.task(func(): handle_move_actor(target_name, pack.map))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("move_map_target -> ask controller to fade and render map")
		.task(func(): Controller.fade_and_render_map.rpc_id(target_name.to_int(), target_name.to_int(), params.map))
		.build()
	)
	
func move_map_self(self_name: String, target_name: String, params: Dictionary) -> void:
	## map: KeyRef to Map.
	## location: KeyRef to Vertex where the target actor's new position will be.
	var pack: Dictionary = Finder.get_actor(self_name).pack()
	pack["map"] = params.get("map")
	pack["location"] = params.get("location")
	Cache.pack(Cache.Pack.builder().key(self_name).ref(func(): return pack).expiry(60).build())
	Queue.enqueue(
		Queue.Item.builder()
		.comment("move map self -> ")
		.task(func(): handle_move_actor(self_name, pack.map))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Move map self")
		.condition(func(): return get_tree().get_first_node_in_group(self_name) == null)
		.task(func(): get_tree().get_first_node_in_group(Group.SPAWNER).spawn(pack))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Move map self")
		.task(func(): Controller.render_map.rpc_id(self_name.to_int(), params.map))
		.build()
	)

func minus_resource_target(self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: 
	## expression: Dice algebra to be subtracted from the target's resource
	if target_name == "": return
	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(
	func(ent): 
		return ent.key() == params.get("resource")
	).pop_front()
		).if_present(
	func(resource: Entity):
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(target_name).resource(resource).build().minus(value).get_value()
		#Logger.debug("minus_resource_target(%s, %s, %s) -> expression=%s result=%s" % [self_name, target_name, params, value, result])		
	)

func minus_resource_self(self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: 
	## expression: Dice algebra to be subtracted from the target's resource
	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(
	func(ent): 
		return ent.key() == params.get("resource")
	).pop_front()
		).if_present(
	func(resource: Entity):
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(self_name).resource(resource).build().minus(value).get_value()
		#Logger.debug("minus_resource_self(%s, %s, %s) -> expression=%s result=%s" % [self_name, target_name, params, value, result])
	)
	
func plus_resource_self(self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: 
	## expression: Dice algebra to be subtracted from the target's resource
	Optional.of_nullable(
		Repo.query([Group.RESOURCE_ENTITY])
		.filter(
	func(ent): 
		return ent.key() == params.get("resource")
	).pop_front()
		).if_present(
	func(resource: Entity):
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(self_name).resource(resource).build().plus(value).get_value()
	)

func target_nearest(self_name: String, target_name: String, params: Dictionary) -> void:
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	self_actor.set_target(
		self_actor.find_nearest_actor_in_view()
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_furthest(self_name: String, target_name: String, params: Dictionary) -> void:
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_furthest_actor_in_view()
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_random(self_name: String, target_name: String, params: Dictionary) -> void:
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_random_actor_in_view()
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_lowest_resource(self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: Name of resource to filter on
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_actor_in_view_with_lowest_resource(params.get("resource"))
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_highest_resource(self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: Name of resource to filter on
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_actor_in_view_with_highest_resource(params.get("resource"))
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_lowest_measure(self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: Name of resource to filter on
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_actor_in_view_with_lowest_measure(params.get("measure"))
		.map(func(a): return a.get_name())
		.or_else("")
	)
	
func target_highest_measure(self_name: String, target_name: String, params: Dictionary) -> void:
	## resource: Name of resource to filter on
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.set_target(
		self_actor.find_actor_in_view_with_highest_measure(params.get("measure"))
		.map(func(a): return a.get_name())
		.or_else("")
	)

func move_to_target(self_name: String, target_name: String, params: Dictionary) -> void:
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	Optional.of_nullable(Finder.get_actor(target_name))\
	.map(func(t): return t.get_position())\
	.if_present(func(pos): self_actor.set_destination(pos))
	
func use_track(self_name: String, target_name: String, params: Dictionary) -> void:
	## Designed to be use as a behavior action.
	var self_actor: Actor = Finder.get_actor(self_name)
	var track_param: String = params.get("track", "")
	var track_keys: Array = track_param.split("|")
	self_actor.use_track(track_keys)

func change_strategy(self_name: String, target_name: String, params: Dictionary) -> void:
	var self_actor: Actor = Finder.get_actor(self_name)
	self_actor.interrupt_strategy()
	var strategy_key: String = params.get("strategy")
	var strategy_ent: Entity
	if strategy_key != null:
		strategy_ent = Repo.query([strategy_key]).pop_front()
	if strategy_ent != null:
		self_actor.set_strategy(strategy_ent)

func set_speed_target(self_name: String, target_name: String, params: Dictionary) -> void:
	## speed: Float value to set target's speed to
	if target_name == "": return
	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return
	var new_speed: float = params.get("speed", 1.0)
	target_actor.set_speed(new_speed)

func set_speed_self(self_name: String, target_name: String, params: Dictionary) -> void:
	## speed: Float value to set caller's speed to
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	var new_speed: float = params.get("speed", 1.0)
	self_actor.set_speed(new_speed)

func temp_speed_target(self_name: String, target_name: String, params: Dictionary) -> void:
	## speed: Float value to temporarily set target's speed to
	## duration: Float time in seconds for the temporary speed change
	if target_name == "": return
	var target_actor: Actor = Finder.get_actor(target_name)
	if target_actor == null: return
	var new_speed: float = params.get("speed", 1.0)
	var duration: float = params.get("duration", 1.0)
	var original_speed: float = target_actor.speed
	target_actor.set_speed(new_speed)
	get_tree().create_timer(duration).timeout.connect(func(): 
		if target_actor != null and is_instance_valid(target_actor):
			target_actor.set_speed(original_speed)
	)

func temp_speed_self(self_name: String, target_name: String, params: Dictionary) -> void:
	## speed: Float value to temporarily set caller's speed to  
	## duration: Float time in seconds for the temporary speed change
	var self_actor: Actor = Finder.get_actor(self_name)
	if self_actor == null: return
	var new_speed: float = params.get("speed", 1.0)
	var duration: float = params.get("duration", 1.0)
	var original_speed: float = self_actor.speed
	self_actor.set_speed(new_speed)
	get_tree().create_timer(duration).timeout.connect(func():
		if self_actor != null and is_instance_valid(self_actor):
			self_actor.set_speed(original_speed)
	)
# ----------------------------------------------------------------------- Actions #
