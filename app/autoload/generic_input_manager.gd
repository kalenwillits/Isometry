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


func _ready() -> void:
	initialize()


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


func assign_action(action_name: String, input_events: Array) -> bool:
	"""
	Assigns an array of InputEvents to a logical action name.
	For single inputs, allocates 1 generic ID.
	For combos (A+B+C), allocates multiple IDs in order.

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


func is_action_pressed(action_name: String) -> bool:
	"""
	Checks if all inputs for an action are currently pressed (held).
	For composite inputs (A+B+C), all must be pressed.
	"""
	var generic_ids = get_action_generic_ids(action_name)
	if generic_ids.is_empty():
		return false

	for generic_id in generic_ids:
		if not Input.is_action_pressed(generic_id):
			return false

	return true


func is_action_just_pressed(action_name: String) -> bool:
	"""
	Checks if an action was just triggered this frame.
	For single inputs, checks if it was just pressed.
	For composite inputs (A+B+C):
	  - All buttons except the last must be pressed (held)
	  - The last button must be just_pressed this frame
	"""
	var generic_ids = get_action_generic_ids(action_name)
	if generic_ids.is_empty():
		return false

	if generic_ids.size() == 1:
		# Single input: just check if it was just pressed
		return Input.is_action_just_pressed(generic_ids[0])
	else:
		# Composite input: all but last must be held, last must be just_pressed
		for i in range(generic_ids.size() - 1):
			if not Input.is_action_pressed(generic_ids[i]):
				return false

		# Check if the last button was just pressed
		return Input.is_action_just_pressed(generic_ids[-1])


func is_action_just_released(action_name: String) -> bool:
	"""
	Checks if an action was just released this frame.
	For composite inputs, checks if ANY of the buttons was just released
	(since releasing any button in a combo breaks the combo).
	"""
	var generic_ids = get_action_generic_ids(action_name)
	if generic_ids.is_empty():
		return false

	if generic_ids.size() == 1:
		# Single input: check if it was just released
		return Input.is_action_just_released(generic_ids[0])
	else:
		# Composite input: if any button was just released, the combo is broken
		for generic_id in generic_ids:
			if Input.is_action_just_released(generic_id):
				return true
		return false


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
