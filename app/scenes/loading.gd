extends Node

func _ready() -> void:
	# Queue 1: Show initial loading status
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Modal: Show loading campaign archive")
		.task(func(): LoadingModal.show_status("Loading campaign archive..."))
		.build()
	)

	# Queue 2: Load archive from disk
	if Repo.get_child_count() == 0:
		Repo.load_failure.connect(_on_load_failure)
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Load campaign archive from disk")
			.task(Repo.load_archive)
			.build()
		)

	# Queue 3: Update modal when archive loaded
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Modal: Archive loaded")
		.condition(func(): return Repo.get_child_count() != 0)
		.task(func(): LoadingModal.show_status("Caching audio assets..."))
		.build()
	)

	# Queue 4: Cache audio assets
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Cache audio assets")
		.condition(func(): return Repo.get_child_count() != 0)
		.task(Cache.pack_audio)
		.build()
	)

	# Queue 5: Route to world scene
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Route to world scene")
		.condition(func(): return Repo.get_child_count() != 0)
		.task(func(): Route.to(Scene.world))
		.build()
	)

func _on_load_failure() -> void:
	LoadingModal.show_error("Failed to load campaign archive")
