class_name MovingHeadingState
extends HeadingState

## Heading state for when the actor is moving.
## Heading syncs to the direction of movement (velocity angle).

func update_heading(actor: Actor, delta: float) -> String:
	if actor.velocity.length_squared() > 0:
		# Add PI to reverse direction to match original backwards convention
		return actor.map_radial(actor.velocity.angle() + PI)
	return actor.heading  # Fallback to current heading if somehow velocity is 0

func get_state_name() -> String:
	return "Moving"
