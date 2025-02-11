extends Node
## Holds controller rpc_id endpoints to allow the server to manipulate clients.
#
#@rpc("any_peer", "call_local", "reliable")
#func request_save(peer_id: int, username: String, password: String) -> void:
	#io.use_dir("data")
	#Optional.of_nullable(Finder.get_actor(str(peer_id)))\
	#.map(func(actor): return actor.pack())\
	#.if_present(func(pack): io.save_json())
#
#@rpc("any_peer", "call_local", "reliable")
#func auth(peer_id: int, username: String, password: String) -> void:
	#Cache.pack("AUTH_%s"% peer_id, func(): hash)

@rpc("any_peer", "reliable")
func get_public_key(peer_id: int) -> void:
	if Cache.network == Network.Mode.HOST or Cache.network == Network.Mode.SERVER:
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Send public key to peer %s" % peer_id)
			.condition(func(): return Secrets.public_key != null)
			.task(func(): set_public_key.rpc_id(peer_id, Secrets.get_public_key()))
			.build()
		)


@rpc("any_peer", "reliable")
func set_public_key(public_key: String) -> void:
	if Cache.network == Network.Mode.CLIENT:
		Secrets.set_public_key(public_key)

@rpc("any_peer", "call_local", "reliable")
func request_spawn_actor(peer_id: int) -> void:
	Queue.enqueue(
		Queue.Item.builder()
		.comment("request_spawn_actor")
		.condition(func(): return Finder.get_actor(str(peer_id)) == null)
		.task(func(): Finder.select(Group.SPAWNER).spawn(Cache.unpack(str(peer_id))))
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
				for audio_fader in Finder.query([Group.AUDIO, map_node.name]):
					audio_fader.fade_in() if map_node.name == map else audio_fader.fade_out()
				).build()
		)

@rpc("authority", "call_local", "reliable")
func fade_and_render_map(peer_id: int, map: String) -> void:
	Transition.at_next_fade(func(): Controller.render_map(map))
	Transition.at_next_fade(func(): Controller.request_spawn_actor.rpc_id(1, peer_id))
	Transition.fade()
