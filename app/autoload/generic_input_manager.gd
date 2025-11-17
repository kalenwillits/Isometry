extends Node

# Generic Input Manager
#
# This system manages a pool of 1000 generic input actions ("000"-"999") registered
# with Godot's InputMap. It tracks which generic IDs map to physical inputs (keys/buttons)
# and which logical actions they represent, enabling true multi-button combo support.

const GENERIC_ID_COUNT = 1000

# Maps generic ID (String) -> InputEvent (the physical input)
var generic_to_input: Dictionary = {}

# Maps logical action name (String) -> Array of generic IDs (Array[String])
# Example: "move_up" -> ["042"] or "zoom_in" -> ["015", "016", "017"]
var action_to_generics: Dictionary = {}

# Maps generic ID (String) -> logical action name (String)
# Reverse lookup for cleanup
var generic_to_action: Dictionary = {}

# Pool of available generic IDs
var available_ids: Array = []

# Whether the system has been initialized
var initialized: bool = false

# State machine for action button inputs (handles priority)
var state_machine: InputStateMachine = null

# Frame-based caching to prevent multiple state machine updates per frame
var cached_frame: int = -1
var cached_triggered_action: String = ""
var cached_held_actions: Dictionary = {}  # action_name -> bool
var cached_released_actions: Dictionary = {}  # action_name -> bool


func _ready() -> void:
	initialize()


func _physics_process(_delta: float) -> void:
	"""
	Updates the state machine once per frame and caches results.
	This prevents the multi-update bug where checking multiple actions
	would cause the state machine to update 27+ times per frame.
	"""
	var current_frame = Engine.get_process_frames()

	# Only update if we're on a new frame
	if current_frame != cached_frame:
		cached_frame = current_frame

		# Debug logging on first frame only
		if current_frame == 1:
			print("[GenericInputManager] First frame - %d actions registered: %s" % [action_to_generics.size(), action_to_generics.keys()])

		# Collect button events for this frame
		var button_events = _collect_button_events_from_generic_ids()

		# Update state machine ONCE per frame
		state_machine.update(button_events)

		# Cache the triggered action
		cached_triggered_action = state_machine.get_triggered_action()

		# Debug when an action triggers
		if cached_triggered_action != "":
			print("[GenericInputManager] Frame %d: Action triggered = %s" % [current_frame, cached_triggered_action])

		# Cache which actions are currently held
		cached_held_actions.clear()
		for action_name in action_to_generics:
			var generic_ids = action_to_generics[action_name]
			var all_pressed = true
			for generic_id in generic_ids:
				if not Input.is_action_pressed(generic_id):
					all_pressed = false
					break
			cached_held_actions[action_name] = all_pressed

		# Cache which actions were just released
		cached_released_actions.clear()
		for action_name in action_to_generics:
			var generic_ids = action_to_generics[action_name]
			var just_released = false
			if generic_ids.size() == 1:
				# Single input: check if it was just released
				just_released = Input.is_action_just_released(generic_ids[0])
			else:
				# Composite input: if any button was just released, the combo is broken
				for generic_id in generic_ids:
					if Input.is_action_just_released(generic_id):
						just_released = true
						break
			cached_released_actions[action_name] = just_released


func initialize() -> void:
	if initialized:
		return

	print("GenericInputManager: Initializing %d generic input actions..." % GENERIC_ID_COUNT)

	# Register all generic actions in InputMap
	for i in range(GENERIC_ID_COUNT):
		var generic_id = "%03d" % i  # "000", "001", ..., "999"

		# Add action to InputMap if it doesn't exist
		if not InputMap.has_action(generic_id):
			InputMap.add_action(generic_id)

		# Add to available pool
		available_ids.append(generic_id)

	# Initialize state machine
	state_machine = InputStateMachine.builder().build()

	initialized = true
	print("GenericInputManager: Initialization complete. %d IDs available." % available_ids.size())


func allocate_ids(count: int) -> Array:
	"""
	Allocates a specified number of generic IDs from the pool.
	Returns an Array of generic ID strings, or empty array if not enough available.
	"""
	if available_ids.size() < count:
		push_error("GenericInputManager: Not enough generic IDs available. Requested: %d, Available: %d" % [count, available_ids.size()])
		return []

	var allocated = []
	for i in range(count):
		allocated.append(available_ids.pop_front())

	return allocated


func free_ids(ids: Array) -> void:
	"""
	Returns generic IDs back to the available pool.
	"""
	for generic_id in ids:
		if generic_id in generic_to_input:
			# Clear the InputMap binding
			InputMap.action_erase_events(generic_id)
			generic_to_input.erase(generic_id)

		if generic_id in generic_to_action:
			generic_to_action.erase(generic_id)

		# Return to pool if not already there
		if generic_id not in available_ids:
			available_ids.append(generic_id)


