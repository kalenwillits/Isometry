extends Node

## UI State Machine
## Manages all UI states and prevents input conflicts
## Responds to actions (cancel, open_menu, toggle_map_view) not keys

enum State {
	GAMEPLAY,
	CHAT_ACTIVE,
	MENU_GLOBAL,
	MENU_SYSTEM,
	MENU_RESOURCES,
	MENU_SKILLS,
	MENU_OPTIONS,
	MENU_KEYBINDS,
	MENU_GAMEPAD,
	MENU_MAP,
	CONTEXT_MENU,
	PLATE_VIEW,
	CONFIRMATION_MODAL,
	AREA_TARGETING
}

var current_state: State = State.GAMEPLAY
var previous_state: State = State.GAMEPLAY
var map_opened_from_gameplay: bool = false  # Track how MENU_MAP was opened
var resources_opened_from_gameplay: bool = false  # Track how MENU_RESOURCES was opened
var skills_opened_from_gameplay: bool = false  # Track how MENU_SKILLS was opened
var context_menu_opened_from: State = State.GAMEPLAY  # Track where CONTEXT_MENU was opened from

signal state_changed(old_state: State, new_state: State)

## Main transition method
func transition_to(new_state: State) -> void:
	if current_state == new_state:
		return  # Already in this state

	var old_state = current_state
	previous_state = current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)

## Query: Should player input be blocked?
func should_block_player_input() -> bool:
	return current_state != State.GAMEPLAY and current_state != State.AREA_TARGETING

## Handle cancel action (context-aware)
func handle_cancel() -> void:
	match current_state:
		State.GAMEPLAY:
			# In gameplay, cancel clears target (handled in actor.gd)
			pass

		State.CHAT_ACTIVE:
			# Cancel chat input, return to gameplay
			transition_to(State.GAMEPLAY)

		State.MENU_GLOBAL:
			# Close global menu
			transition_to(State.GAMEPLAY)

		State.MENU_SYSTEM:
			# Back to global menu
			transition_to(State.MENU_GLOBAL)

		State.MENU_RESOURCES:
			# Return based on how it was opened
			if resources_opened_from_gameplay:
				transition_to(State.GAMEPLAY)
			else:
				transition_to(State.MENU_GLOBAL)

		State.MENU_SKILLS:
			# Return based on how it was opened
			if skills_opened_from_gameplay:
				transition_to(State.GAMEPLAY)
			else:
				transition_to(State.MENU_GLOBAL)

		State.MENU_OPTIONS:
			# Back to system menu
			transition_to(State.MENU_SYSTEM)

		State.MENU_KEYBINDS:
			# Back to system menu
			transition_to(State.MENU_SYSTEM)

		State.MENU_GAMEPAD:
			# Back to system menu
			transition_to(State.MENU_SYSTEM)

		State.MENU_MAP:
			# Return based on how it was opened
			if map_opened_from_gameplay:
				transition_to(State.GAMEPLAY)
			else:
				transition_to(State.MENU_GLOBAL)

		State.CONTEXT_MENU:
			# Close context menu, return to where it was opened from
			transition_to(context_menu_opened_from)

		State.PLATE_VIEW:
			# Close plate view
			transition_to(State.GAMEPLAY)

		State.CONFIRMATION_MODAL:
			# Return to previous state
			transition_to(previous_state)

## Handle open_menu action (toggle global menu)
func handle_open_menu() -> void:
	match current_state:
		State.GAMEPLAY:
			# Open global menu
			transition_to(State.MENU_GLOBAL)

		State.MENU_GLOBAL:
			# Toggle close
			transition_to(State.GAMEPLAY)

		_:
			# Blocked in all other states
			print("[UIStateMachine] open_menu action blocked in state: ", State.keys()[current_state])

## Handle toggle_map_view action (only works from GAMEPLAY)
func handle_toggle_map() -> void:
	match current_state:
		State.GAMEPLAY:
			# Open map via toggle
			map_opened_from_gameplay = true
			transition_to(State.MENU_MAP)

		State.MENU_MAP:
			# Close map if it was opened via toggle
			if map_opened_from_gameplay:
				transition_to(State.GAMEPLAY)

		_:
			# Blocked in all other states
			print("[UIStateMachine] toggle_map_view action blocked in state: ", State.keys()[current_state])

## Transition to map from menu (not toggle)
func open_map_from_menu() -> void:
	map_opened_from_gameplay = false
	transition_to(State.MENU_MAP)

## Handle toggle_resources_view action (only works from GAMEPLAY)
func handle_toggle_resources() -> void:
	match current_state:
		State.GAMEPLAY:
			# Open resources via toggle
			resources_opened_from_gameplay = true
			transition_to(State.MENU_RESOURCES)

		State.MENU_RESOURCES:
			# Close resources if it was opened via toggle
			if resources_opened_from_gameplay:
				transition_to(State.GAMEPLAY)

		_:
			# Blocked in all other states
			print("[UIStateMachine] toggle_resources_view action blocked in state: ", State.keys()[current_state])

## Transition to resources from menu (not toggle)
func open_resources_from_menu() -> void:
	resources_opened_from_gameplay = false
	transition_to(State.MENU_RESOURCES)

## Transition to skills from menu
func open_skills_from_menu() -> void:
	skills_opened_from_gameplay = false
	transition_to(State.MENU_SKILLS)

## Handle toggle_skills_view action (only works from GAMEPLAY)
func handle_toggle_skills() -> void:
	match current_state:
		State.GAMEPLAY:
			# Open skills via toggle
			skills_opened_from_gameplay = true
			transition_to(State.MENU_SKILLS)

		State.MENU_SKILLS:
			# Close skills if it was opened via toggle
			if skills_opened_from_gameplay:
				transition_to(State.GAMEPLAY)

		_:
			# Blocked in all other states
			print("[UIStateMachine] toggle_skills_view action blocked in state: ", State.keys()[current_state])

## Open context menu from current state
func open_context_menu() -> void:
	context_menu_opened_from = current_state
	transition_to(State.CONTEXT_MENU)

## Close context menu and return to where it was opened from
func close_context_menu() -> void:
	transition_to(context_menu_opened_from)

## Get state name for debugging
func get_state_name() -> String:
	return State.keys()[current_state]
