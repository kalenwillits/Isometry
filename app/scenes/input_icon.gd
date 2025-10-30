extends Button
# InputIcon - Displays input binding icons or text for a given action
# Automatically adapts based on the user's selected icon mode
# Now clickable with mouse support

const BaseTheme = preload("res://themes/BaseTheme.res")
const UbuntuMonoFont = preload("res://themes/UbuntuMono-Bold.ttf")

signal icon_clicked()

@export var action_name: String = "":
	set(value):
		action_name = value
		if is_node_ready():
			_refresh_display()

@export var icon_size: Vector2i = Vector2i(8, 8)
@export var text_size: int = 8
@export var label_text: String = ""  # Optional label to display after icon

var current_icon_mode: InputIconMapper.IconMode = InputIconMapper.IconMode.KEYBOARD
var content_container: HBoxContainer = null

func _ready() -> void:
	# Set up button properties
	flat = true  # Transparent background
	focus_mode = Control.FOCUS_NONE  # Don't steal keyboard focus
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Create internal container for content with centering
	content_container = HBoxContainer.new()
	content_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content_container.add_theme_constant_override("separation", 4)
	add_child(content_container)

	# Connect button press
	pressed.connect(_on_button_pressed)

	# Connect to icon mode change signal
	InputIconMapper.icon_mode_changed.connect(_on_icon_mode_changed)

	# Connect to keybind changes signal
	Keybinds.binding_changed.connect(_on_binding_changed)

	_refresh_display()

func _on_button_pressed() -> void:
	icon_clicked.emit()

func _exit_tree() -> void:
	# Disconnect signals when removed
	if InputIconMapper.icon_mode_changed.is_connected(_on_icon_mode_changed):
		InputIconMapper.icon_mode_changed.disconnect(_on_icon_mode_changed)
	if Keybinds.binding_changed.is_connected(_on_binding_changed):
		Keybinds.binding_changed.disconnect(_on_binding_changed)

func _on_icon_mode_changed(_new_mode: InputIconMapper.IconMode) -> void:
	_refresh_display()

func _on_binding_changed(changed_action: String, _binding_type: String) -> void:
	"""Called when any keybind changes - refresh if it's our action"""
	if changed_action == action_name:
		refresh()

# Refresh the display based on current action and icon mode
func _refresh_display() -> void:
	# Clear existing children from content container
	if content_container == null:
		return

	for child in content_container.get_children():
		child.queue_free()

	# If no action name, nothing to display
	if action_name == "":
		return

	# Get current icon mode
	current_icon_mode = InputIconMapper.get_icon_mode()

	# If mode is NONE, hide everything
	if current_icon_mode == InputIconMapper.IconMode.NONE:
		visible = false
		return

	visible = true

	# Get action events from InputMap
	if not InputMap.has_action(action_name):
		_add_text_label("?")
		_add_optional_label()
		return

	var events = InputMap.action_get_events(action_name)
	if events.size() == 0:
		_add_text_label("Unbound")
		_add_optional_label()
		return

	# Filter events based on icon mode preference
	var is_gamepad_mode = current_icon_mode != InputIconMapper.IconMode.KEYBOARD and current_icon_mode != InputIconMapper.IconMode.NONE

	# If gamepad mode is selected, prioritize joypad button events
	if is_gamepad_mode:
		# Collect ALL joypad button events for multi-button combos
		var gamepad_events = []
		for event in events:
			if event is InputEventJoypadButton:
				gamepad_events.append(event)

		# Display multi-button combo or single event
		if gamepad_events.size() > 0:
			_display_gamepad_combo(gamepad_events)
		# If no joypad events, fall back to first event
		elif events.size() > 0:
			var display_data = InputIconMapper.event_to_display(events[0], current_icon_mode)
			_display_single_event(display_data)
	else:
		# Keyboard mode: prioritize keyboard/mouse events
		var event_to_display: InputEvent = null
		for event in events:
			if event is InputEventKey or event is InputEventMouseButton:
				event_to_display = event
				break
		# Fall back to first event if no keyboard/mouse events found
		if event_to_display == null and events.size() > 0:
			event_to_display = events[0]

		# Display the single event
		if event_to_display != null:
			var display_data = InputIconMapper.event_to_display(event_to_display, current_icon_mode)

			# Check if this is a keyboard modifier combo (contains "+")
			if display_data.type == "text" and "+" in display_data.value:
				_display_keyboard_combo(display_data.value)
			else:
				_display_single_event(display_data)

	# Add optional label text after the icon
	_add_optional_label()

# Display a single event (icon or text)
func _display_single_event(display_data: Dictionary) -> void:
	match display_data.type:
		"icon":
			_add_icon(display_data.value)
		"text":
			_add_text_label(display_data.value)
		"none":
			pass  # Don't display anything

# Display multiple gamepad buttons as a combo (e.g., A+B+X)
func _display_gamepad_combo(gamepad_events: Array) -> void:
	# Create a nested container with no spacing for tight combo display
	var combo_container = HBoxContainer.new()
	combo_container.add_theme_constant_override("separation", 0)
	combo_container.alignment = BoxContainer.ALIGNMENT_CENTER

	for i in range(gamepad_events.size()):
		var event = gamepad_events[i]
		var display_data = InputIconMapper.event_to_display(event, current_icon_mode)

		# Display the button in combo container
		match display_data.type:
			"icon":
				_add_icon_to_container(display_data.value, combo_container)
			"text":
				_add_text_label_to_container(display_data.value, combo_container)
			"none":
				pass

		# Add "+" separator between buttons (except after last button)
		if i < gamepad_events.size() - 1:
			_add_text_label_to_container("+", combo_container)

	# Add the combo container to main content container
	content_container.add_child(combo_container)

# Display keyboard modifier combo (e.g., "Ctl+Sft+A")
func _display_keyboard_combo(combo_string: String) -> void:
	# Display the entire combo as a single label to avoid spacing between parts
	_add_text_label(combo_string)

# Add an icon to the display
func _add_icon(icon_path: String) -> void:
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = icon_size
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse

	# Load the texture
	var texture = load(icon_path)
	if texture:
		texture_rect.texture = texture
	else:
		# If icon fails to load, show text instead
		push_warning("Failed to load icon: %s" % icon_path)
		texture_rect.queue_free()
		_add_text_label("?")
		return

	content_container.add_child(texture_rect)

# Add a text label to the display
func _add_text_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", UbuntuMonoFont)
	label.add_theme_font_size_override("font_size", text_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse

	content_container.add_child(label)

# Add an icon to a specific container
func _add_icon_to_container(icon_path: String, container: HBoxContainer) -> void:
	var texture_rect = TextureRect.new()
	texture_rect.custom_minimum_size = icon_size
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse

	# Load the texture
	var texture = load(icon_path)
	if texture:
		texture_rect.texture = texture
	else:
		# If icon fails to load, show text instead
		push_warning("Failed to load icon: %s" % icon_path)
		texture_rect.queue_free()
		_add_text_label_to_container("?", container)
		return

	container.add_child(texture_rect)

# Add a text label to a specific container
func _add_text_label_to_container(text: String, container: HBoxContainer) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", UbuntuMonoFont)
	label.add_theme_font_size_override("font_size", text_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse

	container.add_child(label)

# Add optional label text after the icon/key
func _add_optional_label() -> void:
	if label_text != "":
		var label = Label.new()
		label.text = label_text
		label.add_theme_font_size_override("font_size", text_size)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse
		content_container.add_child(label)

# Public method to force refresh (can be called when icon mode changes)
func refresh() -> void:
	_refresh_display()
