class_name MovementBearingState
extends BearingState

## Bearing state for when the actor is moving.
## Bearing follows the direction of movement (velocity angle).

func update_bearing(actor: Actor, delta: float) -> int:
	if actor.velocity.length_squared() > 0.01:
		# Calculate target position from velocity direction
		var velocity_direction = actor.velocity.normalized()
		var target_position = actor.position + velocity_direction

		# Use centralized bearing calculation with isometric adjustment
		return std.calculate_bearing(target_position, actor.position)

	# Fallback to current bearing if somehow velocity is 0
	return actor.bearing

func get_state_name() -> String:
	return "Movement"
