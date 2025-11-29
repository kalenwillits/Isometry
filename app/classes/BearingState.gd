class_name BearingState
extends RefCounted

## Abstract base class for bearing state machine states.
## Defines the interface for updating actor bearing based on current state.

func update_bearing(_actor: Actor, _delta: float) -> int:
	push_error("BearingState.update_bearing() must be implemented by subclass")
	return 0

func on_enter(_actor: Actor) -> void:
	pass  # Optional: override in subclasses for entry logic

func on_exit(_actor: Actor) -> void:
	pass  # Optional: override in subclasses for cleanup

func get_state_name() -> String:
	return "BaseState"
