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

@rpc("any_peer", "reliable")
func request_spawn_actor(peer_id: int) -> void:
	pass # TODO, this requires the actor to get written to disk
		#Queue.enqueue(
		#Queue.Item.builder()
		#.condition(func(): return get_tree().get_first_node_in_group(str(peer_id)) == null)
		#.task(func(): get_tree().get_first_node_in_group(Group.SPAWNER).spawn(pack))
		#.build()
	#)

@rpc("authority", "call_local", "reliable")
func fade_and_render_map(map: String) -> void:
	## Turns on visiblity and collisions for this actor's map layer
	Transition.at_next_fade(func():
			for map_node in get_tree().get_nodes_in_group(Group.MAP):
				Queue.enqueue(
				Queue.Item.builder()
				.condition(map_node.build_complete)
				.task(
					func():
						for layer in map_node.get_children():
							layer.enabled = map_node.name == map
						).build()
				)
			)
	#Transition.at_next_fade(Controller.request_spawn_actor.rpc_id(1)) # TODO
	Transition.fade()


@rpc("authority", "call_local", "reliable")
func fade() -> void:
	Transition.fade()
	
@rpc("authority", "call_local", "reliable")
func appear() -> void:
	Transition.appear()