func assign_action(action_name: String, input_events: Array, skip_rebuild: bool = false) -> bool:
	"""
	Assigns an array of InputEvents to a logical action name.
	For single inputs, allocates 1 generic ID.
	For combos (A+B+C), allocates multiple IDs in order.

	Set skip_rebuild=true when bulk-loading actions to avoid rebuilding the state machine multiple times.
	Call rebuild_state_machine() manually after all actions are loaded.

	Returns true on success, false on failure.
	"""
	# First, clear any existing assignment
	unassign_action(action_name)

	# Allocate generic IDs
	var generic_ids = allocate_ids(input_events.size())
	if generic_ids.is_empty():
		return false

	# Map each generic ID to its input event
	for i in range(input_events.size()):
		var generic_id = generic_ids[i]
		var input_event = input_events[i]

		# Clear any existing events on this generic action
		InputMap.action_erase_events(generic_id)

		# Add the input event to the generic action
		InputMap.action_add_event(generic_id, input_event)

		# Track the mapping
		generic_to_input[generic_id] = input_event
		generic_to_action[generic_id] = action_name

	# Store the action -> generic IDs mapping
	action_to_generics[action_name] = generic_ids

	# Rebuild state machine to clear any stale paths from previous bindings
	# This ensures runtime binding changes work immediately
	# Skip during bulk loading for performance
	if not skip_rebuild:
		rebuild_state_machine()

	return true


func unassign_action(action_name: String) -> void:
	"""
	Removes all generic ID assignments for a logical action.
	Frees the generic IDs back to the pool.
	"""
	if action_name not in action_to_generics:
		return

	var generic_ids = action_to_generics[action_name]
	free_ids(generic_ids)
	action_to_generics.erase(action_name)


func unassign_keyboard_events(action_name: String) -> void:
	"""
	Removes only keyboard/mouse input events from an action.
	Preserves gamepad events. Re-assigns remaining events if any exist.
	"""
	if action_name not in action_to_generics:
		return

	# Get current input events for this action
	var current_events = get_action_input_events(action_name)

	# Filter out keyboard/mouse events, keep only gamepad events
	var gamepad_events = []
	for event in current_events:
		if _is_gamepad_event(event):
			gamepad_events.append(event)

	# Unassign all events
	unassign_action(action_name)

	# Re-assign gamepad events if any remain
	if gamepad_events.size() > 0:
		assign_action(action_name, gamepad_events)


func unassign_gamepad_events(action_name: String) -> void:
	"""
	Removes only gamepad input events from an action.
	Preserves keyboard/mouse events. Re-assigns remaining events if any exist.
	"""
	if action_name not in action_to_generics:
		return

	# Get current input events for this action
	var current_events = get_action_input_events(action_name)

	# Filter out gamepad events, keep only keyboard/mouse events
	var keyboard_events = []
	for event in current_events:
		if not _is_gamepad_event(event):
			keyboard_events.append(event)

	# Unassign all events
	unassign_action(action_name)

	# Re-assign keyboard events if any remain
	if keyboard_events.size() > 0:
		assign_action(action_name, keyboard_events)


func _is_gamepad_event(event: InputEvent) -> bool:
	"""
	Helper function to determine if an InputEvent is a gamepad event.
	Returns true for joypad buttons and axes, false for keyboard/mouse.
	"""
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


func get_action_generic_ids(action_name: String) -> Array:
	"""
	Returns the array of generic IDs assigned to an action.
	Returns empty array if action is not assigned.
	"""
	if action_name in action_to_generics:
		return action_to_generics[action_name]
	return []


func get_action_input_events(action_name: String) -> Array:
	"""
	Returns the array of InputEvents assigned to an action.
	Returns empty array if action is not assigned.
	"""
	var generic_ids = get_action_generic_ids(action_name)
	var events = []

	for generic_id in generic_ids:
		if generic_id in generic_to_input:
			events.append(generic_to_input[generic_id])

	return events


func get_generic_id_event(generic_id: String) -> InputEvent:
	"""
	Returns the InputEvent associated with a specific generic ID.
	Returns null if the generic ID is not assigned.
	"""
	if generic_id in generic_to_input:
		return generic_to_input[generic_id]
	return null


func is_action_pressed(action_name: String) -> bool:
	"""
	Checks if all inputs for an action are currently pressed (held).
	For composite inputs (A+B+C), all must be pressed.
	"""
	var generic_ids = get_action_generic_ids(action_name)
	if generic_ids.is_empty():
		return false

	# Use cached result from _process()
	return cached_held_actions.get(action_name, false)


func is_action_just_pressed(action_name: String, check_priority: bool = true) -> bool:
	"""
	Checks if an action was just triggered this frame.
	Uses state machine for priority-aware checking.

	With priority checking (default), longer combos prevent shorter ones from triggering.
	Set check_priority=false to bypass priority logic.
	"""
	var generic_ids = get_action_generic_ids(action_name)
	if generic_ids.is_empty():
		print("[GenericInputManager] is_action_just_pressed('%s'): NOT in action_to_generics, returning false" % action_name)
		return false

	# If priority checking is disabled, use raw check
	if not check_priority:
		return _check_action_just_pressed_raw(action_name)

	# Use cached result from _process() to prevent multiple state machine updates per frame
	var result = cached_triggered_action == action_name
	if result:
		print("[GenericInputManager] is_action_just_pressed('%s'): TRUE (cached_triggered_action='%s')" % [action_name, cached_triggered_action])
	return result


