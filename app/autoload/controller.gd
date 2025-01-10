extends Node
## Holds controller rpc_id endpoints to allow the server to manipulate clients.

@rpc("authority", "call_local", "reliable")
func broadcast_actor_render(peer_id: int, map: String) -> void:
	var actor_node = get_tree().get_first_node_in_group(str(peer_id))
	if actor_node:
		if typeof(actor_node) == typeof(Actor):
			var primary_actor = get_tree().get_first_node_in_group(str(multiplayer.get_unique_id()))
			if primary_actor != null:
				actor_node.same_map_as_primary(map == primary_actor.map)
				
@rpc("reliable", "call_local", "any_peer")
func despawn_actor_by_peer_id(peer_id) -> void:
	var actor = get_tree().get_first_node_in_group(str(peer_id))
	if actor != null:
		actor.queue_free()
