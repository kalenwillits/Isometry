extends Node

func _ready():
	pass
	
@rpc("any_peer", "reliable")
func authenticate_and_spawn_actor(peer_id: int, token: PackedByteArray) -> void:
	Logger.info("Authentication request received for peer_id=%s" % peer_id)
	Queue.enqueue(
			Queue.Item.builder()
			.comment("Spawn actor for new authenticated login %s" % peer_id)
			.condition(func(): return Secret.public_key != null)
			.task(func():
				var auth: Secret.Auth = Secret.Auth.builder().token(token).build()
				Logger.debug("Validating auth token for peer_id=%s" % peer_id)

				# Validate campaign checksum first
				var server_checksum: String = Repo.get_campaign_checksum()
				var client_checksum: String = auth.get_campaign_checksum()

				if client_checksum != server_checksum:
					Logger.warn("Campaign checksum mismatch for peer_id=%s - server: %s, client: %s" % [peer_id, server_checksum, client_checksum])
					campaign_mismatch.rpc_id(peer_id)
					return

				if auth.is_valid():
					Logger.info("Authentication successful for user=%s, peer_id=%s" % [auth.get_username(), peer_id])
					var main_ent = Repo.select(Group.MAIN_ENTITY)
					var data: Dictionary = {
						"peer_id": peer_id,
						"token": token,
						"name": auth.get_username(),
						"speed": main_ent.actor.lookup().speed
					}
					if FileAccess.file_exists(auth.get_path()):
						Logger.debug("Loading existing player data from %s" % auth.get_path())
						var result = io.load_json(auth.get_path())
						if result:
							data.merge(result, false) # False because we do not want to overwrite the new peer id
							Logger.trace("Merged player data: %s" % data)
					Logger.debug("Spawning actor with data: peer_id=%s, name=%s, speed=%s" % [data.peer_id, data.name, data.speed])
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
					Logger.warn("Authentication failed for peer_id=%s - invalid token" % peer_id)
				)
			.build()
		)


@rpc("authority", "reliable")
func request_token_from_peer() -> void:
	Logger.info("Token request received from server")
	Queue.enqueue(
			Queue.Item.builder()
			.comment("Authenticating with server")
			.condition(func(): return Secret.public_key != null)
			.task(
				func():
					var auth: Secret.Auth = Secret.Auth.builder()\
						.username(Cache.username)\
						.password(Cache.password)\
						.campaign_checksum(Cache.campaign_checksum)\
						.build()
					if auth.is_valid(): Queue.enqueue(
						Queue.Item.builder()
						.comment("Authenticating with server")
						.task(func(): Controller.authenticate_and_spawn_actor.rpc_id(1, multiplayer.get_unique_id(), auth.get_token()))
						.build()))
	.build()
	)

@rpc("any_peer", "reliable")
func get_public_key(peer_id: int) -> void:
	Logger.debug("Public key request from peer_id=%s" % peer_id)
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
	Logger.debug("Received public key from server (length=%s)" % public_key.length())
	if Cache.network == Network.Mode.CLIENT:
		Secret.set_public_key(public_key)

@rpc("authority", "reliable")
func campaign_mismatch() -> void:
	Logger.error("Campaign version mismatch detected!")

	# Set flag to prevent "Lost connection" message from overwriting this error
	Cache.campaign_mismatch_error = true

	LoadingModal.show_error("Update to the latest campaign version to connect.")

@rpc("any_peer", "call_local", "reliable")
func request_spawn_actor(peer_id: int) -> void:
	Logger.debug("Spawn actor request for peer_id=%s" % peer_id)
	Queue.enqueue(
		Queue.Item.builder()
		.comment("request_spawn_actor")
		.condition(func(): return Finder.get_actor(str(peer_id)) == null)
		.task(func(): Finder.select(Group.SPAWNER).spawn(Cache.unpack(str(peer_id))))
		.build()
	)
	
