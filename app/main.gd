extends Node

func _ready() -> void:
	ArgParse.parse()
	DisplayServer.window_set_title(get_window_title())
	start()

func get_window_title() -> String:
	return ("%s %s" % [Cache.archive, Network.Mode.find_key(Cache.network)]).strip_edges()

func start() -> void:
	match Cache.network:
		Network.Mode.HOST:
			Secrets.load_or_create_rsa()
			Network.start_server()
			Network.server_established.connect(func(): Route.to(Scene.loading))
		Network.Mode.SERVER:
			Secrets.load_or_create_rsa()
			Network.start_server()
			Network.server_established.connect(func(): Route.to(Scene.loading))
		Network.Mode.CLIENT:
			Route.to(Scene.loading)
		_:
			pass
