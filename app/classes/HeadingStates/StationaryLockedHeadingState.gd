class_name StationaryLockedHeadingState
extends HeadingState

## Heading state for when the actor is stationary and camera is locked.
## Heading maintains the last direction from movement (decoupled from bearing).

func update_heading(actor: Actor, delta: float) -> String:
	# Maintain current heading when stationary (bearing controls camera, not heading)
	return actor.heading

func get_state_name() -> String:
	return "StationaryLocked"
