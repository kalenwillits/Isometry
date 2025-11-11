class_name BearingStateMachine
extends RefCounted

## State machine that manages actor bearing based on movement, input, and actions.
## Uses the State pattern to delegate bearing calculation to state objects.
##
## State Priority: ActionTarget > ManualInput > Movement
## - ActionTarget: Locks bearing to action target until manual input or movement
## - ManualInput: Manual WASD/cursor control
## - Movement: Bearing follows velocity direction

var current_state: BearingState
var movement_state: MovementBearingState
var manual_input_state: ManualInputBearingState
var action_target_state: ActionTargetBearingState

func _init() -> void:
	movement_state = MovementBearingState.new()
	manual_input_state = ManualInputBearingState.new()
	action_target_state = ActionTargetBearingState.new()
	current_state = movement_state  # Default to movement state

## Update bearing and handle state transitions based on actor state
func update(actor: Actor, delta: float) -> int:
	# State priority: ActionTarget > ManualInput > Movement

	# Check if we should stay in or enter ActionTarget state
	if current_state == action_target_state and action_target_state.has_valid_target():
		# Check exit conditions: manual bearing input or movement started
		if _has_manual_bearing_input(actor) or _has_movement_started(actor):
			transition_to(actor, _get_highest_priority_state(actor))
		# else: stay in action target state
	# Check if we should enter ManualInput state
	elif _has_manual_bearing_input(actor):
		if current_state != manual_input_state:
			transition_to(actor, manual_input_state)
	# Check if we should enter Movement state
	elif _is_actor_moving(actor):
		if current_state != movement_state:
			transition_to(actor, movement_state)
	# Else stay in current state

	# Delegate bearing calculation to current state
	return current_state.update_bearing(actor, delta)

## Called when an action is used on a target actor
func on_action_targeted(actor: Actor, target: Actor) -> void:
	if target != null and is_instance_valid(target):
		action_target_state.set_target(target)
		transition_to(actor, action_target_state)

## Transition to a new state
func transition_to(actor: Actor, new_state: BearingState) -> void:
	if current_state != new_state:
		current_state.on_exit(actor)
		current_state = new_state
		current_state.on_enter(actor)

func get_current_state_name() -> String:
	return current_state.get_state_name()

## Helper: Check if actor has manual bearing input active
func _has_manual_bearing_input(actor: Actor) -> bool:
	# Check for bearing input (WASD/right-stick)
	if !Finder.select(Group.CAMERA).is_locked():
		return false

	if UIStateMachine.should_block_player_input():
		return false

	var bearing_input = Keybinds.get_vector(
		Keybinds.BEARING_LEFT,
		Keybinds.BEARING_RIGHT,
		Keybinds.BEARING_UP,
		Keybinds.BEARING_DOWN
	)

	return bearing_input.length() > 0.01

## Helper: Check if actor is moving
func _is_actor_moving(actor: Actor) -> bool:
	return actor.velocity.length_squared() > 0.01

## Helper: Check if movement just started (for exiting ActionTarget state)
func _has_movement_started(actor: Actor) -> bool:
	return _is_actor_moving(actor)

## Helper: Get the highest priority state based on current conditions
func _get_highest_priority_state(actor: Actor) -> BearingState:
	if _has_manual_bearing_input(actor):
		return manual_input_state
	elif _is_actor_moving(actor):
		return movement_state
	else:
		return current_state  # Stay in current state

## Builder pattern for constructing BearingStateMachine
class Builder extends Object:
	var _machine: BearingStateMachine

	func _init() -> void:
		_machine = BearingStateMachine.new()

	func with_initial_state(state: BearingState) -> Builder:
		_machine.current_state = state
		return self

	func build() -> BearingStateMachine:
		return _machine

static func builder() -> Builder:
	return Builder.new()
