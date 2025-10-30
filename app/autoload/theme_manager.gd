extends Node
# ThemeManager - Manages theme switching and application across all UI elements
# Uses BaseTheme as foundation and applies color overrides programmatically

const BaseTheme = preload("res://themes/BaseTheme.res")

# Theme color palette definitions
# Each theme defines colors for various UI elements
var theme_palettes: Dictionary = {
	"Dark": {
		# Default dark theme - very dark colors for true dark mode
		"bg_primary": Color("000000"),      # Main background - pure black
		"bg_secondary": Color("0a0a0a"),    # Secondary panels - nearly black
		"bg_tertiary": Color("141414"),     # Elevated elements - very dark gray
		"text_primary": Color("ffffff"),    # Main text - pure white
		"text_secondary": Color("c0c0c0"),  # Secondary text - light gray
		"text_disabled": Color("808080"),   # Disabled text - medium gray
		"accent": Color("2a7edf"),          # Primary accent - blue
		"accent_hover": Color("3a8eef"),    # Hovered accent - brighter blue
		"accent_pressed": Color("1a6ecf"),  # Pressed accent - darker blue
		"border": Color("2a2a2a"),          # Borders - very dark gray
		"selection": Color("2a7edf40"),     # Selection highlight - translucent blue
	},

	"Light": {
		# Light theme - inverted dark theme
		"bg_primary": Color("f5f5f5"),
		"bg_secondary": Color("ffffff"),
		"bg_tertiary": Color("e8e8e8"),
		"text_primary": Color("1a1a1a"),
		"text_secondary": Color("505050"),
		"text_disabled": Color("a0a0a0"),
		"accent": Color("2196f3"),
		"accent_hover": Color("42a5f5"),
		"accent_pressed": Color("1976d2"),
		"border": Color("d0d0d0"),
		"selection": Color("2196f340"),
	},

	"Monokai": {
		# Monokai - iconic code editor theme
		"bg_primary": Color("272822"),
		"bg_secondary": Color("2d2e27"),
		"bg_tertiary": Color("3e3d32"),
		"text_primary": Color("f8f8f2"),
		"text_secondary": Color("a6a384"),
		"text_disabled": Color("75715e"),
		"accent": Color("66d9ef"),          # Cyan
		"accent_hover": Color("7ee8ff"),
		"accent_pressed": Color("4dc9df"),
		"border": Color("49483e"),
		"selection": Color("66d9ef40"),
	},

	"Dracula": {
		# Dracula - popular purple theme
		"bg_primary": Color("282a36"),
		"bg_secondary": Color("2f3241"),
		"bg_tertiary": Color("363849"),
		"text_primary": Color("f8f8f2"),
		"text_secondary": Color("bfbfbf"),
		"text_disabled": Color("6272a4"),
		"accent": Color("bd93f9"),          # Purple
		"accent_hover": Color("cda9ff"),
		"accent_pressed": Color("ad83e9"),
		"border": Color("44475a"),
		"selection": Color("bd93f940"),
	},

	"Solarized Dark": {
		# Solarized Dark - precision colors
		"bg_primary": Color("002b36"),
		"bg_secondary": Color("073642"),
		"bg_tertiary": Color("0e4753"),
		"text_primary": Color("839496"),
		"text_secondary": Color("657b83"),
		"text_disabled": Color("586e75"),
		"accent": Color("268bd2"),          # Blue
		"accent_hover": Color("3a9be2"),
		"accent_pressed": Color("167bc2"),
		"border": Color("073642"),
		"selection": Color("268bd240"),
	},

	"Nord": {
		# Nord - arctic bluish theme
		"bg_primary": Color("2e3440"),
		"bg_secondary": Color("3b4252"),
		"bg_tertiary": Color("434c5e"),
		"text_primary": Color("eceff4"),
		"text_secondary": Color("d8dee9"),
		"text_disabled": Color("4c566a"),
		"accent": Color("88c0d0"),          # Frost cyan
		"accent_hover": Color("98d0e0"),
		"accent_pressed": Color("78b0c0"),
		"border": Color("4c566a"),
		"selection": Color("88c0d040"),
	},

	"Gruvbox": {
		# Gruvbox - retro warm colors
		"bg_primary": Color("282828"),
		"bg_secondary": Color("3c3836"),
		"bg_tertiary": Color("504945"),
		"text_primary": Color("ebdbb2"),
		"text_secondary": Color("d5c4a1"),
		"text_disabled": Color("928374"),
		"accent": Color("fe8019"),          # Orange
		"accent_hover": Color("ff9029"),
		"accent_pressed": Color("ee7009"),
		"border": Color("504945"),
		"selection": Color("fe801940"),
	},

	"One Dark": {
		# One Dark - Atom's iconic theme
		"bg_primary": Color("282c34"),
		"bg_secondary": Color("2c313a"),
		"bg_tertiary": Color("353b45"),
		"text_primary": Color("abb2bf"),
		"text_secondary": Color("828997"),
		"text_disabled": Color("5c6370"),
		"accent": Color("61afef"),          # Blue
		"accent_hover": Color("71bfff"),
		"accent_pressed": Color("519fdf"),
		"border": Color("3e4451"),
		"selection": Color("61afef40"),
	},

	"Tokyo Night": {
		# Tokyo Night - modern dark theme
		"bg_primary": Color("1a1b26"),
		"bg_secondary": Color("24283b"),
		"bg_tertiary": Color("2f3549"),
		"text_primary": Color("a9b1d6"),
		"text_secondary": Color("787c99"),
		"text_disabled": Color("565f89"),
		"accent": Color("7aa2f7"),          # Blue
		"accent_hover": Color("8ab2ff"),
		"accent_pressed": Color("6a92e7"),
		"border": Color("414868"),
		"selection": Color("7aa2f740"),
	},

	"Cobalt": {
		# Cobalt - deep blue theme
		"bg_primary": Color("002240"),
		"bg_secondary": Color("003050"),
		"bg_tertiary": Color("004060"),
		"text_primary": Color("ffffff"),
		"text_secondary": Color("c0c0c0"),
		"text_disabled": Color("808080"),
		"accent": Color("0088ff"),          # Bright blue
		"accent_hover": Color("1098ff"),
		"accent_pressed": Color("0078ef"),
		"border": Color("004060"),
		"selection": Color("0088ff40"),
	},

	"Material": {
		# Material - Google's material design
		"bg_primary": Color("263238"),
		"bg_secondary": Color("2e3c43"),
		"bg_tertiary": Color("37474f"),
		"text_primary": Color("eceff1"),
		"text_secondary": Color("b0bec5"),
		"text_disabled": Color("546e7a"),
		"accent": Color("00bcd4"),          # Cyan
		"accent_hover": Color("10cce4"),
		"accent_pressed": Color("00acc4"),
		"border": Color("455a64"),
		"selection": Color("00bcd440"),
	},

	"Atom One Light": {
		# Atom One Light - light variant
		"bg_primary": Color("fafafa"),
		"bg_secondary": Color("ffffff"),
		"bg_tertiary": Color("f0f0f0"),
		"text_primary": Color("383a42"),
		"text_secondary": Color("696c77"),
		"text_disabled": Color("a0a1a7"),
		"accent": Color("4078f2"),          # Blue
		"accent_hover": Color("5088ff"),
		"accent_pressed": Color("3068e2"),
		"border": Color("e0e0e0"),
		"selection": Color("4078f240"),
	},
}

