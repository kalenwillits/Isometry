extends Node
# InputIconMapper - Utility for mapping input events to icon paths and display text
# This handles converting Godot input events to gamepad icon filenames or keyboard text labels

var CONFIG_FILE_PATH: String = io.get_dir() + "options.cfg"
const CONFIG_SECTION_INPUT: String = "input"
const ICON_BASE_PATH: String = "res://assets/gamepad-icons/"
const ICON_DPI: String = "96dpi"  # Default DPI to use

# Signal emitted when icon mode changes
signal icon_mode_changed(new_mode: IconMode)

# Icon mode enum values
enum IconMode {
	KEYBOARD,
	GENERIC,
	XBOX,
	PLAYSTATION,
	NINTENDO,
	NONE
}

# Map icon mode strings to enum
var icon_mode_map: Dictionary = {
	"Keyboard": IconMode.KEYBOARD,
	"Generic": IconMode.GENERIC,
	"XBox": IconMode.XBOX,
	"PlayStation": IconMode.PLAYSTATION,
	"Nintendo": IconMode.NINTENDO,
	"None": IconMode.NONE
}

# Current cached icon mode
var current_icon_mode: IconMode = IconMode.KEYBOARD

func _ready() -> void:
	current_icon_mode = _load_icon_mode_from_config()

# Get current icon mode (from cache)
func get_icon_mode() -> IconMode:
	return current_icon_mode

# Update icon mode and emit signal
func set_icon_mode(mode: IconMode) -> void:
	if current_icon_mode != mode:
		current_icon_mode = mode
		icon_mode_changed.emit(mode)

# Load icon mode from config file
func _load_icon_mode_from_config() -> IconMode:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	if err == OK:
		var mode_string = config.get_value(CONFIG_SECTION_INPUT, "icon_mode", "Keyboard")
		return icon_mode_map.get(mode_string, IconMode.KEYBOARD)
	return IconMode.KEYBOARD

# Reload icon mode from config and notify listeners
func reload_from_config() -> void:
	var new_mode = _load_icon_mode_from_config()
	set_icon_mode(new_mode)

# Map InputEvent to display data (icon path or text)
# Returns Dictionary with keys: type ("icon" or "text"), value (path or text string)
static func event_to_display(event: InputEvent, icon_mode: IconMode) -> Dictionary:
	if icon_mode == IconMode.NONE:
		return {"type": "none", "value": ""}

	if event is InputEventKey:
		return _key_event_to_display(event, icon_mode)
	elif event is InputEventMouseButton:
		return _mouse_event_to_display(event, icon_mode)
	elif event is InputEventJoypadButton:
		return _joypad_event_to_display(event, icon_mode)

	return {"type": "text", "value": "?"}

# Convert keyboard event to display
static func _key_event_to_display(event: InputEventKey, icon_mode: IconMode) -> Dictionary:
	# Build modifier prefix (shortened to 2-3 characters)
	var modifier_string = ""
	if event.ctrl_pressed:
		modifier_string += "Ctl+"
	if event.shift_pressed:
		modifier_string += "Sft+"
	if event.alt_pressed:
		modifier_string += "Alt+"

	if icon_mode == IconMode.KEYBOARD:
		# Return text representation for keyboard mode with modifiers
		var key_string = OS.get_keycode_string(event.physical_keycode)
		key_string = _shorten_key_name(key_string)
		return {"type": "text", "value": modifier_string + key_string}
	else:
		# For gamepad modes, keyboard inputs don't have icons
		var key_string = OS.get_keycode_string(event.physical_keycode)
		key_string = _shorten_key_name(key_string)
		return {"type": "text", "value": modifier_string + key_string}

# Shorten common key names to fit better in UI
static func _shorten_key_name(key_string: String) -> String:
	match key_string:
		"Escape": return "Esc"
		"Enter": return "Enter"
		"Space": return "Space"
		"Shift": return "Shift"
		"Ctrl": return "Ctrl"
		"Alt": return "Alt"
		"Tab": return "Tab"
		"Backspace": return "Back"
		"Delete": return "Del"
		"Insert": return "Ins"
		"Page Up": return "PgUp"
		"Page Down": return "PgDn"
		_: return key_string

# Convert mouse event to display
static func _mouse_event_to_display(event: InputEventMouseButton, icon_mode: IconMode) -> Dictionary:
	if icon_mode == IconMode.KEYBOARD:
		# Return text representation for keyboard mode
		var mouse_text = _mouse_button_to_text(event.button_index)
		return {"type": "text", "value": mouse_text}
	else:
		# For gamepad modes, map mouse buttons to generic gamepad buttons
		# This is a fallback mapping - adjust as needed
		return {"type": "text", "value": _mouse_button_to_text(event.button_index)}

