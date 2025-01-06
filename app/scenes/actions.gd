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
func make_params(action_ent: Entity) -> Dictionary:
	var params: Dictionary = {}
	if action_ent.parameters:
		for param_ent in action_ent.parameters.lookup():
			params[param_ent.name_] = param_ent.value
	return params
	
func eval_action_if(caller_peer_id: int, target_peer_id: int, key_ref_condition: KeyRef) -> bool:
	if key_ref_condition == null: return true # if there is no condition set, automatically pass
	var condition_ent = key_ref_condition.lookup()
	var lvalue: int = Dice.builder().scene_tree(get_tree()).caller(caller_peer_id).target(target_peer_id).expression(condition_ent.left).build().evaluate()
	var rvalue: int = Dice.builder().scene_tree(get_tree()).caller(caller_peer_id).target(target_peer_id).expression(condition_ent.right).build().evaluate()
	match OperatorSymbolMap.get(condition_ent.operator):
		OP_EQUAL:
			return lvalue == rvalue
		OP_NOT_EQUAL:
			return lvalue != rvalue
		OP_GREATER:
			return lvalue > rvalue
		OP_LESS:
			return lvalue < rvalue
		OP_GREATER_EQUAL:
			return lvalue >= rvalue
		OP_LESS_EQUAL:
			return lvalue <= rvalue
		_:
			Logger.warn("Condition [%s] evaluates to false due to invalid operator [%s] used -- options are: %s" % [condition_ent.key(), condition_ent.operator, OperatorSymbolMap.keys()])
			return false
	
func handle_move_actor(peer_id: int, map: String) -> void:
	if peer_id <= 0: return
	var actor = get_tree().get_first_node_in_group(str(peer_id))
	if actor: 
		if actor.map == map:
			Logger.warn("Attempting to move actor to the same map...")
		else:
			actor.queue_free()
#  ------------------------------------------------------------------------ Utils #
# Actions ----------------------------------------------------------------------- #
## ACTION SIGNATURE MUST ALWAYS BE (String action_key, int caller_peer_id, int target_peer_id, Dict...params)
@rpc("any_peer", "reliable", "call_local")
func invoke_action(action_key: String, caller_peer_id: int, target_peer_id: int) -> void:
	var action_ent = Repo.select(action_key)
	if eval_action_if(caller_peer_id, target_peer_id, action_ent.if_):
		var params := make_params(action_ent)
		if action_ent.do != null: call(action_ent.do, caller_peer_id, target_peer_id, params)
		if action_ent.then != null: invoke_action(action_ent.then.key(), caller_peer_id, target_peer_id)
	else:
		if action_ent.else_ != null: invoke_action(action_ent.else_.key(), caller_peer_id, target_peer_id)
## ACTION SIGNATURE... ------------------------------------------------------------- #

func move_map_target(caller_peer_id: int, target_peer_id: int, params: Dictionary) -> void:
	## map: KeyRef to Map.
	## location: KeyRef to Vertex where the target actor's new position will be.
	var pack: Dictionary = get_tree().get_first_node_in_group(str(target_peer_id)).pack()
	pack["map"] = params.get("map")
	pack["location"] = params.get("location")
	Queue.enqueue(
		Queue.Item.builder()
		.task(func(): handle_move_actor(target_peer_id, pack.map))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.condition(func(): return get_tree().get_first_node_in_group(str(target_peer_id)) == null)
		.task(func(): get_tree().get_first_node_in_group(Group.SPAWNER).spawn(pack))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.task(func(): get_parent().render_map.rpc_id(target_peer_id, params.map))
		.build()
	)
	
func move_map_self(self_peer_id: int, target_peer_id: int, params: Dictionary) -> void:
	## map: KeyRef to Map.
	## location: KeyRef to Vertex where the target actor's new position will be.
	var pack: Dictionary = get_tree().get_first_node_in_group(str(self_peer_id)).pack()
	pack["map"] = params.get("map")
	pack["location"] = params.get("location")
	Queue.enqueue(
		Queue.Item.builder()
		.task(func(): handle_move_actor(self_peer_id, pack.map))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.condition(func(): return get_tree().get_first_node_in_group(str(self_peer_id)) == null)
		.task(func(): get_tree().get_first_node_in_group(Group.SPAWNER).spawn(pack))
		.build()
	)
	Queue.enqueue(
		Queue.Item.builder()
		.task(func(): get_parent().render_map.rpc_id(self_peer_id, params.map))
		.build()
	)

func minus_resource_target(caller_peer_id: int, target_peer_id: int, params: Dictionary) -> void:
	## resource: 
	## expression: Dice algebra to be subtracted from the target's resource
	if target_peer_id == 0: return
	var target_actor: Actor = get_tree().get_first_node_in_group(str(target_peer_id))
	target_actor.resources[params.resource] = target_actor.resources[params.resource] - Dice.builder().expression(params.expression).build().evaluate()
	
func minus_resource_self(caller_peer_id: int, target_peer_id: int, params: Dictionary) -> void:
	## resource: 
	## expression: Dice algebra to be subtracted from the target's resource
	var self_actor: Actor = get_tree().get_first_node_in_group(str(caller_peer_id))
	self_actor.resources[params.resource] = self_actor.resources[params.resource] - Dice.builder().expression(params.expression).build().evaluate()
# ----------------------------------------------------------------------- Actions #