# Current theme state
var current_theme: String = "Dark"
var current_palette: Dictionary = {}

# Groups to apply themes to
var ui_groups: Array[String] = []

func _ready() -> void:
	# Initialize UI groups to apply themes to
	# Use string literals to match Group autoload constants
	ui_groups = [
		"OPTIONS_MENU",
		"KEYBINDS_MENU",
		"GAMEPAD_MENU",
		"SYSTEM_MENU",
		"GLOBAL_MENU",
		"RESOURCES_MENU",
		"CONTEXT_MENU",
		"PLATE_VIEW",
		"MAP_VIEW",
		"CONFIRMATION_MODAL",
		"INTERFACE",
	]

	# Initialize current_palette with Dark theme to avoid invalid access errors
	# This ensures widgets that load early have a valid palette
	current_palette = theme_palettes["Dark"]

	# Load saved theme from config (this may change current_theme but palette loads later)
	load_from_config()

	# Use Queue system to defer theme application until UI is ready
	# This ensures proper execution order after all autoloads and initial UI loads
	var theme_item = Queue.Item.builder()\
		.comment("Apply initial theme on startup: %s" % current_theme)\
		.condition(func(): return _is_ui_ready())\
		.task(func():
			print("ThemeManager: Applying saved theme '%s' on startup" % current_theme)
			apply_theme(current_theme))\
		.expiry(10.0)\
		.build()
	Queue.enqueue(theme_item)

