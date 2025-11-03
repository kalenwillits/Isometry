extends Node

func _ready():
	pass
	
@rpc("any_peer", "reliable")
func authenticate_and_spawn_actor(peer_id: int, token: PackedByteArray) -> void:
	Logger.info("Authentication request received for peer_id=%s" % peer_id, self)
	Queue.enqueue(
			Queue.Item.builder()
			.comment("Spawn actor for new authenticated login %s" % peer_id)
			.condition(func(): return Secret.public_key != null)
			.task(func():
				var auth: Secret.Auth = Secret.Auth.builder().token(token).build()
				Logger.debug("Validating auth token for peer_id=%s" % peer_id, self)
				if auth.is_valid():
					Logger.info("Authentication successful for user=%s, peer_id=%s" % [auth.get_username(), peer_id], self)
					var main_ent = Repo.select(Group.MAIN_ENTITY)
					var data: Dictionary = {
						"peer_id": peer_id, 
						"token": token, 
						"name": auth.get_username(),
						"speed": main_ent.actor.lookup().speed
					}
					if FileAccess.file_exists(auth.get_path()): 
						Logger.debug("Loading existing player data from %s" % auth.get_path(), self)
						var result = io.load_json(auth.get_path())
						if result:
							data.merge(result, false) # False because we do not want to overwrite the new peer id
							Logger.trace("Merged player data: %s" % data, self)
					Logger.debug("Spawning actor with data: peer_id=%s, name=%s, speed=%s" % [data.peer_id, data.name, data.speed], self)
					Finder.select(Group.SPAWNER).spawn(data)
					# Sync initial resources after spawn completes
					Queue.enqueue(
						Queue.Item.builder()
						.comment("Sync initial resources for peer %s" % peer_id)
						.condition(func(): return Finder.get_actor(str(peer_id)) != null)
						.task(func():
							var actor = Finder.get_actor(str(peer_id))
							if actor != null:
								Controller.sync_all_resources.rpc(str(peer_id), actor.resources))
						.build()
					)
				else:
					Logger.warn("Authentication failed for peer_id=%s - invalid token" % peer_id, self)
				)
			.build()
		)


@rpc("authority", "reliable")
func request_token_from_peer() -> void:
	Logger.info("Token request received from server", self)
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
	Logger.debug("Public key request from peer_id=%s" % peer_id, self)
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
	Logger.debug("Received public key from server (length=%s)" % public_key.length(), self)
	if Cache.network == Network.Mode.CLIENT:
		Secret.set_public_key(public_key)

@rpc("any_peer", "call_local", "reliable")
func request_spawn_actor(peer_id: int) -> void:
	Logger.debug("Spawn actor request for peer_id=%s" % peer_id, self)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("request_spawn_actor")
		.condition(func(): return Finder.get_actor(str(peer_id)) == null)
		.task(func(): Finder.select(Group.SPAWNER).spawn(Cache.unpack(str(peer_id))))
		.build()
	)
	
@rpc("authority", "call_local", "reliable")
func render_map(map: String) -> void:
	Logger.info("Rendering map: %s" % map, self)
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
	for navigation_region: NavigationRegion2D in Finder.query([Group.NAVIGATION]):
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Enable navigation region on map %s = %s" % [map, navigation_region.is_in_group(map)])
			.condition(func(): return navigation_region.get_parent().build_complete())
			.task(func(): 
				navigation_region.enabled = navigation_region.is_in_group(map)
				navigation_region.visible = navigation_region.is_in_group(map)
				)
			.build()
		)

@rpc("authority", "call_local", "reliable")
func fade_and_render_map(peer_id: int, map: String) -> void:
	Logger.info("Initiating map transition to %s for peer_id=%s" % [map, peer_id], self)
	Transition.at_next_fade(func(): Controller.render_map(map))
	Transition.at_next_fade(func(): Controller.request_spawn_actor.rpc_id(1, peer_id))
	Transition.fade()

@rpc("any_peer", "call_local", "reliable")
func broadcast_actor_is_despawning(peer_id: int, _map: String) -> void:
	Logger.info("Broadcasting actor despawn for peer_id=%s" % peer_id, self)
	for targeted_by_actor: Actor in Finder.query([Group.ACTOR, str(peer_id)]):
		targeted_by_actor.set_target("") # Clear ANY other actor from being able to target_this one

@rpc("any_peer", "call_local", "reliable")
func submit_chat_request_to_server(author: String, message: String) -> void:
	broadcast_chat.rpc(author, message)
	
@rpc("authority", "call_local", "reliable")
func broadcast_chat(author, message: String) -> void:
	Finder.select(Group.UI_CHAT_WIDGET).submit_message(author, message)

@rpc("authority", "call_local", "reliable")
func open_plate_on_client(plate_key: String, caller: String, target: String) -> void:
	Finder.select(Group.INTERFACE).open_plate_for_actor(plate_key, caller, target)

@rpc("authority", "call_local", "reliable")
func sync_resource(actor_name: String, resource_key: String, new_value: int) -> void:
	"""
	Broadcast a single resource change from server to all clients.
	Called by server after validating and applying resource change.
	"""
	var actor = Finder.get_actor(actor_name)
	if actor == null:
		Logger.warn("sync_resource: actor %s not found" % actor_name, self)
		return

	var old_value = actor.resources.get(resource_key, 0)
	actor.resources[resource_key] = new_value

	Logger.debug("sync_resource: %s.%s: %d -> %d" % [actor_name, resource_key, old_value, new_value], self)
	
	# TODO -- use a finder query to locate the correct resource UI elements and update them that wy
	# Trigger UI update if this is the primary actor
	if actor.is_primary():
		actor.handle_resource_change(resource_key)

@rpc("authority", "call_local", "reliable")
func sync_all_resources(actor_name: String, resources: Dictionary) -> void:
	"""
	Broadcast all resources for an actor (used on spawn/respawn).
	Called by server when actor spawns or needs full resource refresh.
	"""
	var actor = Finder.get_actor(actor_name)
	if actor == null:
		Logger.warn("sync_all_resources: actor %s not found" % actor_name, self)
		return

	actor.resources = resources.duplicate()
	Logger.debug("sync_all_resources: %s synced %d resources" % [actor_name, resources.size()], self)

	# Trigger full UI refresh if primary
	if actor.is_primary():
		for resource_key in resources.keys():
			actor.handle_resource_change(resource_key)
