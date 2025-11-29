class_name StationaryUnlockedHeadingState
extends HeadingState

## Heading state for when the actor is stationary and camera is unlocked.
## Heading freezes at the current value and does not update.

var frozen_heading: String = "S"

func update_heading(_actor: Actor, _delta: float) -> String:
	# Return the frozen heading value
	return frozen_heading

func freeze(heading: String) -> void:
	frozen_heading = heading

func get_state_name() -> String:
	return "StationaryUnlocked"
