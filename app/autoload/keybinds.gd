extends Node

# Signals
signal binding_changed(action_name: String, binding_type: String)
signal bindings_reset()

# Action name constants
const INTERACT: String = "set_destination"
const ACTION_1: String = "action_1"
const ACTION_2: String = "action_2"
const ACTION_3: String = "action_3"
const ACTION_4: String = "action_4"
const ACTION_5: String = "action_5"
const ACTION_6: String = "action_6"
const ACTION_7: String = "action_7"
const ACTION_8: String = "action_8"
const ACTION_9: String = "action_9"
const ZOOM_IN: String = "zoom_in"
const ZOOM_OUT: String = "zoom_out"
const CAMERA_LOCK: String = "camera_lock"
const CAMERA_RECENTER: String = "camera_recenter"
const OPEN_MENU: String = "open_menu"
const MOVE_UP: String = "move_up"
const MOVE_DOWN: String = "move_down"
const MOVE_LEFT: String = "move_left"
const MOVE_RIGHT: String = "move_right"
const BEARING_UP: String = "bearing_up"
const BEARING_DOWN: String = "bearing_down"
const BEARING_LEFT: String = "bearing_left"
const BEARING_RIGHT: String = "bearing_right"
const INCREMENT_TARGET: String = "increment_target"
const DECREMENT_TARGET: String = "decrement_target"
const INCREMENT_TARGET_GROUP: String = "increment_target_group"
const DECREMENT_TARGET_GROUP: String = "decrement_target_group"
const FOCUS_TOP_LEFT: String = "focus_top_left"
const FOCUS_TOP_RIGHT: String = "focus_top_right"
const FOCUS_BOT_LEFT: String = "focus_bot_left"
const FOCUS_BOT_RIGHT: String = "focus_bot_right"
const CLEAR_FOCUS_TOP_LEFT: String = "clear_focus_top_left"
const CLEAR_FOCUS_TOP_RIGHT: String = "clear_focus_top_right"
const CLEAR_FOCUS_BOT_LEFT: String = "clear_focus_bot_left"
const CLEAR_FOCUS_BOT_RIGHT: String = "clear_focus_bot_right"
const OPEN_SELECTION_MENU: String = "open_selection_menu"
const TOGGLE_MAP_VIEW: String = "toggle_map_view"
const TOGGLE_RESOURCES_VIEW: String = "toggle_resources_view"
const TOGGLE_SKILLS_VIEW: String = "toggle_skills_view"
const FOCUS_CHAT: String = "focus_chat"

# Config file settings
var CONFIG_FILE_PATH: String = io.get_dir() + "options.cfg"
const KEYBINDS_SECTION: String = "keybinds"
const GAMEPAD_SECTION: String = "gamepad"

# Default keybinds (keyboard/mouse)
const DEFAULT_KEYBINDS: Dictionary = {
	INTERACT: "mouse_right",
	ACTION_1: "q",
	ACTION_2: "w",
	ACTION_3: "e",
	ACTION_4: "r",
	ACTION_5: "t",
	ACTION_6: "y",
	ACTION_7: "u",
	ACTION_8: "i",
	ACTION_9: "o",
	ZOOM_IN: "page_up",
	ZOOM_OUT: "page_down",
	CAMERA_LOCK: "space",
	CAMERA_RECENTER: "space",
	OPEN_MENU: "home",
	MOVE_UP: "up_arrow",
	MOVE_DOWN: "down_arrow",
	MOVE_LEFT: "left_arrow",
	MOVE_RIGHT: "right_arrow",
	BEARING_UP: "w",
	BEARING_DOWN: "s",
	BEARING_LEFT: "a",
	BEARING_RIGHT: "d",
	INCREMENT_TARGET: "tab",
	DECREMENT_TARGET: "shift+tab",
	INCREMENT_TARGET_GROUP: "equal",
	DECREMENT_TARGET_GROUP: "minus",
	FOCUS_TOP_LEFT: "f1",
	FOCUS_TOP_RIGHT: "f2",
	FOCUS_BOT_LEFT: "f3",
	FOCUS_BOT_RIGHT: "f4",
	CLEAR_FOCUS_TOP_LEFT: "shift+f1",
	CLEAR_FOCUS_TOP_RIGHT: "shift+f2",
	CLEAR_FOCUS_BOT_LEFT: "shift+f3",
	CLEAR_FOCUS_BOT_RIGHT: "shift+f4",
	OPEN_SELECTION_MENU: "grave",
	TOGGLE_MAP_VIEW: "",
	TOGGLE_RESOURCES_VIEW: "",
	TOGGLE_SKILLS_VIEW: "",
	FOCUS_CHAT: "enter"
}

