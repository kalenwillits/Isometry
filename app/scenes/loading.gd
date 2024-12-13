extends Node

func _ready() -> void:
	handle_load_archive()
	
func handle_load_archive() -> void:
	if Repo.get_child_count() == 0:
		Repo.load_complete.connect(func(): Route.to(Scene.world))
		Queue.enqueue(
			Queue.Item.builder()
			.comment("Load from archive.")
			.task(Repo.load_archive)
			.build()
			)
