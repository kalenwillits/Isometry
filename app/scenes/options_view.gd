extends CanvasLayer

const CONFIG_FILE_PATH: String = "user://options.cfg"
const CONFIG_SECTION: String = "display"

# Available resolution presets
var resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

var current_resolution_index: int = 1  # Default to 1920x1080
var is_fullscreen: bool = false
var config: ConfigFile = ConfigFile.new()

# Previous settings for revert functionality
var previous_resolution_index: int = 1
var previous_fullscreen: bool = false

func _ready() -> void:
	visible = false
	add_to_group(Group.OPTIONS_MENU)
	_load_config()
	_apply_saved_settings()
	_create_option_items()

func _load_config() -> void:
	var err = config.load(CONFIG_FILE_PATH)
	if err == OK:
		is_fullscreen = config.get_value(CONFIG_SECTION, "fullscreen", false)
		var saved_width = config.get_value(CONFIG_SECTION, "resolution_width", 1920)
		var saved_height = config.get_value(CONFIG_SECTION, "resolution_height", 1080)

		# Find matching resolution index
		var saved_res = Vector2i(saved_width, saved_height)
		for i in range(resolutions.size()):
			if resolutions[i] == saved_res:
				current_resolution_index = i
				break

func _save_config() -> void:
	config.set_value(CONFIG_SECTION, "fullscreen", is_fullscreen)
	config.set_value(CONFIG_SECTION, "resolution_width", resolutions[current_resolution_index].x)
	config.set_value(CONFIG_SECTION, "resolution_height", resolutions[current_resolution_index].y)
	config.save(CONFIG_FILE_PATH)

func _apply_saved_settings() -> void:
	# Apply fullscreen setting
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolutions[current_resolution_index])

func _create_option_items() -> void:
	var options_list = $Overlay/CenterContainer/PanelContainer/VBox/OptionsList

	# Create Fullscreen toggle
	_create_fullscreen_option(options_list)

	# Create Resolution scroll-through
	_create_resolution_option(options_list)

	# Create Apply button
	_create_apply_button()

func _create_fullscreen_option(parent: VBoxContainer) -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(360, 32)

	# Label
	var label = Label.new()
	label.text = "Fullscreen"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(label)

	# Toggle button
	var toggle_button = Button.new()
	toggle_button.custom_minimum_size = Vector2(80, 24)
	toggle_button.text = "ON" if is_fullscreen else "OFF"
	toggle_button.add_theme_font_size_override("font_size", 16)
	toggle_button.pressed.connect(_on_fullscreen_toggled.bind(toggle_button))
	hbox.add_child(toggle_button)

	parent.add_child(hbox)

func _create_resolution_option(parent: VBoxContainer) -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(360, 32)

	# Label
	var label = Label.new()
	label.text = "Resolution"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(label)

	# Left arrow button
	var left_button = Button.new()
	left_button.custom_minimum_size = Vector2(24, 24)
	left_button.text = "<"
	left_button.add_theme_font_size_override("font_size", 16)
	left_button.pressed.connect(_on_resolution_previous)
	hbox.add_child(left_button)

	# Resolution display label
	var res_label = Label.new()
	res_label.name = "ResolutionLabel"
	res_label.custom_minimum_size = Vector2(120, 24)
	res_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	res_label.add_theme_font_size_override("font_size", 16)
	var current_res = resolutions[current_resolution_index]
	res_label.text = "%dx%d" % [current_res.x, current_res.y]
	hbox.add_child(res_label)

	# Right arrow button
	var right_button = Button.new()
	right_button.custom_minimum_size = Vector2(24, 24)
	right_button.text = ">"
	right_button.add_theme_font_size_override("font_size", 16)
	right_button.pressed.connect(_on_resolution_next)
	hbox.add_child(right_button)

	parent.add_child(hbox)

func _on_fullscreen_toggled(button: Button) -> void:
	is_fullscreen = !is_fullscreen
	button.text = "ON" if is_fullscreen else "OFF"

func _on_resolution_previous() -> void:
	current_resolution_index = (current_resolution_index - 1 + resolutions.size()) % resolutions.size()
	_update_resolution_display()

func _on_resolution_next() -> void:
	current_resolution_index = (current_resolution_index + 1) % resolutions.size()
	_update_resolution_display()

func _update_resolution_display() -> void:
	var options_list = $Overlay/CenterContainer/PanelContainer/VBox/OptionsList
	var resolution_row = options_list.get_children()[1]  # Second row is resolution
	var res_label = resolution_row.get_node("ResolutionLabel")
	var current_res = resolutions[current_resolution_index]
	res_label.text = "%dx%d" % [current_res.x, current_res.y]

func _create_apply_button() -> void:
	var apply_container = $Overlay/CenterContainer/PanelContainer/VBox/ApplyContainer

	# Create Apply button
	var apply_button = Button.new()
	apply_button.custom_minimum_size = Vector2(120, 32)
	apply_button.text = "Apply"
	apply_button.pressed.connect(_on_apply_pressed)
	apply_container.add_child(apply_button)

func _on_apply_pressed() -> void:
	# Store previous settings for potential revert
	previous_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	previous_resolution_index = current_resolution_index

	# Find the current resolution index by getting window size
	if not previous_fullscreen:
		var current_size = DisplayServer.window_get_size()
		for i in range(resolutions.size()):
			if resolutions[i] == current_size:
				previous_resolution_index = i
				break

	# Apply new settings immediately
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolutions[current_resolution_index])

	# Close options view
	close_view()

	# Open confirmation modal with countdown
	get_parent().get_node("ConfirmationModal").open_modal(
		"Keep these display settings?",
		_on_confirm_settings,      # Yes callback
		_on_revert_settings,        # No callback
		9                           # 9 second countdown
	)

func _on_confirm_settings() -> void:
	# User confirmed - save the new settings
	_save_config()

func _on_revert_settings() -> void:
	# User rejected or countdown expired - revert to previous settings
	if previous_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolutions[previous_resolution_index])

	# Update UI to reflect reverted settings
	is_fullscreen = previous_fullscreen
	current_resolution_index = previous_resolution_index

func open_view() -> void:
	visible = true

func close_view() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("menu_cancel"):
		close_view()
		get_viewport().set_input_as_handled()