# Default gamepad bindings
const DEFAULT_GAMEPAD: Dictionary = {
	INTERACT: "b",
	ACTION_1: "a",
	ACTION_2: "x",
	ACTION_3: "y",
	ACTION_4: "left_shoulder",
	ACTION_5: "right_shoulder",
	ACTION_6: "dpad_up",
	ACTION_7: "dpad_down",
	ACTION_8: "dpad_left",
	ACTION_9: "dpad_right",
	ZOOM_IN: "right_shoulder",
	ZOOM_OUT: "left_shoulder",
	CAMERA_LOCK: "left_stick",
	CAMERA_RECENTER: "right_stick",
	OPEN_MENU: "start",
	MOVE_UP: "left_stick_up",
	MOVE_DOWN: "left_stick_down",
	MOVE_LEFT: "left_stick_left",
	MOVE_RIGHT: "left_stick_right",
	BEARING_UP: "right_stick_up",
	BEARING_DOWN: "right_stick_down",
	BEARING_LEFT: "right_stick_left",
	BEARING_RIGHT: "right_stick_right",
	INCREMENT_TARGET: "right_trigger",
	DECREMENT_TARGET: "left_trigger",
	INCREMENT_TARGET_GROUP: "dpad_right",
	DECREMENT_TARGET_GROUP: "dpad_left",
	FOCUS_TOP_LEFT: "dpad_up+left_shoulder",
	FOCUS_TOP_RIGHT: "dpad_up+right_shoulder",
	FOCUS_BOT_LEFT: "dpad_down+left_shoulder",
	FOCUS_BOT_RIGHT: "dpad_down+right_shoulder",
	CLEAR_FOCUS_TOP_LEFT: "dpad_up+dpad_left+left_shoulder",
	CLEAR_FOCUS_TOP_RIGHT: "dpad_up+dpad_right+right_shoulder",
	CLEAR_FOCUS_BOT_LEFT: "dpad_down+dpad_left+left_shoulder",
	CLEAR_FOCUS_BOT_RIGHT: "dpad_down+dpad_right+right_shoulder",
	OPEN_SELECTION_MENU: "",
	TOGGLE_MAP_VIEW: "",
	TOGGLE_RESOURCES_VIEW: "",
	TOGGLE_SKILLS_VIEW: "",
	FOCUS_CHAT: ""
}

# Display names for actions
const ACTION_LABELS: Dictionary = {
	INTERACT: "Set Destination",
	ACTION_1: "Action Slot 1",
	ACTION_2: "Action Slot 2",
	ACTION_3: "Action Slot 3",
	ACTION_4: "Action Slot 4",
	ACTION_5: "Action Slot 5",
	ACTION_6: "Action Slot 6",
	ACTION_7: "Action Slot 7",
	ACTION_8: "Action Slot 8",
	ACTION_9: "Action Slot 9",
	ZOOM_IN: "Zoom In",
	ZOOM_OUT: "Zoom Out",
	CAMERA_LOCK: "Camera Lock",
	CAMERA_RECENTER: "Camera Recenter",
	OPEN_MENU: "Global Menu",
	MOVE_UP: "Move Up",
	MOVE_DOWN: "Move Down",
	MOVE_LEFT: "Move Left",
	MOVE_RIGHT: "Move Right",
	BEARING_UP: "Bearing Up",
	BEARING_DOWN: "Bearing Down",
	BEARING_LEFT: "Bearing Left",
	BEARING_RIGHT: "Bearing Right",
	INCREMENT_TARGET: "Next Target",
	DECREMENT_TARGET: "Previous Target",
	INCREMENT_TARGET_GROUP: "Next Target Group",
	DECREMENT_TARGET_GROUP: "Previous Target Group",
	FOCUS_TOP_LEFT: "Focus North West",
	FOCUS_TOP_RIGHT: "Focus North East",
	FOCUS_BOT_LEFT: "Focus South West",
	FOCUS_BOT_RIGHT: "Focus South East",
	CLEAR_FOCUS_TOP_LEFT: "Clear Focus North West",
	CLEAR_FOCUS_TOP_RIGHT: "Clear Focus North East",
	CLEAR_FOCUS_BOT_LEFT: "Clear Focus South West",
	CLEAR_FOCUS_BOT_RIGHT: "Clear Focus South East",
	OPEN_SELECTION_MENU: "Open Selection Menu",
	TOGGLE_MAP_VIEW: "Toggle Map View",
	TOGGLE_RESOURCES_VIEW: "Toggle Resources View",
	TOGGLE_SKILLS_VIEW: "Toggle Skills View",
	FOCUS_CHAT: "Focus Chat"
}

func _init_actions() -> void:
	for action_name in DEFAULT_KEYBINDS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

func _ready() -> void:
	_init_actions()
	load_bindings()

# ========================== Generic Input API ==========================
# New API that uses the generic input system for true multi-button support

func is_action_pressed(action_name: String) -> bool:
	"""
	Checks if an action is currently pressed (held).
	Handles both single and multi-button combos via generic system.
	Falls back to traditional InputMap if action not in generic system.
	"""
	if GenericInputManager.get_action_generic_ids(action_name).size() > 0:
		return GenericInputManager.is_action_pressed(action_name)
	# Fallback to traditional InputMap
	return Input.is_action_pressed(action_name)

