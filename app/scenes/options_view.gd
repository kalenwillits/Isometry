extends CanvasLayer

var CONFIG_FILE_PATH: String = io.get_dir() + "options.cfg"
const CONFIG_SECTION_DISPLAY: String = "display"
const CONFIG_SECTION_INPUT: String = "input"

# Available resolution presets - Top 12 common gaming resolutions
var resolutions: Array[Vector2i] = [
	Vector2i(800, 600),       # Legacy 4:3
	Vector2i(1280, 720),      # 720p HD (16:9)
	Vector2i(1280, 800),      # Steam Deck (16:10)
	Vector2i(1366, 768),      # Common laptop (16:9)
	Vector2i(1600, 900),      # HD+ (16:9)
	Vector2i(1920, 1080),     # 1080p Full HD (16:9) - Most common
	Vector2i(1920, 1200),     # WUXGA (16:10)
	Vector2i(2560, 1080),     # Ultrawide 1080p (21:9)
	Vector2i(2560, 1440),     # 1440p Quad HD (16:9)
	Vector2i(2560, 1600),     # 1600p (16:10)
	Vector2i(3440, 1440),     # Ultrawide 1440p (21:9)
	Vector2i(3840, 2160)      # 4K Ultra HD (16:9)
]

# Icon mode options
var icon_modes: Array[String] = [
	"Keyboard",
	"Generic",
	"XBox",
	"PlayStation",
	"Nintendo",
	"None"
]

# Theme options - populated from ThemeManager
var themes: Array[String] = []

var current_resolution_index: int = 5  # Default to 1920x1080
var current_icon_mode_index: int = 0  # Default to Keyboard
var current_theme_index: int = 0  # Default to Dark theme
var is_fullscreen: bool = false
var config: ConfigFile = ConfigFile.new()

# State tracking for confirmation flow
var previous_resolution_index: int = 5
var previous_fullscreen: bool = false
var previous_theme_index: int = 0
var has_unsaved_changes: bool = false
var save_button: Button = null

func _ready() -> void:
	visible = false
	add_to_group(Group.OPTIONS_MENU)
	# Load available themes from ThemeManager
	themes = ThemeManager.get_theme_list()
	_load_config()
	_apply_saved_settings()
	_create_option_items()

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		ThemeManager._apply_theme_recursive(self)

func _load_config() -> void:
	var err = config.load(CONFIG_FILE_PATH)
	if err == OK:
		# Load display settings
		is_fullscreen = config.get_value(CONFIG_SECTION_DISPLAY, "fullscreen", false)
		var saved_width = config.get_value(CONFIG_SECTION_DISPLAY, "resolution_width", 1920)
		var saved_height = config.get_value(CONFIG_SECTION_DISPLAY, "resolution_height", 1080)

		# Find matching resolution index
		var saved_res = Vector2i(saved_width, saved_height)
		for i in range(resolutions.size()):
			if resolutions[i] == saved_res:
				current_resolution_index = i
				break

		# Load input settings
		var saved_icon_mode = config.get_value(CONFIG_SECTION_INPUT, "icon_mode", "Keyboard")
		for i in range(icon_modes.size()):
			if icon_modes[i] == saved_icon_mode:
				current_icon_mode_index = i
				break

		# Load theme settings
		var saved_theme = config.get_value(CONFIG_SECTION_DISPLAY, "theme", "Dark")
		for i in range(themes.size()):
			if themes[i] == saved_theme:
				current_theme_index = i
				break

func _save_config() -> void:
	# Save display settings
	config.set_value(CONFIG_SECTION_DISPLAY, "fullscreen", is_fullscreen)
	config.set_value(CONFIG_SECTION_DISPLAY, "resolution_width", resolutions[current_resolution_index].x)
	config.set_value(CONFIG_SECTION_DISPLAY, "resolution_height", resolutions[current_resolution_index].y)
	config.set_value(CONFIG_SECTION_DISPLAY, "theme", themes[current_theme_index])

	# Save input settings
	config.set_value(CONFIG_SECTION_INPUT, "icon_mode", icon_modes[current_icon_mode_index])

	config.save(CONFIG_FILE_PATH)

	# Also save theme to ThemeManager
	ThemeManager.save_to_config(themes[current_theme_index])

func _apply_saved_settings() -> void:
	# Apply fullscreen setting
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolutions[current_resolution_index])

func _create_option_items() -> void:
	var options_list = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/OptionsList

	# Connect cancel button
	$Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/CancelContainer/CancelButton.pressed.connect(_on_cancel_pressed)

	# Create Fullscreen toggle
	_create_fullscreen_option(options_list)

	# Create Resolution scroll-through
	_create_resolution_option(options_list)

	# Create Theme scroll-through
	_create_theme_option(options_list)

	# Create Icon Mode scroll-through
	_create_icon_mode_option(options_list)

	# Create Save button (initially hidden)
	_create_save_button(options_list)

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

