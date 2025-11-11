class_name HeadingStateMachine
extends RefCounted

## State machine that manages actor heading based on movement and camera state.
## Uses the State pattern to delegate heading calculation to state objects.

var current_state: HeadingState
var moving_state: MovingHeadingState
var stationary_locked_state: StationaryLockedHeadingState
var stationary_unlocked_state: StationaryUnlockedHeadingState

func _init() -> void:
	moving_state = MovingHeadingState.new()
	stationary_locked_state = StationaryLockedHeadingState.new()
	stationary_unlocked_state = StationaryUnlockedHeadingState.new()
	current_state = moving_state  # Default to moving state

## Update heading and handle state transitions based on actor state
func update(actor: Actor, delta: float) -> String:
	# Determine if actor is moving
	var is_moving: bool = actor.velocity.length_squared() > 0.01  # Small threshold to avoid float issues

	# Get camera lock state
	var camera_locked: bool = Finder.select(Group.CAMERA).is_locked()

	# Handle state transitions
	if is_moving:
		# Moving state regardless of camera lock
		if current_state != moving_state:
			transition_to(moving_state)
	else:
		# Stationary - determine state based on camera lock
		if camera_locked:
			if current_state != stationary_locked_state:
				transition_to(stationary_locked_state)
		else:
			if current_state != stationary_unlocked_state:
				# Freeze the current heading when transitioning to unlocked
				stationary_unlocked_state.freeze(actor.heading)
				transition_to(stationary_unlocked_state)

	# Delegate heading calculation to current state
	return current_state.update_heading(actor, delta)

## Transition to a new state
func transition_to(new_state: HeadingState) -> void:
	current_state = new_state

func get_current_state_name() -> String:
	return current_state.get_state_name()

## Builder pattern for constructing HeadingStateMachine
class Builder extends Object:
	var _machine: HeadingStateMachine

	func _init() -> void:
		_machine = HeadingStateMachine.new()

	func with_initial_state(state: HeadingState) -> Builder:
		_machine.current_state = state
		return self

	func build() -> HeadingStateMachine:
		return _machine

static func builder() -> Builder:
	return Builder.new()