func is_action_just_pressed(action_name: String) -> bool:
	"""
	Checks if an action was just activated this frame.
	For combos (A+B+C): all but last must be held, last must be just_pressed.
	Falls back to traditional InputMap if action not in generic system.
	"""
	if GenericInputManager.get_action_generic_ids(action_name).size() > 0:
		return GenericInputManager.is_action_just_pressed(action_name)
	# Fallback to traditional InputMap
	return Input.is_action_just_pressed(action_name)

func is_action_just_released(action_name: String) -> bool:
	"""
	Checks if an action was just released this frame.
	For combos, true if any button was released (breaks the combo).
	Falls back to traditional InputMap if action not in generic system.
	"""
	if GenericInputManager.get_action_generic_ids(action_name).size() > 0:
		return GenericInputManager.is_action_just_released(action_name)
	# Fallback to traditional InputMap
	return Input.is_action_just_released(action_name)

func set_assignment(action_name: String, input_events: Array) -> bool:
	"""
	Assigns input events to an action using the generic input system.
	Supports single inputs and multi-button combos.

	Args:
		action_name: The logical action constant (e.g., Keybinds.MOVE_UP)
		input_events: Array of InputEvent objects to assign

	Returns:
		true on success, false if not enough generic IDs available
	"""
	return GenericInputManager.assign_action(action_name, input_events)

func get_assignment_ids(action_name: String) -> Array:
	"""
	Returns the array of generic IDs assigned to an action.
	Used internally for mapping logical actions to generic inputs.
	"""
	return GenericInputManager.get_action_generic_ids(action_name)

func get_assignment_events(action_name: String) -> Array:
	"""
	Returns the array of InputEvent objects assigned to an action.
	Used by UI to display current bindings.
	"""
	return GenericInputManager.get_action_input_events(action_name)

func get_vector(negative_x: String, positive_x: String, negative_y: String, positive_y: String, deadzone: float = 0.25) -> Vector2:
	"""
	Gets a 2D vector from four actions (like Input.get_vector but works with generic system).
	Supports both analog axis inputs and digital button inputs.

	Args:
		negative_x: Action for left movement
		positive_x: Action for right movement
		negative_y: Action for up movement
		positive_y: Action for down movement
		deadzone: Minimum value to register (default 0.25)

	Returns:
		Normalized Vector2 representing the input direction
	"""
	var x_axis = 0.0
	var y_axis = 0.0

	# Check positive_x (right)
	var right_ids = GenericInputManager.get_action_generic_ids(positive_x)
	for generic_id in right_ids:
		var value = _get_generic_input_value(generic_id, deadzone)
		x_axis += value

	# Check negative_x (left)
	var left_ids = GenericInputManager.get_action_generic_ids(negative_x)
	for generic_id in left_ids:
		var value = _get_generic_input_value(generic_id, deadzone)
		x_axis -= value

	# Check negative_y (up)
	var up_ids = GenericInputManager.get_action_generic_ids(negative_y)
	for generic_id in up_ids:
		var value = _get_generic_input_value(generic_id, deadzone)
		y_axis -= value

	# Check positive_y (down)
	var down_ids = GenericInputManager.get_action_generic_ids(positive_y)
	for generic_id in down_ids:
		var value = _get_generic_input_value(generic_id, deadzone)
		y_axis += value

	# Create vector and clamp/normalize
	var result = Vector2(x_axis, y_axis)
	if result.length() > 1.0:
		result = result.normalized()

	return result

func _get_generic_input_value(generic_id: String, deadzone: float) -> float:
	"""
	Gets the input value (0.0 to 1.0) for a generic ID.
	Handles both analog axis and digital button inputs.
	"""
	var event = GenericInputManager.get_generic_id_event(generic_id)
	if event == null:
		return 0.0

	if event is InputEventJoypadMotion:
		# Read the actual axis value from the controller
		var axis_value = Input.get_joy_axis(0, event.axis)

		# Check if this is the positive or negative direction
		var expected_direction = sign(event.axis_value)

		# Only return value if moving in the expected direction and above deadzone
		if sign(axis_value) == expected_direction or (expected_direction == 0 and axis_value != 0):
			var abs_value = abs(axis_value)
			if abs_value >= deadzone:
				# Remap from [deadzone, 1.0] to [0.0, 1.0]
				var remapped = (abs_value - deadzone) / (1.0 - deadzone)
				# Snap near-full deflection to 1.0 to compensate for hardware tolerances
				if remapped >= 0.75:
					remapped = 1.0
				return remapped

		return 0.0

	elif event is InputEventJoypadButton:
		return 1.0 if Input.is_joy_button_pressed(0, event.button_index) else 0.0

	elif event is InputEventKey:
		return 1.0 if Input.is_key_pressed(event.physical_keycode) else 0.0

	elif event is InputEventMouseButton:
		return 1.0 if Input.is_mouse_button_pressed(event.button_index) else 0.0

	return 0.0

