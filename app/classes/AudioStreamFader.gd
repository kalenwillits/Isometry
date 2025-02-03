extends AudioStreamPlayer
class_name AudioStreamFader

const TRANSITION_TIME: float = 1.1
const FADE_IN_DB: int = 0
const FADE_OUT_DB: int = -80

func fade_in() -> void:
	playing = true
	create_tween().tween_property(self, "volume_db", FADE_IN_DB, TRANSITION_TIME)

func fade_out() -> void:
	create_tween().tween_property(self, "volume_db", FADE_OUT_DB, TRANSITION_TIME)
	Queue.enqueue(
		Queue.Item.builder()
		.task(func(): playing = false)
		.condition(func(): return self.volume_db <= FADE_OUT_DB)
		.build()
	)
