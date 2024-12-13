extends Node

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
	if key_ref_condition == null: return true
	var condition_ent = key_ref_condition.lookup()
	# TODO - dice eval (This needs to happen now. Target and caller resources need to be injected)
	var target_actor = get_tree().get_first_node_in_group(str(target_peer_id))
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
# ACTION SIGNATURE MUST ALWAYS BE (String action_key, int caller_peer_id, int target_peer_id, Dict...params)
@rpc("any_peer", "reliable", "call_local")
func invoke_action(action_key: String, caller_peer_id: int, target_peer_id: int) -> void:
	var action_ent = Repo.select(action_key)
	# TODO condition
	var params := make_params(action_ent)
	call(action_ent.do, caller_peer_id, target_peer_id, params)
	# TODO else
	# TODO then
	

@rpc("any_peer", "reliable", "call_local")
func move_map(caller_peer_id: int, target_peer_id: int, params: Dictionary) -> void:
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
# ----------------------------------------------------------------------- Actions #