# ========================== Public API ==========================

func get_all_actions() -> Array:
	"""Returns array of all bindable action names"""
	var actions: Array = []
	for action_name in DEFAULT_KEYBINDS.keys():
		actions.append(action_name)
	return actions

func get_action_label(action_name: String) -> String:
	"""Returns the display name for an action"""
	return ACTION_LABELS.get(action_name, action_name)

func get_keybind(action_name: String) -> String:
	"""Returns the current keyboard binding as a string (e.g., 'ctrl+x' or 'a+b+c')"""
	# First check generic system
	var events = GenericInputManager.get_action_input_events(action_name)
	if events.size() > 0:
		# Check if these are keyboard/mouse events
		var is_keyboard = false
		for event in events:
			if event is InputEventKey or event is InputEventMouseButton:
				is_keyboard = true
				break

		if is_keyboard:
			# Convert events to string representation
			var key_parts: Array = []
			for event in events:
				if event is InputEventKey or event is InputEventMouseButton:
					key_parts.append(_event_to_string(event))
			return "+".join(key_parts)

	# Fallback to traditional InputMap
	events = InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey or event is InputEventMouseButton:
			return _event_to_string(event)
	return ""

func get_gamepad_bind(action_name: String) -> String:
	"""Returns the current gamepad binding as a string (e.g., 'a+b' or 'left_stick_up')"""
	# First check generic system
	var events = GenericInputManager.get_action_input_events(action_name)
	if events.size() > 0:
		# Check if these are gamepad events
		var is_gamepad = false
		for event in events:
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				is_gamepad = true
				break

		if is_gamepad:
			# Convert events to string representation
			var joy_inputs: Array = []
			for event in events:
				if event is InputEventJoypadButton:
					joy_inputs.append(_joy_button_to_string(event.button_index))
				elif event is InputEventJoypadMotion:
					joy_inputs.append(_joy_motion_to_string(event.axis, event.axis_value))
			if joy_inputs.size() > 0:
				return "+".join(joy_inputs)

	# Fallback to traditional InputMap
	events = InputMap.action_get_events(action_name)
	var joy_inputs: Array = []
	for event in events:
		if event is InputEventJoypadButton:
			joy_inputs.append(_joy_button_to_string(event.button_index))
		elif event is InputEventJoypadMotion:
			joy_inputs.append(_joy_motion_to_string(event.axis, event.axis_value))
	if joy_inputs.size() > 0:
		return "+".join(joy_inputs)
	return ""

func set_keybind(action_name: String, binding: String) -> void:
	"""Sets the keyboard/mouse binding for an action"""
	# Remove keyboard/mouse events and get preserved gamepad events
	var gamepad_events = GenericInputManager.unassign_keyboard_events(action_name)

	# Remove existing keyboard/mouse events from traditional system
	_remove_keyboard_mouse_events(action_name)

	# Build combined event array
	var all_events = []

	# Add new keyboard binding
	if binding != "":
		var keyboard_events = _parse_keyboard_binding(binding)
		all_events.append_array(keyboard_events)

	# Add preserved gamepad events
	all_events.append_array(gamepad_events)

	# Assign combined events
	if all_events.size() > 0:
		if not GenericInputManager.assign_action(action_name, all_events):
			push_error("Failed to assign keyboard binding for %s" % action_name)

	binding_changed.emit(action_name, "keyboard")

func set_gamepad_bind(action_name: String, binding: String) -> void:
	"""Sets the gamepad binding for an action"""
	# Remove gamepad events and get preserved keyboard/mouse events
	var keyboard_events = GenericInputManager.unassign_gamepad_events(action_name)

	# Remove existing gamepad events from traditional system
	_remove_gamepad_events(action_name)

	# Build combined event array
	var all_events = []

	# Add preserved keyboard events first
	all_events.append_array(keyboard_events)

	# Add new gamepad binding
	if binding != "":
		# Ensure joy_ prefix
		var joy_binding = binding
		if not joy_binding.begins_with("joy_"):
			var parts = joy_binding.split("+")
			var joy_parts: Array = []
			for part in parts:
				joy_parts.append("joy_" + part)
			joy_binding = "+".join(joy_parts)

		var gamepad_events = _parse_gamepad_binding(joy_binding)
		all_events.append_array(gamepad_events)

	# Assign combined events
	if all_events.size() > 0:
		if not GenericInputManager.assign_action(action_name, all_events):
			push_error("Failed to assign gamepad binding for %s" % action_name)

	binding_changed.emit(action_name, "gamepad")

func find_conflict(binding: String, binding_type: String, exclude_action: String = "") -> String:
	"""
	Checks if a binding is already assigned to another action.
	Returns the conflicting action name, or empty string if no conflict.
	"""
	for action_name in get_all_actions():
		if action_name == exclude_action:
			continue

		var existing_binding: String = ""
		if binding_type == "keyboard":
			existing_binding = get_keybind(action_name)
		else:
			existing_binding = get_gamepad_bind(action_name)

		if existing_binding == binding:
			return action_name

	return ""