@rpc("authority", "call_local", "reliable")
func render_map(map: String) -> void:
	Logger.info("Rendering map: %s" % map)
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
				for floor_sprite in Finder.query([Group.FLOOR_SPRITE, map_node.name]):
					floor_sprite.visible = map_node.name == map
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
	Logger.info("Initiating map transition to %s for peer_id=%s" % [map, peer_id])
	Transition.at_next_fade(func(): Controller.render_map(map))
	Transition.at_next_fade(func(): Controller.request_spawn_actor.rpc_id(1, peer_id))
	Transition.fade()

@rpc("any_peer", "call_local", "reliable")
func broadcast_actor_is_despawning(peer_id: int, _map: String) -> void:
	Logger.info("Broadcasting actor despawn for peer_id=%s" % peer_id)
	for targeted_by_actor: Actor in Finder.query([Group.ACTOR, str(peer_id)]):
		targeted_by_actor.set_target("") # Clear ANY other actor from being able to target_this one

@rpc("any_peer", "call_local", "reliable")
func submit_chat_request_to_server(author: String, message: String, channel: int = Chat.Channel.PUBLIC) -> void:
	# Server-side routing logic based on channel type
	if Cache.network == Network.Mode.HOST or Cache.network == Network.Mode.SERVER:
		var sender_actor = Finder.get_actor(author)
		if sender_actor == null:
			Logger.warn("Chat sender actor not found: %s" % author)
			return

		match channel:
			Chat.Channel.WHISPER:
				_route_whisper(author, message, sender_actor)
			Chat.Channel.SAY:
				_route_say(author, message, sender_actor)
			Chat.Channel.FOCUS:
				_route_focus(author, message, sender_actor)
			Chat.Channel.GROUP:
				_route_group(author, message, sender_actor)
			Chat.Channel.PUBLIC:
				_route_public(author, message)
			Chat.Channel.MAP:
				_route_map(author, message, sender_actor)
			Chat.Channel.YELL:
				_route_yell(author, message, sender_actor)

@rpc("authority", "call_local", "reliable")
func broadcast_chat(actor_node_name: String, message: String, channel: int, recipient_node_name: String = "") -> void:
	# Get the actor to retrieve display name
	var actor = Finder.get_actor(actor_node_name)
	var display_name = actor.display_name if actor else actor_node_name

	# Get recipient display name if provided
	var recipient_display_name = ""
	if not recipient_node_name.is_empty():
		var recipient_actor = Finder.get_actor(recipient_node_name)
		recipient_display_name = recipient_actor.display_name if recipient_actor else recipient_node_name

	Finder.select(Group.UI_CHAT_WIDGET).submit_message(display_name, message, channel, recipient_display_name)

# Channel routing helpers
func _route_whisper(author: String, message: String, sender_actor: Actor) -> void:
	var target_name = sender_actor.target
	if target_name.is_empty():
		# Send error message back to sender using LOG channel
		broadcast_chat.rpc_id(sender_actor.peer_id, "System", "No target selected for whisper", Chat.Channel.LOG)
		return

	var target_actor = Finder.get_actor(target_name)
	if target_actor == null or target_actor.is_npc():
		broadcast_chat.rpc_id(sender_actor.peer_id, "System", "Target not found: %s" % target_name, Chat.Channel.LOG)
		return

	# Send to both sender and recipient with recipient info
	broadcast_chat.rpc_id(sender_actor.peer_id, author, message, Chat.Channel.WHISPER, target_name)
	broadcast_chat.rpc_id(target_actor.peer_id, author, message, Chat.Channel.WHISPER, target_name)

func _route_say(author: String, message: String, sender_actor: Actor) -> void:
	var recipients = {}
	recipients[sender_actor.peer_id] = true  # Include sender

	# Send to all actors who have the sender in their view
	for actor in Finder.query([Group.ACTOR]):
		if actor.is_npc():
			continue
		if actor.in_view.has(author):
			recipients[actor.peer_id] = true

	# Broadcast once per unique peer_id
	for peer_id in recipients.keys():
		broadcast_chat.rpc_id(peer_id, author, message, Chat.Channel.SAY)

