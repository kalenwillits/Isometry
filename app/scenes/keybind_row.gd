extends HBoxContainer

const BaseTheme = preload("res://themes/BaseTheme.res")

signal binding_requested(action_name: String, binding_type: String)
signal reset_requested(action_name: String, binding_type: String)

@export var action_name: String = ""
@export var binding_type: String = "keyboard"  # "keyboard" or "gamepad"

var is_listening: bool = false
var pressed_keys: Array = []
var key_combo_to_bind: Array = []  # Tracks the full keyboard combo even after keys are released
var pressed_joy_buttons: Array = []
var joy_combo_to_bind: Array = []  # Tracks the full combo even after buttons are released

@onready var action_label: Label = $ActionLabel
@onready var binding_button: Button = $BindingButton
@onready var clear_button: Button = $ResetButton

func _ready() -> void:
	binding_button.pressed.connect(_on_binding_button_pressed)
	clear_button.pressed.connect(_on_clear_button_pressed)
	clear_button.text = "Clear"

	Keybinds.binding_changed.connect(_on_binding_changed)
	Keybinds.bindings_reset.connect(_on_bindings_reset)

	_update_display()

func _update_display() -> void:
	"""Updates the displayed action name and current binding"""
	if action_name == "":
		return

	# Set action label
	action_label.text = Keybinds.get_action_label(action_name)

	# Set binding button text
	var current_binding: String = ""
	if binding_type == "keyboard":
		current_binding = Keybinds.get_keybind(action_name)
	else:
		current_binding = Keybinds.get_gamepad_bind(action_name)

	if current_binding == "":
		binding_button.text = "---"
	else:
		binding_button.text = _format_binding_display(current_binding)

func _format_binding_display(binding: String) -> String:
	"""Formats binding string for display (capitalizes, better formatting)"""
	# Replace underscores with spaces
	binding = binding.replace("_", " ")

	# Capitalize each word
	var parts = binding.split(" ")
	var formatted_parts: Array = []
	for part in parts:
		if part.length() > 0:
			formatted_parts.append(part.capitalize())

	return " ".join(formatted_parts)

func _on_binding_button_pressed() -> void:
	"""Called when user clicks the binding button to rebind"""
	if is_listening:
		_stop_listening()
	else:
		_start_listening()

func _start_listening() -> void:
	"""Enters listening mode to capture new binding"""
	is_listening = true
	pressed_keys.clear()
	key_combo_to_bind.clear()
	pressed_joy_buttons.clear()
	joy_combo_to_bind.clear()

	binding_button.text = "Press key..."
	if binding_type == "gamepad":
		binding_button.text = "Press button or move stick..."

	# Request focus
	set_process_input(true)

func _stop_listening() -> void:
	"""Exits listening mode"""
	is_listening = false
	set_process_input(false)
	_update_display()

func _input(event: InputEvent) -> void:
	if not is_listening:
		return

	# Handle keyboard/mouse inputs
	if binding_type == "keyboard":
		if event is InputEventKey:
			_handle_key_binding(event)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed:
			_handle_mouse_binding(event)
			get_viewport().set_input_as_handled()

	# Handle gamepad inputs
	elif binding_type == "gamepad":
		if event is InputEventJoypadButton:
			_handle_joy_binding(event)
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadMotion:
			_handle_joy_motion_binding(event)
			get_viewport().set_input_as_handled()

func _handle_key_binding(event: InputEventKey) -> void:
	"""Handles keyboard key binding using state machine approach (like gamepad)"""

	# Skip modifier keys themselves - only capture regular keys with modifiers
	if event.physical_keycode in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META]:
		return  # Don't bind modifier keys, wait for actual key

	if event.pressed:
		# KEY PRESS: Add to tracking arrays

		# Find key name using physical_keycode
		var key_name: String = ""
		for name in Keybinds.KEY_MAP.keys():
			if Keybinds.KEY_MAP[name] == event.physical_keycode:
				key_name = name
				break

		if key_name == "":
			_stop_listening()
			return

		# Build the key string with modifiers
		var key_with_modifiers: String = ""
		if event.ctrl_pressed:
			key_with_modifiers += "ctrl+"
		if event.shift_pressed:
			key_with_modifiers += "shift+"
		if event.alt_pressed:
			key_with_modifiers += "alt+"
		key_with_modifiers += key_name

		# Add to pressed list (current physical keys held)
		if key_with_modifiers not in pressed_keys:
			pressed_keys.append(key_with_modifiers)

		# Add to combo list (all keys pressed in this session)
		if key_with_modifiers not in key_combo_to_bind:
			key_combo_to_bind.append(key_with_modifiers)

		# Update display to show current combo
		binding_button.text = "+".join(key_combo_to_bind)

	else:
		# KEY RELEASE: Remove from pressed list

		# Find the key that was released
		var key_name: String = ""
		for name in Keybinds.KEY_MAP.keys():
			if Keybinds.KEY_MAP[name] == event.physical_keycode:
				key_name = name
				break

		if key_name == "":
			return

		# Build the key string with modifiers (same logic as press)
		var key_with_modifiers: String = ""
		if event.ctrl_pressed:
			key_with_modifiers += "ctrl+"
		if event.shift_pressed:
			key_with_modifiers += "shift+"
		if event.alt_pressed:
			key_with_modifiers += "alt+"
		key_with_modifiers += key_name

		# Remove from currently pressed keys
		if key_with_modifiers in pressed_keys:
			pressed_keys.erase(key_with_modifiers)

		# When ALL keys released, apply the binding
		if pressed_keys.size() == 0 and key_combo_to_bind.size() > 0:
			var binding_str = "+".join(key_combo_to_bind)
			_apply_binding(binding_str)