func swap_bindings(action1: String, action2: String, binding_type: String) -> void:
	"""Swaps bindings between two actions"""
	var binding1: String = ""
	var binding2: String = ""

	if binding_type == "keyboard":
		binding1 = get_keybind(action1)
		binding2 = get_keybind(action2)
		set_keybind(action1, binding2)
		set_keybind(action2, binding1)
	else:
		binding1 = get_gamepad_bind(action1)
		binding2 = get_gamepad_bind(action2)
		set_gamepad_bind(action1, binding2)
		set_gamepad_bind(action2, binding1)

func reset_to_defaults() -> void:
	"""Resets all bindings to default values"""
	for action_name in get_all_actions():
		# Clear generic assignments
		GenericInputManager.unassign_action(action_name)
		InputMap.action_erase_events(action_name)

		# Restore default keybind
		var default_key = DEFAULT_KEYBINDS.get(action_name, "")
		if default_key != "":
			set_keybind(action_name, default_key)

		# Restore default gamepad
		var default_joy = DEFAULT_GAMEPAD.get(action_name, "")
		if default_joy != "":
			set_gamepad_bind(action_name, default_joy)

	save_bindings()
	bindings_reset.emit()

func reset_action_to_default(action_name: String, binding_type: String) -> void:
	"""Resets a single action's binding to default"""
	if binding_type == "keyboard":
		var default_key = DEFAULT_KEYBINDS.get(action_name, "")
		set_keybind(action_name, default_key)
	else:
		var default_joy = DEFAULT_GAMEPAD.get(action_name, "")
		set_gamepad_bind(action_name, default_joy)

func clear_binding(action_name: String, binding_type: String) -> void:
	"""Clears a single action's binding (sets it to empty)"""
	if binding_type == "keyboard":
		set_keybind(action_name, "")
	else:
		set_gamepad_bind(action_name, "")

func get_all_bindings() -> Dictionary:
	"""
	Returns a snapshot of all current bindings.
	Used for storing state before changes to enable cancel/revert.
	Returns: {"action_name": {"keyboard": "ctrl+x", "gamepad": "a+b"}, ...}
	"""
	var bindings: Dictionary = {}
	for action_name in get_all_actions():
		bindings[action_name] = {
			"keyboard": get_keybind(action_name),
			"gamepad": get_gamepad_bind(action_name)
		}
	return bindings

func restore_all_bindings(bindings: Dictionary) -> void:
	"""
	Restores bindings from a saved state (from get_all_bindings).
	Used for reverting changes when user cancels.
	"""
	for action_name in bindings.keys():
		var action_bindings = bindings[action_name]
		if action_bindings.has("keyboard"):
			set_keybind(action_name, action_bindings["keyboard"])
		if action_bindings.has("gamepad"):
			set_gamepad_bind(action_name, action_bindings["gamepad"])

# ========================== Save/Load ==========================

func save_bindings() -> void:
	"""Saves current bindings to config file"""
	var config = ConfigFile.new()
	config.load(CONFIG_FILE_PATH)  # Load existing config

	# Save keyboard bindings
	for action_name in get_all_actions():
		var keybind = get_keybind(action_name)
		config.set_value(KEYBINDS_SECTION, action_name, keybind)

		var gamepad_bind = get_gamepad_bind(action_name)
		config.set_value(GAMEPAD_SECTION, action_name, gamepad_bind)

	config.save(CONFIG_FILE_PATH)

func load_bindings() -> void:
	"""Loads bindings from config file, or uses defaults if not found"""
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)

	if err != OK:
		# Config doesn't exist, use defaults
		reset_to_defaults()
		return

	# Load keyboard and gamepad bindings
	for action_name in get_all_actions():
		var keybind = config.get_value(
			KEYBINDS_SECTION,
			action_name,
			DEFAULT_KEYBINDS.get(action_name, "")
		)

		var gamepad_bind = config.get_value(
			GAMEPAD_SECTION,
			action_name,
			DEFAULT_GAMEPAD.get(action_name, "")
		)

		# Clear existing assignments
		GenericInputManager.unassign_action(action_name)
		InputMap.action_erase_events(action_name)

		# Register keyboard and gamepad bindings SEPARATELY to avoid treating
		# them as multi-button combos in the InputStateMachine
		var has_assignments = false

		# Parse and assign keyboard events separately
		if keybind != "":
			var keyboard_events = _parse_keyboard_binding(keybind)
			if keyboard_events.size() > 0:
				# Skip rebuild during bulk loading for performance
				if not GenericInputManager.assign_action(action_name, keyboard_events, true, false):
					push_error("Failed to assign keyboard bindings for %s" % action_name)
				else:
					has_assignments = true

		# Parse and assign gamepad events separately
		if gamepad_bind != "":
			# Ensure joy_ prefix
			var joy_binding = gamepad_bind
			if not joy_binding.begins_with("joy_"):
				var parts = joy_binding.split("+")
				var joy_parts: Array = []
				for part in parts:
					joy_parts.append("joy_" + part)
				joy_binding = "+".join(joy_parts)

			var gamepad_events = _parse_gamepad_binding(joy_binding)
			if gamepad_events.size() > 0:
				# Skip rebuild during bulk loading for performance, APPEND to keyboard events
				if not GenericInputManager.assign_action(action_name, gamepad_events, true, true):
					push_error("Failed to assign gamepad bindings for %s" % action_name)
				else:
					has_assignments = true

		if not has_assignments:
			push_warning("No events to assign for action '%s' (keyboard='%s', gamepad='%s')" % [action_name, keybind, gamepad_bind])

	# Rebuild state machine once after all actions are loaded
	GenericInputManager.rebuild_state_machine()

