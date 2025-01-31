extends Node
## Holds controller rpc_id endpoints to allow the server to manipulate clients.

@rpc("any_peer", "call_local", "reliable")
func request_spawn_actor(peer_id: int) -> void:
	Queue.enqueue(
		Queue.Item.builder()
		.comment("request_spawn_actor")
		.condition(func(): return Finder.get_actor(str(peer_id)) == null)
		.task(func(): Finder.select(Group.SPAWNER).spawn(Cache.unpack_actor(peer_id)))
		.build()
	)
	
@rpc("authority", "call_local", "reliable")
func render_map(map: String) -> void:
	for map_node in Finder.query([Group.MAP]):
		Queue.enqueue(
		Queue.Item.builder()
		.comment("render map")
		.condition(func(): return map_node.build_complete())
		.task(
			func():
				for map_layer in Finder.query([Group.MAP_LAYER, map_node.name]):
					map_layer.enabled = map_node.name == map
				for parallax_layer in Finder.query([Group.PARALLAX, map_node.name]):
					parallax_layer.set_visibility(map_node.name == map)
				).build()
		)

@rpc("authority", "call_local", "reliable")
func fade_and_render_map(peer_id: int, map: String) -> void:
	Transition.at_next_fade(func(): Controller.render_map(map))
	Transition.at_next_fade(func(): Controller.request_spawn_actor.rpc_id(1, peer_id))
	Transition.fade()