func _is_ui_ready() -> bool:
	"""Check if UI nodes are loaded and ready for theming"""
	# Check if at least one UI group has nodes
	for group_name in ui_groups:
		var nodes = get_tree().get_nodes_in_group(group_name)
		if nodes.size() > 0:
			print("ThemeManager: UI ready - found %d nodes in group '%s'" % [nodes.size(), group_name])
			return true
	print("ThemeManager: UI not ready yet - no nodes in any UI groups")
	return false

func get_theme_list() -> Array[String]:
	"""Returns list of all available theme names"""
	var themes: Array[String] = []
	for theme_name in theme_palettes.keys():
		themes.append(theme_name)
	return themes

func apply_theme(theme_name: String) -> void:
	"""Applies the specified theme to all UI elements"""
	if not theme_palettes.has(theme_name):
		push_warning("Theme '%s' not found, using Dark theme" % theme_name)
		theme_name = "Dark"

	current_theme = theme_name
	current_palette = theme_palettes[theme_name]

	# Apply theme to all UI root nodes via Finder
	_apply_to_all_ui_nodes()

func _apply_to_all_ui_nodes() -> void:
	"""Finds and applies theme colors to all UI nodes"""
	# Apply to all nodes in UI groups - recursively to include children
	for group_name in ui_groups:
		var nodes = get_tree().get_nodes_in_group(group_name)
		for node in nodes:
			if node is Control:
				_apply_theme_recursive(node)  # Apply recursively, not just to root

	# Also apply to the root interface node and its children
	var interface_nodes = get_tree().get_nodes_in_group("INTERFACE")
	for interface in interface_nodes:
		_apply_theme_recursive(interface)

func _apply_theme_recursive(node: Node) -> void:
	"""Recursively applies theme to a node and all its children"""
	if node is Control:
		_apply_theme_to_node(node)

	for child in node.get_children():
		_apply_theme_recursive(child)

func _apply_theme_to_node(control: Control) -> void:
	"""Applies theme color overrides to a specific control node"""
	# Apply panel background colors
	if control is PanelContainer or control is Panel:
		control.add_theme_stylebox_override("panel", _create_panel_stylebox())

	# Apply button colors
	if control is Button:
		control.add_theme_stylebox_override("normal", _create_button_stylebox("normal"))
		control.add_theme_stylebox_override("hover", _create_button_stylebox("hover"))
		control.add_theme_stylebox_override("pressed", _create_button_stylebox("pressed"))
		control.add_theme_stylebox_override("disabled", _create_button_stylebox("disabled"))
		control.add_theme_color_override("font_color", current_palette["text_primary"])
		control.add_theme_color_override("font_hover_color", current_palette["text_primary"])
		control.add_theme_color_override("font_pressed_color", current_palette["text_primary"])
		control.add_theme_color_override("font_disabled_color", current_palette["text_disabled"])

	# Apply label colors - BUT preserve group colors and other custom overrides
	if control is Label:
		# Check if this label is part of a group widget or has custom colors
		# Look for markers: node name contains "Group", parent is target_group_widget, etc.
		var has_custom_color = _has_custom_color_override(control)

		# Only apply theme color if no custom color is set
		if not has_custom_color:
			control.add_theme_color_override("font_color", current_palette["text_primary"])

	# Apply line edit colors
	if control is LineEdit:
		control.add_theme_color_override("font_color", current_palette["text_primary"])
		control.add_theme_color_override("font_placeholder_color", current_palette["text_secondary"])
		control.add_theme_color_override("selection_color", current_palette["selection"])
		control.add_theme_color_override("caret_color", current_palette["accent"])

	# Apply rich text label colors
	if control is RichTextLabel:
		control.add_theme_color_override("default_color", current_palette["text_primary"])
		control.add_theme_color_override("selection_color", current_palette["selection"])

