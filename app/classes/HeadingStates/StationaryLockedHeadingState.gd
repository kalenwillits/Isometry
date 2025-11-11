class_name StationaryLockedHeadingState
extends HeadingState

## Heading state for when the actor is stationary and camera is locked.
## Heading syncs to the bearing radial immediately when bearing input is received.

func update_heading(actor: Actor, delta: float) -> String:
	# If bearing vector exists and has magnitude, sync heading to bearing radial
	if actor.bearing_vector.length_squared() > 0:
		# Add PI to reverse direction to match original backwards convention
		return actor.map_radial(actor.bearing_vector.angle() + PI)

	# Otherwise maintain current heading
	return actor.heading

func get_state_name() -> String:
	return "StationaryLocked"
