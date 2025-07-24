extends Node
	
@rpc("any_peer", "reliable")
func authenticate_and_spawn_actor(peer_id: int, token: PackedByteArray) -> void:
	Queue.enqueue(
			Queue.Item.builder()
			.comment("Spawn actor for new authenticated login %s" % peer_id)
			.condition(func(): return Secret.public_key != null)
			.task(func():
				var auth: Secret.Auth = Secret.Auth.builder().token(token).build()
				if auth.is_valid():
					var data: Dictionary = {"peer_id": peer_id, "token": token, "name": auth.get_username()}
					if FileAccess.file_exists(auth.get_path()): 
						var result = io.load_json(auth.get_path())
						if result:
							data.merge(result, false) # False because we do not want to overwrite the new peer id
					Finder.select(Group.SPAWNER).spawn(data)
				)
			.build()
		)


@rpc("authority", "reliable")
func request_token_from_peer() -> void:
	Queue.enqueue(
			Queue.Item.builder()
			.comment("Authenticating with server")
			.condition(func(): return Secret.public_key != null)
			.task(
				func():
					var auth: Secret.Auth = Secret.Auth.builder().username(Cache.username).password(Cache.password).build()
					if auth.is_valid(): Queue.enqueue(
						Queue.Item.builder()
						.comment("Authenticating with server")
						.task(func(): Controller.authenticate_and_spawn_actor.rpc_id(1, multiplayer.get_unique_id(), auth.get_token()))
						.build()))
	.build()
	)

@rpc("any_peer", "reliable")
func get_public_key(peer_id: int) -> void:
	if Cache.network == Network.Mode.HOST or Cache.network == Network.Mode.SERVER:
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Send public key to peer %s" % peer_id)
			.condition(func(): return Secret.public_key != null)
			.task(func(): set_public_key.rpc_id(peer_id, Secret.get_public_key()))
			.build()
		)


@rpc("any_peer", "reliable")
func set_public_key(public_key: String) -> void:
	if Cache.network == Network.Mode.CLIENT:
		Secret.set_public_key(public_key)

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

@rpc("any_peer", "call_local", "reliable")
func broadcast_actor_is_despawning(peer_id: int, map: String) -> void:
	for targeted_by_actor: Actor in Finder.query([Group.ACTOR, str(peer_id)]):
		targeted_by_actor.set_target("") # Clear ANY other actor from being able to target_this one