# ========================== Helper Methods ==========================

func _remove_keyboard_mouse_events(action_name: String) -> void:
	"""Removes all keyboard and mouse events from an action"""
	var events = InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey or event is InputEventMouseButton:
			InputMap.action_erase_event(action_name, event)

func _remove_gamepad_events(action_name: String) -> void:
	"""Removes all gamepad events from an action"""
	var events = InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_erase_event(action_name, event)

func _event_to_string(event: InputEvent) -> String:
	"""Converts an InputEvent to a string representation"""
	if event is InputEventKey:
		var result: String = ""
		if event.ctrl_pressed:
			result += "ctrl+"
		if event.shift_pressed:
			result += "shift+"
		if event.alt_pressed:
			result += "alt+"

		# Find the key name
		for key_name in KEY_MAP.keys():
			if KEY_MAP[key_name] == event.physical_keycode:
				result += key_name
				return result

		# Fallback to keycode
		return result + str(event.physical_keycode)

	elif event is InputEventMouseButton:
		for mouse_name in MOUSE_MAP.keys():
			if MOUSE_MAP[mouse_name] == event.button_index:
				return mouse_name
		return "mouse_" + str(event.button_index)

	return ""

func _joy_button_to_string(button_index: int) -> String:
	"""Converts a joy button index to string name"""
	for joy_name in JOY_MAP.keys():
		if JOY_MAP[joy_name] == button_index:
			return joy_name
	return str(button_index)

func _joy_motion_to_string(axis: int, axis_value: float) -> String:
	"""Converts axis and axis_value to analog stick name"""
	# Search for matching motion in JOY_MAP
	for joy_name in JOY_MAP.keys():
		var joy_data = JOY_MAP[joy_name]
		if joy_data is String:
			# Parse format "0:axis:value"
			var parts = joy_data.split(":")
			if parts.size() == 3:
				var map_axis = int(parts[1])
				var map_value = float(parts[2])
				if map_axis == axis and map_value == axis_value:
					return joy_name
	# Fallback to raw format
	return "axis_" + str(axis) + "_" + str(axis_value)

func _parse_keyboard_binding(binding: String) -> Array:
	"""
	Parses a keyboard binding string and returns an array of InputEvent objects.
	Supports formats like: "a", "ctrl+x", "a+b+c", "mouse_left"
	"""
	var events: Array = []

	# Split by + to get individual keys/buttons
	var parts = binding.split("+")

	for part in parts:
		var event = null

		# Handle mouse inputs
		if part.begins_with("mouse_"):
			event = InputEventMouseButton.new()
			var mouse_button = MOUSE_MAP.get(part)
			if mouse_button == null:
				push_error("Unknown mouse button: ", part)
				continue
			event.button_index = mouse_button
			events.append(event)

		# Handle keyboard keys (check for modifiers in the part)
		else:
			# For multi-key combos like "a+b+c", each part is a separate key
			# For modifier combos like "ctrl+x", we need special handling
			# We'll treat ctrl, shift, alt as modifiers only if they're in specific positions

			# Check if this is a modifier key
			var is_modifier = part in ["ctrl", "shift", "alt"]

			if is_modifier and parts.size() > 1:
				# This is a modifier in a combo, skip it (handled below)
				continue

			# Create key event
			event = InputEventKey.new()
			var keycode = KEY_MAP.get(part)
			if keycode == null:
				push_error("Unknown key: ", part)
				continue

			event.physical_keycode = keycode

			# Check if earlier parts were modifiers (for traditional ctrl+x style)
			if parts.size() > 1:
				var part_index = parts.find(part)
				for i in range(part_index):
					var mod = parts[i]
					if mod == "ctrl":
						event.ctrl_pressed = true
					elif mod == "shift":
						event.shift_pressed = true
					elif mod == "alt":
						event.alt_pressed = true

			events.append(event)

	return events

