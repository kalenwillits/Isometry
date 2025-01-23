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
	Logger.info(params["message"])
	
func set_destination_self(self_name: String, _target_name: String, params: Dictionary) -> void:
	## destination: Vertex Key
	var vertex_ent = Repo.select(params.destination)
	Finder.get_actor(self_name).set_destination(Vector2(vertex_ent.x, vertex_ent.y))

func move_map_target(self_name: String, target_name: String, params: Dictionary) -> void:
	## map: KeyRef to Map.
	## location: KeyRef to Vertex where the target actor's new position will be.
	var pack: Dictionary = get_tree().get_first_node_in_group(target_name).pack()
	pack["map"] = params.get("map")
	pack["location"] = params.get("location")
	Cache.pack_actor(target_name.to_int(), pack)
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
	var pack: Dictionary = get_tree().get_first_node_in_group(self_name).pack()
	pack["map"] = params.get("map")
	pack["location"] = params.get("location")
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
		.task(func(): get_parent().render_map.rpc_id(self_name.to_int(), params.map))
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
		var target_actor: Actor = get_tree().get_first_node_in_group(target_name)
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(target_actor).resource(resource).build().minus(value).get_value()
		Logger.debug("minus_resource_target(%s, %s, %s) -> expression=%s result=%s" % [self_name, target_name, params, value, result])		
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
		var self_actor: Actor = get_tree().get_first_node_in_group(self_name)
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(self_actor).resource(resource).build().minus(value).get_value()
		Logger.debug("minus_resource_self(%s, %s, %s) -> expression=%s result=%s" % [self_name, target_name, params, value, result])
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
		var self_actor: Actor = get_tree().get_first_node_in_group(self_name)
		var value: int = Dice.builder().expression(params.expression).build().evaluate()
		var result: int = ResourceOperator.builder().actor(self_actor).resource(resource).build().plus(value).get_value()
		Logger.debug("plus_resource_self(%s, %s, %s) -> expression=%s result=%s" % [self_name, target_name, params, value, result])
	)
# ----------------------------------------------------------------------- Actions #
