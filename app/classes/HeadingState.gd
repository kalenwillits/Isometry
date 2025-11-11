class_name HeadingState
extends RefCounted

## Abstract base class for heading state machine states.
## Defines the interface for updating actor heading based on current state.

func update_heading(actor: Actor, delta: float) -> String:
	push_error("HeadingState.update_heading() must be implemented by subclass")
	return "S"

func get_state_name() -> String:
	return "BaseState"