func _create_theme_option(parent: VBoxContainer) -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(360, 32)

	# Label
	var label = Label.new()
	label.text = "Theme"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(label)

	# Left arrow button
	var left_button = Button.new()
	left_button.custom_minimum_size = Vector2(24, 24)
	left_button.text = "<"
	left_button.add_theme_font_size_override("font_size", 16)
	left_button.pressed.connect(_on_theme_previous)
	hbox.add_child(left_button)

	# Theme display label
	var theme_label = Label.new()
	theme_label.name = "ThemeLabel"
	theme_label.custom_minimum_size = Vector2(140, 24)
	theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	theme_label.add_theme_font_size_override("font_size", 16)
	theme_label.text = themes[current_theme_index]
	hbox.add_child(theme_label)

	# Right arrow button
	var right_button = Button.new()
	right_button.custom_minimum_size = Vector2(24, 24)
	right_button.text = ">"
	right_button.add_theme_font_size_override("font_size", 16)
	right_button.pressed.connect(_on_theme_next)
	hbox.add_child(right_button)

	parent.add_child(hbox)

func _on_fullscreen_toggled(button: Button) -> void:
	is_fullscreen = !is_fullscreen
	button.text = "ON" if is_fullscreen else "OFF"
	has_unsaved_changes = true
	_update_save_button_visibility()

func _on_resolution_previous() -> void:
	current_resolution_index = (current_resolution_index - 1 + resolutions.size()) % resolutions.size()
	_update_resolution_display()
	has_unsaved_changes = true
	_update_save_button_visibility()

func _on_resolution_next() -> void:
	current_resolution_index = (current_resolution_index + 1) % resolutions.size()
	_update_resolution_display()
	has_unsaved_changes = true
	_update_save_button_visibility()

func _update_resolution_display() -> void:
	var options_list = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/OptionsList
	var resolution_row = options_list.get_children()[1]  # Second row is resolution
	var res_label = resolution_row.get_node("ResolutionLabel")
	var current_res = resolutions[current_resolution_index]
	res_label.text = "%dx%d" % [current_res.x, current_res.y]

func _on_theme_previous() -> void:
	current_theme_index = (current_theme_index - 1 + themes.size()) % themes.size()
	_update_theme_display()
	_apply_theme_preview()
	has_unsaved_changes = true
	_update_save_button_visibility()

func _on_theme_next() -> void:
	current_theme_index = (current_theme_index + 1) % themes.size()
	_update_theme_display()
	_apply_theme_preview()
	has_unsaved_changes = true
	_update_save_button_visibility()

func _update_theme_display() -> void:
	var options_list = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/OptionsList
	var theme_row = options_list.get_children()[2]  # Third row is theme
	var theme_label = theme_row.get_node("ThemeLabel")
	theme_label.text = themes[current_theme_index]

func _apply_theme_preview() -> void:
	"""Applies the theme as a preview (before saving)"""
	ThemeManager.apply_theme(themes[current_theme_index])

func _apply_display_settings_immediately() -> void:
	# Apply fullscreen setting
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolutions[current_resolution_index])

	# Save to config immediately
	config.set_value(CONFIG_SECTION_DISPLAY, "fullscreen", is_fullscreen)
	config.set_value(CONFIG_SECTION_DISPLAY, "resolution_width", resolutions[current_resolution_index].x)
	config.set_value(CONFIG_SECTION_DISPLAY, "resolution_height", resolutions[current_resolution_index].y)
	config.save(CONFIG_FILE_PATH)

func _create_icon_mode_option(parent: VBoxContainer) -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(360, 32)

	# Label
	var label = Label.new()
	label.text = "Input Icons"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	hbox.add_child(label)

	# Left arrow button
	var left_button = Button.new()
	left_button.custom_minimum_size = Vector2(24, 24)
	left_button.text = "<"
	left_button.add_theme_font_size_override("font_size", 16)
	left_button.pressed.connect(_on_icon_mode_previous)
	hbox.add_child(left_button)

	# Icon mode display label
	var mode_label = Label.new()
	mode_label.name = "IconModeLabel"
	mode_label.custom_minimum_size = Vector2(120, 24)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 16)
	mode_label.text = icon_modes[current_icon_mode_index]
	hbox.add_child(mode_label)

	# Right arrow button
	var right_button = Button.new()
	right_button.custom_minimum_size = Vector2(24, 24)
	right_button.text = ">"
	right_button.add_theme_font_size_override("font_size", 16)
	right_button.pressed.connect(_on_icon_mode_next)
	hbox.add_child(right_button)

	parent.add_child(hbox)

