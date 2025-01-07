extends Node

var _build_world_complete: bool = false

func build_world_complete() -> bool:
	return _build_world_complete

func _on_peer_connected(peer_id) -> void:
	Logger.info("Peer %s connected..." % peer_id )
	Queue.enqueue(
		Queue.Item.builder()
				.task(func(): spawn_primary_actor(peer_id))
				.build()
			)

func _on_peer_disconnected(peer_id) -> void:
	Logger.info("Peer %s disconnected..." % peer_id)
	get_tree()\
	.get_nodes_in_group(str(peer_id))\
	.map(func(node): node.queue_free()) # TODO - Save actor state?
	
func _on_peer_failed_to_connect() -> void:
	Logger.error("Failed to connect")
	
func _on_server_disconnected() -> void:
	Network.connection_failed.disconnect(_on_peer_failed_to_connect)
	Network.server_disconnected.disconnect(_on_server_disconnected)
	get_tree().quit() # Temporarily closing client
	#Route.to(Scene.splash) # TODO - route to error

func _ready() -> void:
	get_tree().get_first_node_in_group(Group.SPAWNER).set_spawn_function(spawn_actor)
	_handle_network_mode()
	
func spawn_primary_actor(peer_id: int) -> void:
	var main_ent = Repo.select(Group.MAIN_ENTITY)
	var actor_data := {
		"peer_id": peer_id, 
		"map": main_ent.map.lookup().key(), 
		"actor": main_ent.actor.lookup().key()
		}
	get_tree().get_first_node_in_group(Group.SPAWNER).spawn(actor_data)
	if Cache.network == Network.Mode.HOST:
		Queue.enqueue(
			Queue.Item.builder()
			.comment("First time render of map")
			.task(func(): render_map(actor_data.map))
			.condition(build_world_complete)
			.build()
		)

func _handle_network_mode() -> void:
	match Cache.network:
		Network.Mode.HOST, Network.Mode.SERVER:
			Network.peer_connected.connect(_on_peer_connected)
			Network.peer_disconnected.connect(_on_peer_disconnected)
			Queue.enqueue(
				Queue.Item.builder()
				.task(build_world)
				.condition(Repo.get_child_count)
				.build()
			)
			Queue.enqueue(
				Queue.Item.builder()
				.task(func(): spawn_primary_actor(1))
				.condition(build_world_complete)
				.build()
			)
			Queue.enqueue(
				Queue.Item.builder()
				.task(build_deployments)
				.condition(build_world_complete)
				.build()
			)
		Network.Mode.CLIENT:
			Network.connected_to_server.connect(_on_connected_to_server)
			Network.connection_failed.connect(_on_peer_failed_to_connect)
			Network.server_disconnected.connect(_on_server_disconnected)
			Queue.enqueue(
				Queue.Item.builder()
				.task(build_world)
				.condition(Repo.get_child_count)
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
		for deployment_ent in map_ent.deployments.lookup():
			var data := {
				"peer_id": 0,  # NPC 
				"map": map_ent.key(), 
				"actor": deployment_ent.actor.key(),
				"position/x": deployment_ent.location.lookup().x,
				"position/y": deployment_ent.location.lookup().y,
			}
			get_tree().get_first_node_in_group(Group.SPAWNER).spawn(data)
			
func derive_actor_name(peer_id: int) -> String:
	if peer_id > 0:
		return str(peer_id)
	return str(-get_tree().get_node_count_in_group(Group.ACTOR))
	
func spawn_actor(data: Dictionary) -> Actor:
	if data.get("peer_id", 0) > 0:
		Queue.enqueue(
			Queue.Item.builder()
			.condition(func(): return get_node_or_null(derive_actor_name(data.get("peer_id", 0))) != null)
			.task(func(): Controller.broadcast_actor_render(data.peer_id, data.get("map")))
			.build()
		)
	return Actor\
	.builder()\
	.name(derive_actor_name(data.get("peer_id", 0)))\
	.actor(data.get("actor"))\
	.peer_id(data.get("peer_id", 0))\
	.map(data.get("map"))\
	.location(Vector2(data.get("position/x", 0.0), data.get("position/y", 0.0)))\
	.resources(data.get("resources", {}))\
	.build()

@rpc("authority", "call_local", "reliable")
func render_map(map: String) -> void:
	## Turns on visiblity and collisions for this actor's map layer
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
	for actor_node in get_tree().get_nodes_in_group(Group.ACTOR):
		if actor_node.map == map:
			actor_node.enable()
		else:
			actor_node.disable()

func _on_connected_to_server() -> void:
	pass
