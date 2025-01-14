extends Node
## Holds controller rpc_id endpoints to allow the server to manipulate clients.

@rpc("authority", "call_local", "reliable")
func broadcast_actor_render(peer_id: int, map: String) -> void:
	var actor_node = get_tree().get_first_node_in_group(str(peer_id))
	Queue.enqueue(
		Queue.Item.builder()
		.task(func(): actor_node.is_awake(Finder.get_primary_actor().map == map))
		.condition(func(): return Finder.get_primary_actor() != null)
		.build()
	)

@rpc("reliable", "call_local", "any_peer")
func despawn_actor_by_peer_id(peer_id) -> void:
	var actor = get_tree().get_first_node_in_group(str(peer_id))
	if actor != null:
		actor.queue_free()