func is_action_just_released(action_name: String) -> bool:
	"""
	Checks if an action was just released this frame.
	For composite inputs, checks if ANY of the buttons was just released
	(since releasing any button in a combo breaks the combo).
	"""
	var generic_ids = get_action_generic_ids(action_name)
	if generic_ids.is_empty():
		return false

	# Use cached result from _process()
	return cached_released_actions.get(action_name, false)


func get_available_id_count() -> int:
	"""
	Returns the number of generic IDs still available in the pool.
	"""
	return available_ids.size()


func get_action_list() -> Array:
	"""
	Returns a list of all logical action names currently assigned.
	"""
	return action_to_generics.keys()


func clear_all_assignments() -> void:
	"""
	Clears all action assignments and returns all generic IDs to the pool.
	Useful for resetting the system or loading a new configuration.
	"""
	for action_name in action_to_generics.keys():
		unassign_action(action_name)


# ========================== Priority System ==========================


func _get_all_just_pressed_actions() -> Array:
	"""
	Returns a list of all actions that would be just_pressed this frame.
	Used for priority checking.
	"""
	var active_actions = []

	for action_name in action_to_generics.keys():
		if _check_action_just_pressed_raw(action_name):
			active_actions.append(action_name)

	return active_actions


func _check_action_just_pressed_raw(action_name: String) -> bool:
	"""
	Checks if an action is just_pressed WITHOUT priority logic.
	"""
	var generic_ids = get_action_generic_ids(action_name)
	if generic_ids.is_empty():
		return false

	if generic_ids.size() == 1:
		return Input.is_action_just_pressed(generic_ids[0])
	else:
		# Composite: all but last held, last just_pressed
		for i in range(generic_ids.size() - 1):
			if not Input.is_action_pressed(generic_ids[i]):
				return false
		return Input.is_action_just_pressed(generic_ids[-1])


func _get_consumed_ids_for_priority() -> Array:
	"""
	Determines which generic IDs are consumed by higher-priority (longer) combos.
	Returns an array of generic ID strings that should not trigger shorter actions.
	"""
	var active_actions = _get_all_just_pressed_actions()

	# Sort by combo length (longest first)
	active_actions.sort_custom(func(a, b):
		return get_action_generic_ids(a).size() > get_action_generic_ids(b).size()
	)

	var consumed_ids = []

	# Mark IDs as consumed in order of priority
	for action in active_actions:
		var ids = get_action_generic_ids(action)

		# Check if any of this action's IDs are already consumed
		var is_consumed = false
		for id in ids:
			if id in consumed_ids:
				is_consumed = true
				break

		if not is_consumed:
			# This action wins, consume its IDs
			consumed_ids.append_array(ids)

	return consumed_ids


# ========================== State Machine Helpers ==========================


func _event_to_button_key(event: InputEvent) -> String:
	"""
	Converts an InputEvent to a unique button key string.
	Used by the state machine to identify physical inputs.
	"""
	if event is InputEventJoypadButton:
		return "joy_btn_%d" % event.button_index
	elif event is InputEventJoypadMotion:
		return "joy_axis_%d_%d" % [event.axis, sign(event.axis_value)]
	elif event is InputEventKey:
		return "key_%d" % event.physical_keycode
	elif event is InputEventMouseButton:
		return "mouse_%d" % event.button_index
	return ""


func _collect_button_events_from_generic_ids() -> Array:
	"""
	Collects button events by checking all registered generic IDs.
	Returns an array of ButtonEvent objects.
	"""
	var events = []
	var seen_button_keys = []

	# Iterate through all generic IDs to find which buttons are active
	for generic_id in generic_to_input.keys():
		var input_event = generic_to_input[generic_id]
		var button_key = _event_to_button_key(input_event)

		if button_key == "" or button_key in seen_button_keys:
			continue

		seen_button_keys.append(button_key)

		# Determine the state of this button
		var state = ButtonEvent.State.HELD

		if Input.is_action_just_pressed(generic_id):
			state = ButtonEvent.State.JUST_PRESSED
		elif Input.is_action_just_released(generic_id):
			state = ButtonEvent.State.RELEASED
		elif Input.is_action_pressed(generic_id):
			state = ButtonEvent.State.HELD
		else:
			# Not pressed, skip
			continue

		events.append(ButtonEvent.builder()
			.button_key(button_key)
			.state(state)
			.build())

	return events


func rebuild_state_machine() -> void:
	"""
	Rebuilds the state machine from scratch with all current action bindings.
	This is necessary when bindings are changed at runtime to clear stale paths.
	"""
	# Create a fresh state machine
	state_machine = InputStateMachine.builder().build()

	# Re-register all current action bindings
	for action_name in action_to_generics:
		var input_events = get_action_input_events(action_name)

		# Build button keys for state machine registration
		var button_keys = []
		for input_event in input_events:
			var button_key = _event_to_button_key(input_event)
			if button_key != "":
				button_keys.append(button_key)

		# Register with the fresh state machine
		if button_keys.size() > 0:
			state_machine.register_binding(button_keys, action_name)