func _parse_gamepad_binding(binding: String) -> Array:
	"""
	Parses a gamepad binding string and returns an array of InputEvent objects.
	Supports formats like: "joy_a", "joy_a+joy_b", "joy_left_stick_up"
	"""
	var events: Array = []

	# Split by + to get individual buttons
	var joystick_buttons = binding.split("+")

	for button_str in joystick_buttons:
		# Remove "joy_" prefix
		var button_name = button_str.replace("joy_", "")
		var joy_button = JOY_MAP.get(button_name)

		if joy_button == null:
			push_error("Unknown gamepad button: ", button_name)
			continue

		var event = null

		# Check if it's an analog motion (string) or button (int)
		if joy_button is String:
			# Parse analog motion format: "0:axis:value"
			var parts = joy_button.split(":")
			if parts.size() != 3:
				push_error("Invalid analog motion format: ", joy_button)
				continue

			event = InputEventJoypadMotion.new()
			event.axis = int(parts[1])
			event.axis_value = float(parts[2])
			events.append(event)
		else:
			# It's a button
			event = InputEventJoypadButton.new()
			event.button_index = joy_button
			events.append(event)

	return events

func bind(action_name: String, binding: String) -> void:
	"""
	Binds an input string to an action.
	Supports formats:
	- "a", "space", "enter" - keyboard keys
	- "ctrl+x", "shift+a", "ctrl+shift+s" - key combinations
	- "mouse_left", "mouse_right", "mouse_wheel_up" - mouse buttons
	- "joy_a", "joy_b", "joy_left_shoulder" - gamepad buttons
	- "joy_a+joy_b" - gamepad combinations (adds multiple events)
	- "joy_left_stick_up", "joy_right_stick_down" - analog stick motion
	"""
	var event = null

	# Handle mouse inputs
	if binding.begins_with("mouse_"):
		event = InputEventMouseButton.new()
		var mouse_button = MOUSE_MAP.get(binding)
		if mouse_button == null:
			push_error("Unknown mouse button: ", binding)
			return
		event.button_index = mouse_button
		InputMap.action_add_event(action_name, event)

	# Handle gamepad button inputs (e.g., "joy_a+joy_x+joy_y")
	elif binding.begins_with("joy_"):
		# Split the binding for gamepad button combinations
		var joystick_buttons = binding.split("+")

		# Add an InputEventJoypadButton for each button in the combination
		for button_str in joystick_buttons:
			# Remove "joy_" prefix to get button name
			var button_name = button_str.replace("joy_", "")
			var joy_button = JOY_MAP.get(button_name)
			if joy_button == null:
				push_error("Unknown gamepad button: ", button_name)
				return

			# Check if it's an analog motion (string) or button (int)
			if joy_button is String:
				# Parse analog motion format: "0:axis:value"
				var parts = joy_button.split(":")
				if parts.size() != 3:
					push_error("Invalid analog motion format: ", joy_button)
					return

				event = InputEventJoypadMotion.new()
				event.axis = int(parts[1])
				event.axis_value = float(parts[2])
				InputMap.action_add_event(action_name, event)
			else:
				# It's a button
				event = InputEventJoypadButton.new()
				event.button_index = joy_button
				InputMap.action_add_event(action_name, event)

	# Handle keyboard key inputs (including modifiers)
	else:
		# Split the binding if it's a combination (e.g., "ctrl+shift+x")
		var parts = binding.split("+")
		var key_name = parts[parts.size() - 1]  # Last part is the main key
		var modifiers = parts.slice(0, parts.size() - 1) if parts.size() > 1 else []

		# Create the key event
		event = InputEventKey.new()
		var keycode = KEY_MAP.get(key_name)
		if keycode == null:
			push_error("Unknown key: ", key_name)
			return

		event.physical_keycode = keycode

		# Apply modifiers
		for modifier in modifiers:
			if modifier == "shift":
				event.shift_pressed = true
			elif modifier == "ctrl":
				event.ctrl_pressed = true
			elif modifier == "alt":
				event.alt_pressed = true
			else:
				push_error("Unknown modifier: ", modifier)

		InputMap.action_add_event(action_name, event)

