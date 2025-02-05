extends Object
class_name KeyFrames
## Class defining what animation keyframes are available

const IDLE: String = "idle"
const WALK: String = "walk"
const RUN: String = "run"
const DEAD: String = "dead"
const ACTION_1: String = "action_1"
const ACTION_2: String = "action_2"
const ACTION_3: String = "action_3"
const ACTION_4: String = "action_4"
const ACTION_5: String = "action_5"
const ACTION_6: String = "action_6"
const ACTION_7: String = "action_7"
const ACTION_8: String = "action_8"
const ACTION_9: String = "action_9"

static func list() -> Array[String]:
	return [
		IDLE,
		WALK, 
		RUN, 
		DEAD,
		ACTION_1, 
		ACTION_2, 
		ACTION_3, 
		ACTION_4, 
		ACTION_5, 
		ACTION_6, 
		ACTION_7, 
		ACTION_8, 
		ACTION_9
	]