func _route_focus(author: String, message: String, sender_actor: Actor) -> void:
	var recipients = {}
	recipients[sender_actor.peer_id] = true  # Include sender

	# Add all focus slot targets
	for focus_target in [sender_actor.focus_top_left, sender_actor.focus_top_right,
	                      sender_actor.focus_bot_left, sender_actor.focus_bot_right]:
		if not focus_target.is_empty():
			var target_actor = Finder.get_actor(focus_target)
			if target_actor and not target_actor.is_npc():
				recipients[target_actor.peer_id] = true

	# Broadcast to all recipients
	for peer_id in recipients.keys():
		broadcast_chat.rpc_id(peer_id, author, message, Chat.Channel.FOCUS)

func _route_group(author: String, message: String, sender_actor: Actor) -> void:
	var target_group = sender_actor.target_group
	if target_group.is_empty():
		broadcast_chat.rpc_id(sender_actor.peer_id, "System", "No target group selected", Chat.Channel.LOG)
		return

	var recipients = {}
	# Send to all actors in the same target group
	for actor in Finder.query([Group.ACTOR]):
		if actor.is_npc():
			continue
		if actor.target_group == target_group:
			recipients[actor.peer_id] = true

	# Broadcast once per unique peer_id
	for peer_id in recipients.keys():
		broadcast_chat.rpc_id(peer_id, author, message, Chat.Channel.GROUP)

func _route_public(author: String, message: String) -> void:
	var recipients = {}
	# Broadcast to all non-NPC actors
	for actor in Finder.query([Group.ACTOR]):
		if actor.is_npc():
			continue
		recipients[actor.peer_id] = true

	# Broadcast once per unique peer_id
	for peer_id in recipients.keys():
		broadcast_chat.rpc_id(peer_id, author, message, Chat.Channel.PUBLIC)

func _route_map(author: String, message: String, sender_actor: Actor) -> void:
	# Get sender's current map by checking their groups
	var sender_map = ""
	for group in sender_actor.get_groups():
		# Maps are typically group names like "grasslands", "forest", etc.
		# We need to identify which group is the map group
		if group in Finder.query([Group.MAP]).map(func(node): return node.name):
			sender_map = group
			break

	if sender_map.is_empty():
		Logger.warn("Could not determine map for actor: %s" % author)
		broadcast_chat.rpc_id(sender_actor.peer_id, author, message, Chat.Channel.MAP)
		return

	var recipients = {}
	# Send to all actors on the same map
	for actor in Finder.query([Group.ACTOR]):
		if actor.is_npc():
			continue
		if actor.is_in_group(sender_map):
			recipients[actor.peer_id] = true

	# Broadcast once per unique peer_id
	for peer_id in recipients.keys():
		broadcast_chat.rpc_id(peer_id, author, message, Chat.Channel.MAP)

func _route_yell(author: String, message: String, sender_actor: Actor) -> void:
	# Yell reaches actors within 2x(salience + perception)
	var yell_range = 2 * (sender_actor.salience + sender_actor.perception)

	var recipients = {}
	# Calculate who can hear the yell
	for actor in Finder.query([Group.ACTOR]):
		if actor.is_npc():
			continue
		var distance = sender_actor.global_position.distance_to(actor.global_position)
		if distance <= yell_range:
			recipients[actor.peer_id] = true

	# Broadcast once per unique peer_id
	for peer_id in recipients.keys():
		broadcast_chat.rpc_id(peer_id, author, message, Chat.Channel.YELL)

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
		Logger.warn("sync_resource: actor %s not found" % actor_name)
		return

	var old_value = actor.resources.get(resource_key, 0)
	actor.resources[resource_key] = new_value

	Logger.debug("sync_resource: %s.%s: %d -> %d" % [actor_name, resource_key, old_value, new_value])

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
		Logger.warn("sync_all_resources: actor %s not found" % actor_name)
		return

	actor.resources = resources.duplicate()
	Logger.debug("sync_all_resources: %s synced %d resources" % [actor_name, resources.size()])

	# Trigger full UI refresh if primary
	if actor.is_primary():
		for resource_key in resources.keys():
			actor.handle_resource_change(resource_key)
