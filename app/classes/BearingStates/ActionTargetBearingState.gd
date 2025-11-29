class_name ActionTargetBearingState
extends BearingState

## Bearing state for when an action was just used on a target.
## Continuously tracks the target actor's position until state exits.

var target_actor: Actor = null

func set_target(actor: Actor) -> void:
	target_actor = actor

func on_enter(_actor: Actor) -> void:
	# Target should be set before entering this state
	if target_actor == null:
		push_warning("ActionTargetBearingState entered without a target actor")

func on_exit(_actor: Actor) -> void:
	target_actor = null  # Clear reference

func update_bearing(actor: Actor, _delta: float) -> int:
	# Continuously track target if it exists and is valid
	if target_actor != null and is_instance_valid(target_actor):
		# Calculate bearing to target's current position
		return std.calculate_bearing(target_actor.position, actor.position)

	# Target invalid or lost, keep current bearing
	return actor.bearing

func has_valid_target() -> bool:
	return target_actor != null and is_instance_valid(target_actor)

func get_state_name() -> String:
	return "ActionTarget"