#JOY_BUTTON_A
# ---------------------------- Static Data -----------------------------------------------
const KEY_MAP: Dictionary = {
	"a": KEY_A,
	"b": KEY_B,
	"c": KEY_C,
	"d": KEY_D,
	"e": KEY_E,
	"f": KEY_F,
	"g": KEY_G,
	"h": KEY_H,
	"i": KEY_I,
	"j": KEY_J,
	"k": KEY_K,
	"l": KEY_L,
	"m": KEY_M,
	"n": KEY_N,
	"o": KEY_O,
	"p": KEY_P,
	"q": KEY_Q,
	"r": KEY_R,
	"s": KEY_S,
	"t": KEY_T,
	"u": KEY_U,
	"v": KEY_V,
	"w": KEY_W,
	"x": KEY_X,
	"y": KEY_Y,
	"z": KEY_Z,

	"1": KEY_1,
	"2": KEY_2,
	"3": KEY_3,
	"4": KEY_4,
	"5": KEY_5,
	"6": KEY_6,
	"7": KEY_7,
	"8": KEY_8,
	"9": KEY_9,
	"0": KEY_0,

	"minus": KEY_MINUS,
	"equal": KEY_EQUAL,
	"backspace": KEY_BACKSPACE,
	"tab": KEY_TAB,
	"caps_lock": KEY_CAPSLOCK,
	"left_shift": KEY_SHIFT,
	"right_shift": KEY_SHIFT,
	"left_control": KEY_CTRL,
	"right_control": KEY_CTRL,
	"alt": KEY_ALT,
	"space": KEY_SPACE,
	"enter": KEY_ENTER,
	"semicolon": KEY_SEMICOLON,
	"quote": KEY_APOSTROPHE,
	"comma": KEY_COMMA,
	"period": KEY_PERIOD,
	"slash": KEY_SLASH,
	"left_bracket": KEY_BRACKETLEFT,
	"right_bracket": KEY_BRACKETRIGHT,
	"backslash": KEY_BACKSLASH,
	"grave": KEY_QUOTELEFT,
	
	"f1": KEY_F1,
	"f2": KEY_F2,
	"f3": KEY_F3,
	"f4": KEY_F4,
	"f5": KEY_F5,
	"f6": KEY_F6,
	"f7": KEY_F7,
	"f8": KEY_F8,
	"f9": KEY_F9,
	"f10": KEY_F10,
	"f11": KEY_F11,
	"f12": KEY_F12,
	"print": KEY_PRINT,
	"scroll_lock": KEY_SCROLLLOCK,
	"pause": KEY_PAUSE,
	"insert": KEY_INSERT,
	"home": KEY_HOME,
	"page_up": KEY_PAGEUP,
	"delete": KEY_DELETE,
	"end": KEY_END,
	"page_down": KEY_PAGEDOWN,
	"left_arrow": KEY_LEFT,
	"up_arrow": KEY_UP,
	"right_arrow": KEY_RIGHT,
	"down_arrow": KEY_DOWN,
}

const MOUSE_MAP: Dictionary = {
	"mouse_left": MOUSE_BUTTON_LEFT,
	"mouse_right": MOUSE_BUTTON_RIGHT,
	"mouse_middle": MOUSE_BUTTON_MIDDLE,
	"mouse_wheel_up": MOUSE_BUTTON_WHEEL_UP,
	"mouse_wheel_down": MOUSE_BUTTON_WHEEL_DOWN,
	"mouse_wheel_left": MOUSE_BUTTON_WHEEL_LEFT,
	"mouse_wheel_right": MOUSE_BUTTON_WHEEL_RIGHT,
	"mouse_xbutton1": MOUSE_BUTTON_XBUTTON1,
	"mouse_xbutton2": MOUSE_BUTTON_XBUTTON2
}

const JOY_MAP: Dictionary = {
	"a": JOY_BUTTON_A,
	"b": JOY_BUTTON_B,
	"x": JOY_BUTTON_X,
	"y": JOY_BUTTON_Y,
	"back": JOY_BUTTON_BACK,
	"guide": JOY_BUTTON_GUIDE,
	"start": JOY_BUTTON_START,
	"left_stick": JOY_BUTTON_LEFT_STICK,
	"right_stick": JOY_BUTTON_RIGHT_STICK,
	"left_shoulder": JOY_BUTTON_LEFT_SHOULDER,
	"right_shoulder": JOY_BUTTON_RIGHT_SHOULDER,
	"dpad_up": JOY_BUTTON_DPAD_UP,
	"dpad_down": JOY_BUTTON_DPAD_DOWN,
	"dpad_left": JOY_BUTTON_DPAD_LEFT,
	"dpad_right": JOY_BUTTON_DPAD_RIGHT,
	"misc1": JOY_BUTTON_MISC1,
	"paddle1": JOY_BUTTON_PADDLE1,
	"paddle2": JOY_BUTTON_PADDLE2,
	"paddle3": JOY_BUTTON_PADDLE3,
	"paddle4": JOY_BUTTON_PADDLE4,
	"touchpad": JOY_BUTTON_TOUCHPAD,
	# Analog stick motion (format: "axis:value")
	"left_stick_up": "0:1:-1.0",     # axis 1, negative
	"left_stick_down": "0:1:1.0",    # axis 1, positive
	"left_stick_left": "0:0:-1.0",   # axis 0, negative
	"left_stick_right": "0:0:1.0",   # axis 0, positive
	"right_stick_up": "0:3:-1.0",    # axis 3, negative
	"right_stick_down": "0:3:1.0",   # axis 3, positive
	"right_stick_left": "0:2:-1.0",  # axis 2, negative
	"right_stick_right": "0:2:1.0",  # axis 2, positive
	"left_trigger": "0:4:1.0",       # axis 4, positive (L2/LT)
	"right_trigger": "0:5:1.0"       # axis 5, positive (R2/RT)
}
