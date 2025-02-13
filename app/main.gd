extends Node

func _ready() -> void:
	var parsed_args: Dictionary = ArgParse.parse()
	for arg in [
		"uri", 
		"port", 
		"archive", 
		"network", 
		"dir",
		"username",
		"password",
		]:
		Cache.set(arg, parsed_args.get(arg))
	DisplayServer.window_set_title(get_window_title())
	start()

func get_window_title() -> String:
	return ("%s %s" % [Cache.archive, Network.Mode.find_key(Cache.network)]).strip_edges()

func start() -> void:
	match Cache.network:
		Network.Mode.HOST:
			Secret.load_or_create_rsa()
			Network.start_server()
			Network.server_established.connect(func(): Route.to(Scene.loading))
		Network.Mode.SERVER:
			Secret.load_or_create_rsa()
			Network.start_server()
			Network.server_established.connect(func(): Route.to(Scene.loading))
		Network.Mode.CLIENT:
			Route.to(Scene.loading)
		_:
			pass