func _has_custom_color_override(control: Control) -> bool:
	"""Check if a control has a custom color that should be preserved"""
	# Check if node is part of target group widget (group colors)
	var parent = control.get_parent()
	while parent != null:
		if parent.get_script():
			var script_path = parent.get_script().resource_path
			if "target_group" in script_path or "focus_plate" in script_path:
				# This is a group label that should preserve its color
				return true
		parent = parent.get_parent()

	# Check if the label has "Group" in its name (group labels)
	if "Group" in control.name:
		return true

	return false

func _create_panel_stylebox() -> StyleBoxFlat:
	"""Creates a StyleBoxFlat for panels with current theme colors"""
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = current_palette["bg_secondary"]
	stylebox.border_color = current_palette["border"]
	stylebox.set_border_width_all(1)
	stylebox.set_corner_radius_all(4)
	return stylebox

func _create_button_stylebox(state: String) -> StyleBoxFlat:
	"""Creates a StyleBoxFlat for buttons in different states"""
	var stylebox = StyleBoxFlat.new()

	match state:
		"normal":
			stylebox.bg_color = current_palette["bg_tertiary"]
			stylebox.border_color = current_palette["border"]
		"hover":
			stylebox.bg_color = current_palette["accent_hover"]
			stylebox.border_color = current_palette["accent"]
		"pressed":
			stylebox.bg_color = current_palette["accent_pressed"]
			stylebox.border_color = current_palette["accent"]
		"disabled":
			stylebox.bg_color = current_palette["bg_tertiary"]
			stylebox.border_color = current_palette["border"]

	stylebox.set_border_width_all(1)
	stylebox.set_corner_radius_all(4)
	stylebox.set_content_margin_all(8)

	return stylebox

func _get_config_path() -> String:
	"""Gets the config file path, accessing io autoload safely"""
	# Access io through get_node to avoid static analysis errors
	var io_node = get_node_or_null("/root/io")
	if io_node and io_node.has_method("get_dir"):
		return io_node.get_dir() + "options.cfg"
	else:
		# Fallback to user:// if io is not available
		return "user://options.cfg"

func load_from_config() -> void:
	"""Loads the saved theme from config file"""
	var config = ConfigFile.new()
	var config_path = _get_config_path()
	var err = config.load(config_path)

	if err == OK:
		current_theme = config.get_value("display", "theme", "Dark")
		# Validate and load the palette immediately
		if not theme_palettes.has(current_theme):
			push_warning("Saved theme '%s' not found, using Dark theme" % current_theme)
			current_theme = "Dark"
		current_palette = theme_palettes[current_theme]
		print("ThemeManager: Loaded theme from config: '%s'" % current_theme)
	else:
		current_theme = "Dark"
		current_palette = theme_palettes["Dark"]
		print("ThemeManager: Config load failed (err %d), using default 'Dark'" % err)

func save_to_config(theme_name: String) -> void:
	"""Saves the theme preference to config file"""
	var config = ConfigFile.new()
	var config_path = _get_config_path()

	# Load existing config first
	config.load(config_path)

	# Set theme value
	config.set_value("display", "theme", theme_name)

	# Save config
	config.save(config_path)

func get_current_theme() -> String:
	"""Returns the name of the currently active theme"""
	return current_theme

func get_current_palette() -> Dictionary:
	"""Returns the color palette of the currently active theme"""
	return current_palette