# Convert joypad event to display
static func _joypad_event_to_display(event: InputEventJoypadButton, icon_mode: IconMode) -> Dictionary:
	if icon_mode == IconMode.KEYBOARD:
		# Show text for keyboard mode
		var button_text = _joypad_button_to_text(event.button_index)
		return {"type": "text", "value": button_text}
	else:
		# Get icon path based on mode
		var icon_name = _joypad_button_to_icon_name(event.button_index, icon_mode)
		if icon_name != "":
			var icon_path = "%s%s.%s.png" % [ICON_BASE_PATH, icon_name, ICON_DPI]
			return {"type": "icon", "value": icon_path}
		else:
			return {"type": "text", "value": _joypad_button_to_text(event.button_index)}

# Map mouse button index to text
static func _mouse_button_to_text(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT: return "LMB"
		MOUSE_BUTTON_RIGHT: return "RMB"
		MOUSE_BUTTON_MIDDLE: return "MMB"
		MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
		MOUSE_BUTTON_WHEEL_LEFT: return "Wheel Left"
		MOUSE_BUTTON_WHEEL_RIGHT: return "Wheel Right"
		MOUSE_BUTTON_XBUTTON1: return "Mouse 4"
		MOUSE_BUTTON_XBUTTON2: return "Mouse 5"
		_: return "Mouse"

# Map joypad button index to text
static func _joypad_button_to_text(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_BACK: return "Back"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_GUIDE: return "Guide"
		JOY_BUTTON_LEFT_STICK: return "L3"
		JOY_BUTTON_RIGHT_STICK: return "R3"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_DPAD_UP: return "D-Up"
		JOY_BUTTON_DPAD_DOWN: return "D-Down"
		JOY_BUTTON_DPAD_LEFT: return "D-Left"
		JOY_BUTTON_DPAD_RIGHT: return "D-Right"
		_: return "Button"

# Map joypad button index to icon filename (without path or extension)
static func _joypad_button_to_icon_name(button_index: int, icon_mode: IconMode) -> String:
	# Map button to icon name based on mode
	match icon_mode:
		IconMode.GENERIC:
			return _joypad_button_to_generic_icon(button_index)
		IconMode.XBOX:
			return _joypad_button_to_xbox_icon(button_index)
		IconMode.PLAYSTATION:
			return _joypad_button_to_playstation_icon(button_index)
		IconMode.NINTENDO:
			return _joypad_button_to_nintendo_icon(button_index)
		_:
			return ""

# Generic gamepad icons
static func _joypad_button_to_generic_icon(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_LEFT_STICK: return "generic_l3"
		JOY_BUTTON_RIGHT_STICK: return "generic_r3"
		JOY_BUTTON_BACK: return "generic_select"
		JOY_BUTTON_START: return "generic_start"
		JOY_BUTTON_DPAD_UP: return "generic_dpad_up"
		JOY_BUTTON_DPAD_DOWN: return "generic_dpad_down"
		JOY_BUTTON_DPAD_LEFT: return "generic_dpad_left"
		JOY_BUTTON_DPAD_RIGHT: return "generic_dpad_right"
		_: return ""

# Xbox gamepad icons
static func _joypad_button_to_xbox_icon(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "xb_a"
		JOY_BUTTON_B: return "xb_b"
		JOY_BUTTON_X: return "xb_x"
		JOY_BUTTON_Y: return "xb_y"
		JOY_BUTTON_LEFT_SHOULDER: return "xb_lb"
		JOY_BUTTON_RIGHT_SHOULDER: return "xb_rb"
		JOY_BUTTON_BACK: return "xb_select"
		JOY_BUTTON_START: return "xb_start"
		JOY_BUTTON_GUIDE: return "xb_super"
		_: return _joypad_button_to_generic_icon(button_index)

# PlayStation gamepad icons
static func _joypad_button_to_playstation_icon(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "ps_x"  # A button maps to X on PlayStation
		JOY_BUTTON_B: return "ps_circle"
		JOY_BUTTON_X: return "ps_square"
		JOY_BUTTON_Y: return "ps_triangle"
		JOY_BUTTON_LEFT_SHOULDER: return "ps_l1"
		JOY_BUTTON_RIGHT_SHOULDER: return "ps_r1"
		JOY_BUTTON_GUIDE: return "ps_super"
		_: return _joypad_button_to_generic_icon(button_index)

# Nintendo Switch gamepad icons
static func _joypad_button_to_nintendo_icon(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "switch_b"  # A button maps to B on Switch (physically)
		JOY_BUTTON_B: return "switch_a"  # B button maps to A on Switch (physically)
		JOY_BUTTON_X: return "switch_y"
		JOY_BUTTON_Y: return "switch_x"
		JOY_BUTTON_LEFT_SHOULDER: return "switch_l"
		JOY_BUTTON_RIGHT_SHOULDER: return "switch_r"
		JOY_BUTTON_BACK: return "switch_minus"
		JOY_BUTTON_START: return "switch_plus"
		JOY_BUTTON_GUIDE: return "switch_super"
		_: return _joypad_button_to_generic_icon(button_index)
