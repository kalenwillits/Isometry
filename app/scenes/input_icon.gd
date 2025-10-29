extends Button
# InputIcon - Displays input binding icons or text for a given action
# Automatically adapts based on the user's selected icon mode
# Now clickable with mouse support

signal icon_clicked()

@export var action_name: String = "":
	set(value):
		action_name = value
		if is_node_ready():
			_refresh_display()

@export var icon_size: Vector2i = Vector2i(8, 8)
@export var text_size: int = 8

var current_icon_mode: InputIconMapper.IconMode = InputIconMapper.IconMode.KEYBOARD
var content_container: HBoxContainer = null

func _ready() -> void:
	# Set up button properties
	flat = true  # Transparent background
	focus_mode = Control.FOCUS_NONE  # Don't steal keyboard focus
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	# Create internal container for content
	content_container = HBoxContainer.new()
	add_child(content_container)

	# Connect button press
	pressed.connect(_on_button_pressed)

	# Connect to icon mode change signal
	InputIconMapper.icon_mode_changed.connect(_on_icon_mode_changed)
	_refresh_display()

func _on_button_pressed() -> void:
	icon_clicked.emit()

func _exit_tree() -> void:
	# Disconnect signal when removed
	if InputIconMapper.icon_mode_changed.is_connected(_on_icon_mode_changed):
		InputIconMapper.icon_mode_changed.disconnect(_on_icon_mode_changed)

func _on_icon_mode_changed(_new_mode: InputIconMapper.IconMode) -> void:
	_refresh_display()

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
		return

	var events = InputMap.action_get_events(action_name)
	if events.size() == 0:
		_add_text_label("Unbound")
		return

	# Filter events based on icon mode preference
	var is_gamepad_mode = current_icon_mode != InputIconMapper.IconMode.KEYBOARD and current_icon_mode != InputIconMapper.IconMode.NONE
	var event_to_display: InputEvent = null

	# If gamepad mode is selected, prioritize joypad button events
	if is_gamepad_mode:
		# First, try to find joypad button events
		for event in events:
			if event is InputEventJoypadButton:
				event_to_display = event
				break
		# If no joypad events, fall back to first event
		if event_to_display == null and events.size() > 0:
			event_to_display = events[0]
	else:
		# Keyboard mode: show first event
		if events.size() > 0:
			event_to_display = events[0]

	# Display the single event
	if event_to_display != null:
		var display_data = InputIconMapper.event_to_display(event_to_display, current_icon_mode)

		match display_data.type:
			"icon":
				_add_icon(display_data.value)
			"text":
				_add_text_label(display_data.value)
			"none":
				pass  # Don't display anything

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
	label.add_theme_font_size_override("font_size", text_size)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse

	# Add a subtle background to text labels
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_box.corner_radius_top_left = 2
	style_box.corner_radius_top_right = 2
	style_box.corner_radius_bottom_left = 2
	style_box.corner_radius_bottom_right = 2
	style_box.content_margin_left = 2
	style_box.content_margin_right = 2
	style_box.content_margin_top = 0
	style_box.content_margin_bottom = 0

	# Create a panel container to hold the label with background
	var panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse
	panel.add_theme_stylebox_override("panel", style_box)
	panel.add_child(label)

	content_container.add_child(panel)

# Public method to force refresh (can be called when icon mode changes)
func refresh() -> void:
	_refresh_display()
