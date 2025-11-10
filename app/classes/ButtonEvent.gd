extends Object
class_name ButtonEvent

enum State {
	JUST_PRESSED,
	HELD,
	RELEASED
}

var button_key: String = ""
var state: State = State.JUST_PRESSED

class Builder extends Object:
	var this: ButtonEvent = ButtonEvent.new()

	func button_key(value: String) -> Builder:
		this.button_key = value
		return self

	func state(value: State) -> Builder:
		this.state = value
		return self

	func build() -> ButtonEvent:
		return this

static func builder() -> Builder:
	return Builder.new()

func get_button_key() -> String:
	return button_key

func get_state() -> State:
	return state

func is_just_pressed() -> bool:
	return state == State.JUST_PRESSED

func is_held() -> bool:
	return state == State.HELD

func is_released() -> bool:
	return state == State.RELEASED