func _on_icon_mode_previous() -> void:
	current_icon_mode_index = (current_icon_mode_index - 1 + icon_modes.size()) % icon_modes.size()
	_update_icon_mode_display()
	_apply_icon_mode_immediately()

func _on_icon_mode_next() -> void:
	current_icon_mode_index = (current_icon_mode_index + 1) % icon_modes.size()
	_update_icon_mode_display()
	_apply_icon_mode_immediately()

func _apply_icon_mode_immediately() -> void:
	# Save icon mode to config immediately
	config.set_value(CONFIG_SECTION_INPUT, "icon_mode", icon_modes[current_icon_mode_index])
	config.save(CONFIG_FILE_PATH)
	# Notify InputIconMapper to reload and emit signal
	InputIconMapper.reload_from_config()

func _update_icon_mode_display() -> void:
	var options_list = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/OptionsList
	var icon_mode_row = options_list.get_children()[3]  # Fourth row is icon mode
	var mode_label = icon_mode_row.get_node("IconModeLabel")
	mode_label.text = icon_modes[current_icon_mode_index]

func open_view() -> void:
	# Capture current settings as "previous" when opening
	previous_resolution_index = current_resolution_index
	previous_fullscreen = is_fullscreen
	previous_theme_index = current_theme_index
	has_unsaved_changes = false
	_update_save_button_visibility()
	visible = true

func close_view() -> void:
	visible = false

func _unhandled_input(_event: InputEvent) -> void:
	if not visible:
		return

	# Cancel action is handled by UIStateMachine via interface.gd

func _create_save_button(parent: VBoxContainer) -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(360, 32)
	hbox.add_theme_constant_override("separation", 8)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Save button
	save_button = Button.new()
	save_button.custom_minimum_size = Vector2(120, 32)
	save_button.text = "Save"
	save_button.add_theme_font_size_override("font_size", 18)
	save_button.pressed.connect(_on_save_pressed)
	save_button.visible = false  # Initially hidden
	hbox.add_child(save_button)

	parent.add_child(hbox)

func _update_save_button_visibility() -> void:
	if save_button:
		save_button.visible = has_unsaved_changes

func _on_save_pressed() -> void:
	# Capture current settings as "previous" for potential revert
	previous_resolution_index = current_resolution_index
	previous_fullscreen = is_fullscreen

	# Apply the settings immediately
	_apply_display_settings_immediately()

	# Hide options menu while showing confirmation
	visible = false

	# Open confirmation modal with 9-second countdown
	get_parent().get_node("ConfirmationModal").open_modal(
		"Keep these display settings?",
		_on_confirm_settings,      # Yes callback
		_on_revert_settings,        # No callback
		9                           # 9 second countdown
	)

func _on_confirm_settings() -> void:
	# User confirmed - save the settings to config
	_save_config()
	has_unsaved_changes = false
	_update_save_button_visibility()
	# Show options menu again
	visible = true

func _on_revert_settings() -> void:
	# User rejected or countdown expired - revert to previous settings
	is_fullscreen = previous_fullscreen
	current_resolution_index = previous_resolution_index
	current_theme_index = previous_theme_index

	# Apply the reverted settings
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolutions[current_resolution_index])

	# Revert theme
	ThemeManager.apply_theme(themes[current_theme_index])

	# Update UI to reflect reverted settings
	_update_fullscreen_button_text()
	_update_resolution_display()
	_update_theme_display()

	has_unsaved_changes = false
	_update_save_button_visibility()
	# Show options menu again
	visible = true

func _update_fullscreen_button_text() -> void:
	var options_list = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/OptionsList
	var fullscreen_row = options_list.get_children()[0]  # First row is fullscreen
	var toggle_button = fullscreen_row.get_children()[1]  # Button is second child
	if toggle_button is Button:
		toggle_button.text = "ON" if is_fullscreen else "OFF"

func _on_cancel_pressed() -> void:
	# If there are unsaved changes, revert them
	if has_unsaved_changes:
		is_fullscreen = previous_fullscreen
		current_resolution_index = previous_resolution_index
		current_theme_index = previous_theme_index

		# Apply the reverted settings
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(resolutions[current_resolution_index])

		# Revert theme
		ThemeManager.apply_theme(themes[current_theme_index])

		# Update UI
		_update_fullscreen_button_text()
		_update_resolution_display()
		_update_theme_display()

		has_unsaved_changes = false
		_update_save_button_visibility()

	# Trigger state transition instead of closing directly
	UIStateMachine.handle_cancel()
