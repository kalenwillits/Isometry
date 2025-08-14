extends Node

enum Mode {
	NONE,
	HOST,
	SERVER,
	CLIENT,
}

const DEFAULT_URI: String = "localhost"
const DEFAULT_PORT: int = 5000
const DEFAULT_MAX_NUM_CLIENTS: int = 4095

func _ready():
	pass
	
func _on_tree_exiting():
	Logger.debug("Network shutting down", self)
	pass
	
func start_server() -> void:
	Logger.info("Starting server on port %s" % std.coalesce(Cache.port, DEFAULT_PORT), self)
	establish_server(std.coalesce(Cache.port, DEFAULT_PORT))
	
func start_client() -> void:
	Logger.info("Starting client connecting to %s:%s" % [std.coalesce(Cache.uri, DEFAULT_URI), std.coalesce(Cache.port, DEFAULT_PORT)], self)
	establish_client(std.coalesce(Cache.uri, DEFAULT_URI), std.coalesce(Cache.port, DEFAULT_PORT))
	
# PROPERTIES -------------------------------------------------------------------------------------------------------- #

# A MultiplayerPeer implementation that should be passed to
# MultiplayerAPI.multiplayer_peer after being initialized as either a client,
# server, or mesh. Events can then be handled by connecting to MultiplayerAPI
# signals. See ENetConnection for more information on the ENet library wrapper.

# Note: ENet only uses UDP, not TCP. When forwarding the server port to make
# your server accessible on the public Internet, you only need to forward the
# server port in UDP. You can use the UPNP class to try to forward the server
# port automatically when starting the server.
var peer = ENetMultiplayerPeer.new()
# --------------------------------------------------------------------------------------------------------- PROPERTIES #

# SIGNALS ------------------------------------------------------------------------------------------------------------ #

# Emitted when this MultiplayerAPI's multiplayer_peer fails to establish a
# connection to a server. Only emitted on clients.
signal peer_connected(peer_id)

# Emitted when this MultiplayerAPI's multiplayer_peer disconnects from a
# peer. Clients get notified when other clients disconnect from the same
# server.
signal peer_disconnected(peer_id)

# Emitted when this MultiplayerAPI's multiplayer_peer successfully
# connected to a server. Only emitted on clients.
signal connected_to_server

# Emitted when this MultiplayerAPI's multiplayer_peer fails to establish a
# connection to a server. Only emitted on clients.
signal connection_failed

# Emitted when this MultiplayerAPI's multiplayer_peer disconnects from a
# peer. Clients get notified when other clients disconnect from the same
# server.
signal server_disconnected

signal server_established

signal client_established
# ------------------------------------------------------------------------------------------------------------ SIGNALS #

func establish_server(port: int = 5000, max_clients: int = DEFAULT_MAX_NUM_CLIENTS):
	Logger.debug("Establishing server: port=%s, max_clients=%s, trial=%s" % [port, max_clients, OS.has_feature("trial")], self)
	if OS.has_feature("trial"):
		max_clients = 0
		Logger.trace("Trial version detected, setting max_clients to 0", self)
	# 	Create server that listens to connections via port. The port needs to
	# 	be an available, unused port between 0 and 65535. Note that ports below
	# 	1024 are privileged and may require elevated permissions depending on
	# 	the platform.
	if peer.create_server(port, max_clients) != OK:
		Logger.error("Failed to create server on port %s" % port, self)
		return
	else:
		Logger.info("Server created successfully on port %s" % port, self)
	# The IP used when creating a server. This is set to the wildcard "*" by
	# default, which binds to all available interface.
	#peer.set_bind_ip(uri)
	multiplayer.set_multiplayer_peer(peer)
	Logger.trace("Multiplayer peer set for server", self)
	multiplayer.peer_connected.connect(func(peer_id): 
		Logger.debug("Server received peer_connected signal for peer_id=%s" % peer_id, self)
		peer_connected.emit(peer_id))
	multiplayer.peer_disconnected.connect(func(peer_id): 
		Logger.debug("Server received peer_disconnected signal for peer_id=%s" % peer_id, self)
		peer_disconnected.emit(peer_id))
	_defer_signal(func(): server_established.emit())

func establish_client(uri: String = "localhost", port: int = 5000):
	Logger.debug("Establishing client: uri=%s, port=%s, trial=%s" % [uri, port, OS.has_feature("trial")], self)
	if OS.has_feature("trial"): 
		Logger.trace("Trial version detected, skipping client creation", self)
		return
	# Create client that connects to a server at uri using specified port.
	if peer.create_client(uri, port) != OK:
		Logger.error("Failed to create client connecting to %s:%s" % [uri, port], self)
		return
	else:
		Logger.info("Client created successfully, connecting to %s:%s" % [uri, port], self)
	# The peer object to handle the RPC system (effectively enabling networking
	# when set). 
	multiplayer.set_multiplayer_peer(peer)
	Logger.trace("Multiplayer peer set for client", self)
	multiplayer.connected_to_server.connect(func(): 
		Logger.debug("Client received connected_to_server signal", self)
		connected_to_server.emit())
	multiplayer.connection_failed.connect(func(): 
		Logger.debug("Client received connection_failed signal", self)
		connection_failed.emit())
	multiplayer.server_disconnected.connect(func(): 
		Logger.debug("Client received server_disconnected signal", self)
		server_disconnected.emit())
	_defer_signal(func(): client_established.emit())
	
func unestablish():
	Logger.info("Unestablishing network connection", self)
	multiplayer.set_multiplayer_peer(null)
	Logger.debug("Network connection unestablished", self)

func _on_connected_to_server():
	Logger.info("Connected to server.", self)

func _on_connection_failed():
	Logger.info("Connection failed.", self)

func _on_peer_connected(peer_id):
	Logger.info("Peer connected [%s]." % peer_id, self)

func _on_peer_disconnected(peer_id):
	Logger.info("Peer disconnected [%s]." % peer_id, self)

func _on_server_disconnected():
	Logger.info("Server disconnected.", self)

func _defer_signal(function) -> void:
	function.call_deferred()
