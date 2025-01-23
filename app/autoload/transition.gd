extends CanvasLayer

const TRANSITION_TIME: float = 3.3
const RED: int = 0.5
const GREEN: int = 0.5
const BLUE: int = 0.5

enum State {
	IS_FADING,
	IS_APPEARING
}

var state: State = State.IS_APPEARING
var is_idle: bool = true

var fade_queue: Array = []
var appear_queue: Array = []

func _ready() -> void:
	$Timer.wait_time = TRANSITION_TIME
	$VBoxContainer/HBoxContainer/DarkScreen.color = Color(RED, GREEN, BLUE)
	visible = true

func _process(_delta: float) -> void:
	if $Timer.time_left:
		match state:
			State.IS_FADING:
				adjust_alpha_color(1.0 - ($Timer.time_left / TRANSITION_TIME))
			State.IS_APPEARING:
				adjust_alpha_color(($Timer.time_left / TRANSITION_TIME))

func at_next_fade(callable: Callable) -> void:
	fade_queue.append(callable)
	
func at_next_appear(callable: Callable) -> void:
	appear_queue.append(callable)

func fade() -> void:
	Queue.enqueue(
		Queue.Item.builder()
		.task(func():
				is_idle = false
				visible = true
				state = State.IS_FADING
				$Timer.start(TRANSITION_TIME)
				)
		.condition(func(): return is_idle)
		.build()
	)

	
func appear() -> void:
	Queue.enqueue(
		Queue.Item.builder()
		.task(func():
				is_idle = false
				visible = true
				state = State.IS_APPEARING
				$Timer.start(TRANSITION_TIME)
				)
		.condition(func(): return is_idle)
		.build()
	)

	
func adjust_alpha_color(alpha: float) -> void:
	$VBoxContainer/HBoxContainer/DarkScreen.modulate = Color(RED, GREEN, BLUE, alpha)
	
func exec_queue() -> void:
	match state:
		State.IS_FADING:
			while fade_queue:
				Queue.enqueue(
					Queue.Item.builder()
					.task(fade_queue.pop_front())
					.build()
				)
		State.IS_APPEARING:
			while appear_queue:
				Queue.enqueue(
					Queue.Item.builder()
					.task(appear_queue.pop_front())
					.build()
				)

func _on_timer_timeout() -> void:
	is_idle = true
	match state:
		State.IS_FADING:
			visible = true
			exec_queue()
		State.IS_APPEARING:
			visible = false
			exec_queue()
