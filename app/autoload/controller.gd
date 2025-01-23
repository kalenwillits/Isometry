extends Node
## Holds controller rpc_id endpoints to allow the server to manipulate clients.

@rpc("authority", "call_local", "reliable")
func broadcast_actor_render(peer_id: int, map: String) -> void:
	Queue.enqueue(
		Queue.Item.builder()
		.comment("broadcast_actor_render")
		.task(func(): Finder.get_actor(str(peer_id)).map == map)
		.condition(func(): return (Finder.get_primary_actor() != null) and (Finder.get_actor(str(peer_id)) != null))
		.build()
	)

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
func fade_and_render_map(peer_id: int, map: String) -> void:
	## Turns on visiblity and collisions for this actor's map layer
	Transition.at_next_fade(func():
			for map_node in get_tree().get_nodes_in_group(Group.MAP):
				Queue.enqueue(
				Queue.Item.builder()
				.comment("Enable map layer in fade_and_render_map for map %s" % map_node.name)
				.condition(func(): return map_node.build_complete())
				.task(
					func():
						for layer in map_node.get_children():
							layer.enabled = map_node.name == map
						).build()
				)
			)
	Transition.at_next_fade(func(): Controller.request_spawn_actor.rpc_id(1, peer_id))
	Transition.fade()


@rpc("authority", "call_local", "reliable")
func fade() -> void:
	Transition.fade()
	
@rpc("authority", "call_local", "reliable")
func appear() -> void:
	Transition.appear()
