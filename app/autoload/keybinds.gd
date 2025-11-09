extends Node

# Signals
signal binding_changed(action_name: String, binding_type: String)
signal bindings_reset()

# Action name constants
const INTERACT: String = "interact"
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
	OPEN_MENU: "backspace",
	MOVE_UP: "up_arrow",
	MOVE_DOWN: "down_arrow",
	MOVE_LEFT: "left_arrow",
	MOVE_RIGHT: "right_arrow"
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
	OPEN_MENU: "select",
	MOVE_UP: "left_stick_up",
	MOVE_DOWN: "left_stick_down",
	MOVE_LEFT: "left_stick_left",
	MOVE_RIGHT: "left_stick_right"
}

# Display names for actions
const ACTION_LABELS: Dictionary = {
	INTERACT: "Interact",
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
	MOVE_RIGHT: "Move Right"
}

func _init_actions() -> void:
	for action_name in DEFAULT_KEYBINDS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

func _ready() -> void:
	_init_actions()
	load_bindings()

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
	"""Returns the current keyboard binding as a string (e.g., 'ctrl+x')"""
	var events = InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey or event is InputEventMouseButton:
			return _event_to_string(event)
	return ""

func get_gamepad_bind(action_name: String) -> String:
	"""Returns the current gamepad binding as a string (e.g., 'a+b' or 'left_stick_up')"""
	var events = InputMap.action_get_events(action_name)
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
	# Remove existing keyboard/mouse events
	_remove_keyboard_mouse_events(action_name)

	# Add new binding
	if binding != "":
		bind(action_name, binding)

	binding_changed.emit(action_name, "keyboard")

func set_gamepad_bind(action_name: String, binding: String) -> void:
	"""Sets the gamepad binding for an action"""
	# Remove existing gamepad events
	_remove_gamepad_events(action_name)

	# Add new binding with joy_ prefix
	if binding != "":
		var joy_binding = binding
		if not joy_binding.begins_with("joy_"):
			# Convert button names to joy_ format
			var parts = joy_binding.split("+")
			var joy_parts: Array = []
			for part in parts:
				joy_parts.append("joy_" + part)
			joy_binding = "+".join(joy_parts)
		bind(action_name, joy_binding)

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
		InputMap.action_erase_events(action_name)

		# Restore default keybind
		var default_key = DEFAULT_KEYBINDS.get(action_name, "")
		if default_key != "":
			bind(action_name, default_key)

		# Restore default gamepad
		var default_joy = DEFAULT_GAMEPAD.get(action_name, "")
		if default_joy != "":
			bind(action_name, "joy_" + default_joy)

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

	# Load keyboard bindings
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

		# Clear existing events
		InputMap.action_erase_events(action_name)

		# Apply loaded bindings
		if keybind != "":
			bind(action_name, keybind)

		if gamepad_bind != "":
			# Add joy_ prefix if not present
			if not gamepad_bind.begins_with("joy_"):
				var parts = gamepad_bind.split("+")
				var joy_parts: Array = []
				for part in parts:
					joy_parts.append("joy_" + part)
				gamepad_bind = "+".join(joy_parts)
			bind(action_name, gamepad_bind)

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
	"right_stick_right": "0:2:1.0"   # axis 2, positive
}
