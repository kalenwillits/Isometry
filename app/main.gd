extends Node

func _ready() -> void:
	if OS.has_feature("launcher"):
		Route.to(Scene.launcher)
		return
	var parsed_args: Dictionary = ArgParse.parse()
	for arg in [
		"uri",
		"port",
		"campaign",
		# "network" is already parsed correctly in cache.gd during initialization
		"dir",
		"username",
		"password",
		]:
		Cache.set(arg, parsed_args.get(arg))
	DisplayServer.window_set_title(get_window_title())
	start()

func get_window_title() -> String:
	return ("%s %s" % [Cache.campaign, Network.Mode.find_key(Cache.network)]).strip_edges()

func start() -> void:
		match Cache.network:
			Network.Mode.HOST:
				LoadingModal.show_status("Initializing encryption keys...")
				Secret.load_or_create_rsa()
				LoadingModal.show_status("Starting server...")
				Network.start_server()
				Network.server_established.connect(func(): Route.to(Scene.loading))
			Network.Mode.SERVER:
				LoadingModal.show_status("Initializing encryption keys...")
				Secret.load_or_create_rsa()
				LoadingModal.show_status("Starting server...")
				Network.start_server()
				Network.server_established.connect(func(): Route.to(Scene.loading))
			Network.Mode.CLIENT:
				Route.to(Scene.loading)
			_:
				pass
