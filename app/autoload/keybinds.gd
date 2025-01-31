extends Node

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

# TODO - Tracking joystick buttons for multi-presses is a pain like this... shelf this feature
# TODO - Complete default keybinds and remove all of them from the project menu
# TODO - support combined presses
const DEFAULT: Dictionary = {
	INTERACT: ["mouse_right"],
	ACTION_1: ["q"],
	ACTION_2: ["w"],
	ACTION_3: ["e"],
	ACTION_4: ["r"],
	ACTION_5: ["t"],
	ACTION_6: ["y"],
	ACTION_7: ["u"],
	ACTION_8: ["i"],
	ACTION_9: ["o"],
	ZOOM_IN: ["page_up", "mouse_wheel_up"],
	ZOOM_OUT: ["page_down", "mouse_wheel_down"]
}

func _init_actions() -> void:
	for action_name in DEFAULT.keys():
		InputMap.add_action(action_name)
		
func _bind_actions() -> void:
	for action_name in DEFAULT.keys():
		for binding in DEFAULT[action_name]:
		# TODO - add default to the .get() to get this from another source such as a JSON file.
		# TODO - write that json file as defaults if one does not already exist
			bind(action_name, std.coalesce(binding))

func _ready() -> void:
	_init_actions()
	_bind_actions()

func bind(action_name: String, binding: String) -> void:
	var event = null
	var modifier = null
	var key = null
	var joystick_buttons = []
	
	# Handle mouse inputs first (no change here)
	if binding.begins_with("mouse_"):
		event = InputEventMouseButton.new()

		if binding == "mouse_left":
			event.button_index = MOUSE_BUTTON_LEFT
		elif binding == "mouse_right":
			event.button_index = MOUSE_BUTTON_RIGHT
		elif binding == "mouse_middle":
			event.button_index = MOUSE_BUTTON_MIDDLE
		elif binding == "mouse_wheel_up":
			event.button_index = MOUSE_BUTTON_WHEEL_UP
		elif binding == "mouse_wheel_down":
			event.button_index = MOUSE_BUTTON_WHEEL_DOWN
		elif binding == "mouse_wheel_left":
			event.button_index = MOUSE_BUTTON_WHEEL_LEFT
		elif binding == "mouse_wheel_right":
			event.button_index = MOUSE_BUTTON_WHEEL_RIGHT
		else:
			return  # If the binding is not a recognized mouse input, exit

	# Handle joystick button inputs (e.g., "a+x+y")
	elif binding.begins_with("joy_"):
		# Split the binding for joystick button combinations (e.g., "a+x+y")
		joystick_buttons = binding.split("+")
		
		# We will add an InputEventJoypadButton for each joystick button in the combination
		for button in joystick_buttons:
			var joy_button = JOY_MAP.get(button)
			if joy_button == null:
				push_error("failed to find joy button ", joy_button)
				return
			
			event = InputEventJoypadButton.new()
			event.button_index = joy_button

			# Add the event to the action (each combination will be a different event)
			InputMap.action_add_event(action_name, event)

	# Handle key inputs (for regular key combinations)
	else:
		# Split the binding if it's a combination (e.g., "shift+q")
		var parts = binding.split("+")
		if parts.size() > 1:
			# We have a combination of keys
			var modifiers = parts.slice(0, parts.size() - 1)  # All except the last part (which is the main key)
			key = parts[parts.size() - 1]  # The last part is the main key

			# Set modifier flags for InputEventKey
			if "shift" in modifiers:
				modifier |= KEY_SHIFT
			if "ctrl" in modifiers:
				modifier |= KEY_CTRL
			if "alt" in modifiers:
				modifier |= KEY_ALT

		else:
			key = binding  # No modifiers, just a single key

		# Now create the InputEventKey for the main key
		event = InputEventKey.new()
		var keycode = std.coalesce(
			KEY_MAP.get(key),
			MOUSE_MAP.get(key),  # This will handle some special mouse keys, if needed
			JOY_MAP.get(key)      # For joystick bindings, we'll use this map
		)
		
		if keycode == null: 
			push_error("failed to find keycode ", keycode)
			return
		
		event.physical_keycode = keycode

		# Apply modifiers (Shift, Ctrl, Alt)
		event.modifier = modifier

	# Add the event to the input map for the corresponding action
	InputMap.action_add_event(action_name, event)




func unbind(action_name: String) -> void:
	InputMap.action_erase_events(action_name)

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
	"touchpad": JOY_BUTTON_TOUCHPAD
}
