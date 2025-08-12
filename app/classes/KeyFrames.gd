extends Object
class_name KeyFrames
## Class defining what animation keyframes are available

const IDLE: String = "idle"
const WALK: String = "walk"
const RUN: String = "run"
const DEAD: String = "dead"

static func list() -> Array[String]:
	return [
		IDLE,
		WALK, 
		RUN, 
		DEAD
	]

static func is_valid_animation(animation_name: String) -> bool:
	return animation_name in list() or animation_name != ""

static func get_base_animation_names() -> Array[String]:
	# Returns base animation names that should always be available
	return list()
