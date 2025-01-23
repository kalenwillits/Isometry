extends Timer
class_name Fader

const TRANSITION_TIME: float = 1.1
const RED: int = 1.0
const GREEN: int = 1.0
const BLUE: int = 1.0

enum State {
	IS_FADING,
	IS_APPEARING
}

var target: Node
var state: State = State.IS_APPEARING
var is_idle: bool = true

class Builder extends Object:
	var this: Fader = Fader.new()
	
	func target(value: Node) -> Builder:
		this.target = value
		return self

	func build() -> Fader:
		assert(this.target != null)
		this.name = "Fader"
		return this
		
static func builder() -> Builder:
	return Builder.new()
	
func deploy(node: Node) -> void:
	node.add_child(self)

var fade_queue: Array = []
var appear_queue: Array = []

func _ready() -> void:
	one_shot = true
	autostart = false
	timeout.connect(_on_timeout)
	wait_time = TRANSITION_TIME

func _process(_delta: float) -> void:
	if time_left:
		match state:
			State.IS_FADING:
				adjust_alpha_color(1.0 - (time_left / TRANSITION_TIME))
			State.IS_APPEARING:
				adjust_alpha_color((time_left / TRANSITION_TIME))

func at_next_fade(callable: Callable) -> void:
	fade_queue.append(callable)
	
func at_next_appear(callable: Callable) -> void:
	appear_queue.append(callable)

func fade() -> void:
	Queue.enqueue(
		Queue.Item.builder()
		.target(self)
		.comment("Fader.fade")
		.task(fade_now)
		.condition(func(): return is_inside_tree())
		.build()
	)

func fade_now() -> void:
	set_process(true)
	is_idle = false
	state = State.IS_FADING
	start.call_deferred(TRANSITION_TIME)
	
func appear() -> void:
	Queue.enqueue(
		Queue.Item.builder()
		.comment("Fader.appear")
		.target(self)
		.task(appear_now)
		.condition(func(): return is_inside_tree())
		.build()
	)
	
func appear_now() -> void:
	set_process(true)
	is_idle = false
	state = State.IS_APPEARING
	start.call_deferred(TRANSITION_TIME)

	
func adjust_alpha_color(delta: float) -> void:
	var current_a: float = target.modulate.a
	var diff = current_a - (current_a - delta)
	target.modulate = Color(diff, diff, diff, diff)

func exec_queue() -> void:
	match state:
		State.IS_FADING:
			while fade_queue:
				Queue.enqueue(
					Queue.Item.builder()
					.comment("Fader.exec_queue when state=IS_FADING")
					.task(fade_queue.pop_front())
					.build()
				)
		State.IS_APPEARING:
			while appear_queue:
				Queue.enqueue(
					Queue.Item.builder()
					.comment("Fader.exec_queue when state=IS_APPEARING")
					.task(appear_queue.pop_front())
					.build()
				)

func _on_timeout() -> void:
	set_process(false)
	is_idle = true
	match state:
		State.IS_FADING:
			exec_queue()
		State.IS_APPEARING:
			exec_queue()
