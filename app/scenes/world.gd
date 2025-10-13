extends Node

var _build_world_complete: bool = false

func build_world_complete() -> bool:
	return _build_world_complete

func _on_peer_connected(peer_id) -> void:
	Logger.info("Peer %s connected..." % peer_id, self )
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Request Token from peer %s" % peer_id)
		.task(func(): Controller.request_token_from_peer.rpc_id(peer_id))
		.build()
	)

func _on_peer_disconnected(peer_id) -> void:
	Logger.info("Peer %s disconnected..." % peer_id, self)
	Optional.of_nullable(Finder.get_actor(str(peer_id)))\
	.if_present(func(actor): actor.save_and_exit())
	
func _on_peer_failed_to_connect() -> void:
	Logger.error("Failed to connect", self)
	
func _on_server_disconnected() -> void:
	Network.connection_failed.disconnect(_on_peer_failed_to_connect)
	Network.server_disconnected.disconnect(_on_server_disconnected)
	get_tree().quit() # Temporarily closing client
	#Route.to(Scene.splash) # TODO - route to error

func _ready() -> void:
	add_to_group(Group.WORLD)
	get_tree().get_first_node_in_group(Group.SPAWNER).set_spawn_function(spawn_actor)
	_handle_network_mode()
	
func spawn_primary_actor(peer_id: int) -> void:
	var auth = Secret.get_auth()
	var data := {
		"peer_id": peer_id, 
		"token": auth.get_token(),
		"name": auth.get_username()
		}
	if FileAccess.file_exists(auth.get_path()): 
		var result = io.load_json(auth.get_path())
		if result:
			data.merge(result, false) # False because we do not want to overwrite the new peer id
	Finder.select(Group.SPAWNER).spawn(data)

func _handle_network_mode() -> void:
	match Cache.network:
		Network.Mode.HOST, Network.Mode.SERVER:
			Network.peer_connected.connect(_on_peer_connected)
			Network.peer_disconnected.connect(_on_peer_disconnected)
			Queue.enqueue(
				Queue.Item.builder()
				.comment("Building world for host or server")
				.task(build_world)
				.condition(func(): return Repo.get_child_count() != 0)
				.build()
			)
			Queue.enqueue(
				Queue.Item.builder()
				.comment("Spawning host or server actor")
				.task(func(): spawn_primary_actor(1))
				.condition(func(): return build_world_complete() and Secret.public_key != null)
				.build()
			)
			Queue.enqueue(
				Queue.Item.builder()
				.comment("Deploying all other actors for host or server")
				.task(build_deployments)
				.condition(func(): return build_world_complete())
				.build()
			)
		Network.Mode.CLIENT:
			Network.connected_to_server.connect(_on_connected_to_server)
			Network.connection_failed.connect(_on_peer_failed_to_connect)
			Network.server_disconnected.connect(_on_server_disconnected)
			Queue.enqueue(
				Queue.Item.builder()
				.comment("Build world for client")
				.task(build_world)
				.condition(func(): return Repo.get_child_count() != 0)
				.build()
			)
			Network.start_client()
	
func build_world() -> void:
	for map_ent in Repo.query([Group.MAP_ENTITY]):
		build_map(map_ent.key())
	_build_world_complete = true

func build_map(map_key: String) -> void:
	add_child(
		Map
		.builder()
		.map(map_key)
		.build()
	)

func build_deployments() -> void:
	for map_ent in Repo.query([Group.MAP_ENTITY]):
		if map_ent.deployments == null: continue
		for deployment_ent in map_ent.deployments.lookup():
			var actor_ent: Entity = deployment_ent.actor.lookup()
			var data := {
				"peer_id": 0,  # NPC 
				"map": map_ent.key(), 
				"actor": deployment_ent.actor.key(),
				"location/x": deployment_ent.location.lookup().x,
				"location/y": deployment_ent.location.lookup().y,
				"speed": actor_ent.speed,
			}
			get_tree().get_first_node_in_group(Group.SPAWNER).spawn(data)

func get_actor_location(data: Dictionary) -> Vector2:
	## Derives the actor's location using fallbacks
	## - if a location is set using location/x, location/y -- such as when a saved actor reloads. That location takes prority.
	## - if a location is set on data as to be a action parameter
	## - The default spawn location set on the map.
	## - If no map exists for the actor yet, we must derive one from the main entity
	## - Final static fallback value
	
	if data.get("location/x") != null and data.get("location/y") != null:
		return Vector2(data.get("location/x"), data.get("location/y"))
		
	if data.get("location") != null:
		var vertex_ent: Entity = Repo.select(data.get("location"))
		if vertex_ent != null:
			return Vector2(vertex_ent.x, vertex_ent.y)
			
	var main_ent = Repo.select(Group.MAIN_ENTITY)
	if data.get("map", main_ent.map.key()) != null:
		var map_ent: Entity = Repo.select(data.get("map", main_ent.map.key()))
		if map_ent != null:
			var vertex_ent: Entity = map_ent.spawn.lookup()
			if vertex_ent != null:
				return Vector2(vertex_ent.x, vertex_ent.y)
	return Vector2(0.0, 0.0)
	
func spawn_actor(data: Dictionary) -> Actor:
	var main_ent = Repo.select(Group.MAIN_ENTITY)
	var builder: Actor.ActorBuilder = Actor.builder()
	var location: Vector2 = get_actor_location(data)
	builder.display_name(std.coalesce(data.get("name"), data.get("actor", main_ent.actor.lookup().name_)))\
	.username(data.get("username", ""))\
	.token(data.get("token", "".to_utf8_buffer()))\
	.actor(data.get("actor", main_ent.actor.key()))\
	.peer_id(data.get("peer_id", 0))\
	.map(data.get("map", main_ent.map.key()))\
	.location(location)\
	.resources(data.get("resources", {}))\
	.discovery(data.get("discovery", {}))\
	.speed(data.get("speed", main_ent.actor.lookup().speed))\
	.perception(data.get("perception", -1))\
	.salience(data.get("salience", -1))
	return builder.build()

func _on_connected_to_server() -> void:
	Controller.get_public_key.rpc_id(1, multiplayer.get_unique_id())