func _handle_mouse_binding(event: InputEventMouseButton) -> void:
	"""Handles mouse button binding"""
	var binding_str: String = ""

	# Find mouse button name
	for name in Keybinds.MOUSE_MAP.keys():
		if Keybinds.MOUSE_MAP[name] == event.button_index:
			binding_str = name
			break

	if binding_str == "":
		_stop_listening()
		return

	_apply_binding(binding_str)

func _handle_joy_binding(event: InputEventJoypadButton) -> void:
	"""Handles gamepad button binding (supports combinations)"""
	if event.pressed:
		# Add button to pressed list
		var button_name: String = ""
		for name in Keybinds.JOY_MAP.keys():
			if Keybinds.JOY_MAP[name] == event.button_index:
				button_name = name
				break

		if button_name != "" and button_name not in pressed_joy_buttons:
			pressed_joy_buttons.append(button_name)
			# Also add to combo list if not already there
			if button_name not in joy_combo_to_bind:
				joy_combo_to_bind.append(button_name)

			# Update display to show current combo
			binding_button.text = "+".join(joy_combo_to_bind)
	else:
		# Button released - remove from currently pressed list
		var button_name: String = ""
		for name in Keybinds.JOY_MAP.keys():
			if Keybinds.JOY_MAP[name] == event.button_index:
				button_name = name
				break

		if button_name in pressed_joy_buttons:
			pressed_joy_buttons.erase(button_name)

		# Only apply binding when ALL buttons have been released
		if pressed_joy_buttons.size() == 0 and joy_combo_to_bind.size() > 0:
			var binding_str = "+".join(joy_combo_to_bind)
			_apply_binding(binding_str)

func _handle_joy_motion_binding(event: InputEventJoypadMotion) -> void:
	"""Handles gamepad analog stick motion binding"""
	# Only trigger when axis movement exceeds threshold to avoid capturing drift
	if abs(event.axis_value) < 0.5:
		return

	# Find the motion name in the JOY_MAP
	var motion_name: String = ""
	for name in Keybinds.JOY_MAP.keys():
		var joy_data = Keybinds.JOY_MAP[name]
		if joy_data is String:
			# Parse format "0:axis:value"
			var parts = joy_data.split(":")
			if parts.size() == 3:
				var map_axis = int(parts[1])
				var map_value = float(parts[2])
				# Check if axis matches and direction matches (same sign)
				if map_axis == event.axis and sign(map_value) == sign(event.axis_value):
					motion_name = name
					break

	if motion_name == "":
		_stop_listening()
		return

	# Apply the binding immediately (analog stick doesn't support combos)
	_apply_binding(motion_name)

func _apply_binding(binding_str: String) -> void:
	"""Applies the captured binding after checking for conflicts"""
	# Check for conflicts
	var conflict_action = Keybinds.find_conflict(binding_str, binding_type, action_name)

	if conflict_action != "":
		# Emit signal to parent to handle conflict dialog
		binding_requested.emit(action_name, binding_type)
		_show_conflict_dialog(conflict_action, binding_str)
	else:
		# No conflict, apply directly
		_set_binding(binding_str)
		_stop_listening()

func _set_binding(binding_str: String) -> void:
	"""Sets the binding without conflict checking"""
	if binding_type == "keyboard":
		Keybinds.set_keybind(action_name, binding_str)
	else:
		Keybinds.set_gamepad_bind(action_name, binding_str)

func _show_conflict_dialog(conflict_action: String, binding_str: String) -> void:
	"""Shows conflict dialog and handles user response"""
	# Create confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.theme = BaseTheme
	dialog.dialog_text = "'%s' is already bound to '%s'.\nSwap bindings?" % [
		binding_str,
		Keybinds.get_action_label(conflict_action)
	]
	dialog.title = "Binding Conflict"
	dialog.get_label().add_theme_font_size_override("font_size", 16)

	# Add swap button
	dialog.add_cancel_button("Cancel")
	dialog.get_ok_button().text = "Swap"

	dialog.confirmed.connect(func():
		Keybinds.swap_bindings(action_name, conflict_action, binding_type)
		_stop_listening()
	)

	dialog.canceled.connect(func():
		_stop_listening()
	)

	# Add to scene and show
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func _on_clear_button_pressed() -> void:
	"""Called when user clicks clear button"""
	Keybinds.clear_binding(action_name, binding_type)
	_update_display()

func _on_binding_changed(changed_action: String, changed_type: String) -> void:
	"""Called when any binding changes"""
	if changed_action == action_name and changed_type == binding_type:
		_update_display()

func _on_bindings_reset() -> void:
	"""Called when all bindings are reset"""
	_update_display()
