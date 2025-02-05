extends AudioStreamPlayer2D
class_name AudioStreamFader2D

const TRANSITION_TIME: float = 1.1
const FADE_IN_DB: int = 0
const FADE_OUT_DB: int = -80
const SCALE_EXPRESSION_NORMAL: float = 100.0

var scale_expression: String

func _ready() -> void:
	finished.connect(_on_finished)
	_calculate_scale()
	
func set_scale_expression(value: String) -> void:
	scale_expression = value

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

func _on_finished() -> void:
	_calculate_scale()

func _calculate_scale() -> void:
	if scale_expression != "":
		var result: float = Dice.builder().expression(scale_expression).build().evaluate() / SCALE_EXPRESSION_NORMAL
		set_pitch_scale(result)
		
func play_if_not_playing() -> void:
	if !playing: 
		play()
	
