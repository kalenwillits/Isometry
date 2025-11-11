class_name ManualInputBearingState
extends BearingState

## Bearing state for manual input control.
## Handles both WASD/right-stick bearing input and mouse cursor tracking.

var last_mouse_position: Vector2 = Vector2.ZERO
var mouse_movement_threshold: float = 5.0  # Pixels moved to trigger cursor bearing

func on_enter(actor: Actor) -> void:
	# Initialize mouse tracking
	last_mouse_position = actor.get_global_mouse_position()

func update_bearing(actor: Actor, delta: float) -> int:
	# Block input if camera not locked or UI blocking
	if !Finder.select(Group.CAMERA).is_locked():
		return actor.bearing

	if UIStateMachine.should_block_player_input():
		actor.is_bearing_mode_active = false
		actor.bearing_vector = Vector2.ZERO
		return actor.bearing

	# Check for bearing input (WASD/right-stick)
	var bearing_input = Keybinds.get_vector(
		Keybinds.BEARING_LEFT,
		Keybinds.BEARING_RIGHT,
		Keybinds.BEARING_UP,
		Keybinds.BEARING_DOWN
	)

	# Handle bearing input
	if bearing_input.length() > 0.01:  # Small deadzone for analog sticks
		actor.is_bearing_mode_active = true

		# Normalize the input direction and calculate bearing
		var direction = bearing_input.normalized()
		var target_position = actor.position + direction

		# Apply isometric adjustment for bearing_vector (used by camera)
		var raw_angle = direction.angle()
		var isometric_adjustment = std.isometric_factor(raw_angle)

		# Cache the bearing vector with isometric adjustment for movement
		actor.bearing_vector = direction
		actor.bearing_vector.y *= isometric_adjustment
		actor.bearing_vector = actor.bearing_vector.normalized()

		# Calculate and return the bearing
		return std.calculate_bearing(target_position, actor.position)
	else:
		actor.is_bearing_mode_active = false

	# Check for mouse cursor movement (if not in direct movement mode)
	if !actor.is_direct_movement_active:
		var current_mouse_position = actor.get_global_mouse_position()
		var mouse_delta = current_mouse_position.distance_to(last_mouse_position)

		if mouse_delta > mouse_movement_threshold:
			# Mouse moved significantly - update bearing to cursor
			last_mouse_position = current_mouse_position

			# Calculate direction from actor to mouse cursor
			var direction = actor.position.direction_to(current_mouse_position)
			var raw_angle = direction.angle()
			var isometric_adjustment = std.isometric_factor(raw_angle)

			# Cache the bearing vector with isometric adjustment for movement
			actor.bearing_vector = direction
			actor.bearing_vector.y *= isometric_adjustment
			actor.bearing_vector = actor.bearing_vector.normalized()

			# Use centralized bearing calculation
			return std.calculate_bearing(current_mouse_position, actor.position)

	# No manual input detected, keep current bearing
	return actor.bearing

func get_state_name() -> String:
	return "ManualInput"
