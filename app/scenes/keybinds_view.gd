extends CanvasLayer

const KeybindRowScene = preload("res://scenes/keybind_row.tscn")
const BaseTheme = preload("res://themes/BaseTheme.res")
const ITEMS_PER_PAGE: int = 8

var current_page: int = 0
var total_pages: int = 0
var all_actions: Array = []
var original_bindings: Dictionary = {}
var has_unsaved_changes: bool = false

@onready var keybinds_list: VBoxContainer = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/RowsContainer/KeybindsList
@onready var vbox: VBoxContainer = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox

var navigation_container: HBoxContainer
var buttons_container: HBoxContainer
var page_label: Label
var prev_button: Button
var next_button: Button
var cancel_button: Button
var reset_button: Button
var save_button: Button

func _ready() -> void:
	add_to_group(Group.KEYBINDS_MENU)

	# Store original bindings for cancel/revert
	original_bindings = Keybinds.get_all_bindings()

	# Create UI layout
	_create_navigation_row()
	_create_buttons_row()

	# Listen for binding changes
	Keybinds.binding_changed.connect(_on_binding_changed_anywhere)
	Keybinds.bindings_reset.connect(_refresh_current_page)

	# Load actions and build UI
	_load_actions()
	_calculate_pages()

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_show_page(0)

		# Apply theme after rows are created
		ThemeManager._apply_theme_recursive(self)

		# Update save button visibility
		_update_save_button_visibility()

func _create_navigation_row() -> void:
	# Find or create navigation container
	var nav_node = vbox.get_node_or_null(NodePath("NavigationContainer"))
	if nav_node:
		navigation_container = nav_node as HBoxContainer

	if not navigation_container:
		navigation_container = HBoxContainer.new()
		navigation_container.name = "NavigationContainer"
		# Find the RowsContainer and insert navigation before it
		var rows_container = vbox.get_node_or_null(NodePath("RowsContainer"))
		if rows_container:
			var rows_index = rows_container.get_index()
			vbox.add_child(navigation_container)
			vbox.move_child(navigation_container, rows_index)
		else:
			vbox.add_child(navigation_container)

	# Clear existing children
	for child in navigation_container.get_children():
		child.queue_free()

	# Configure container
	navigation_container.alignment = BoxContainer.ALIGNMENT_CENTER
	navigation_container.add_theme_constant_override("separation", 12)

	# Previous button
	prev_button = Button.new()
	prev_button.text = "←"
	prev_button.custom_minimum_size = Vector2(60, 32)
	prev_button.pressed.connect(_on_prev_page)
	navigation_container.add_child(prev_button)

	# Page label
	page_label = Label.new()
	page_label.text = "1/1"
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.custom_minimum_size = Vector2(80, 32)
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_label.add_theme_font_size_override("font_size", 16)
	navigation_container.add_child(page_label)

	# Next button
	next_button = Button.new()
	next_button.text = "→"
	next_button.custom_minimum_size = Vector2(60, 32)
	next_button.pressed.connect(_on_next_page)
	navigation_container.add_child(next_button)

func _create_buttons_row() -> void:
	# Find or create buttons container
	var btn_node = vbox.get_node_or_null(NodePath("ButtonsContainer/HBox"))
	if btn_node:
		buttons_container = btn_node as HBoxContainer

	if not buttons_container:
		buttons_container = HBoxContainer.new()
		buttons_container.name = "ButtonsContainer"
		vbox.add_child(buttons_container)

	# Clear existing children
	for child in buttons_container.get_children():
		child.queue_free()

	# Configure container
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 12)

	# Cancel button
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(100, 32)
	cancel_button.add_theme_font_size_override("font_size", 16)
	cancel_button.pressed.connect(_on_back_pressed)
	buttons_container.add_child(cancel_button)

	# Reset button
	reset_button = Button.new()
	reset_button.text = "Reset"
	reset_button.custom_minimum_size = Vector2(100, 32)
	reset_button.add_theme_font_size_override("font_size", 16)
	reset_button.pressed.connect(_on_reset_all_pressed)
	buttons_container.add_child(reset_button)

	# Save button
	save_button = Button.new()
	save_button.text = "Save"
	save_button.custom_minimum_size = Vector2(100, 32)
	save_button.add_theme_font_size_override("font_size", 16)
	save_button.pressed.connect(_on_save_pressed)
	save_button.disabled = true  # Initially disabled
	buttons_container.add_child(save_button)

func _load_actions() -> void:
	"""Loads all bindable actions from Keybinds"""
	all_actions = Keybinds.get_all_actions()

func _calculate_pages() -> void:
	"""Calculates total number of pages needed"""
	total_pages = ceil(float(all_actions.size()) / float(ITEMS_PER_PAGE))
	if total_pages == 0:
		total_pages = 1

func _show_page(page_num: int) -> void:
	"""Displays the specified page of keybinds"""
	# Clamp page number
	current_page = clampi(page_num, 0, total_pages - 1)

	# Clear existing rows
	for child in keybinds_list.get_children():
		child.queue_free()

	# Calculate range of actions to display
	var start_idx = current_page * ITEMS_PER_PAGE
	var end_idx = mini(start_idx + ITEMS_PER_PAGE, all_actions.size())

	# Create rows for this page
	for i in range(start_idx, end_idx):
		var action_name = all_actions[i]
		var row = KeybindRowScene.instantiate()
		row.action_name = action_name
		row.binding_type = "keyboard"
		keybinds_list.add_child(row)

	# Apply theme to newly created rows
	for child in keybinds_list.get_children():
		ThemeManager._apply_theme_recursive(child)

	# Update page label
	page_label.text = "%d / %d" % [current_page + 1, total_pages]

	# Update navigation button states
	if prev_button:
		prev_button.disabled = (current_page == 0)
	if next_button:
		next_button.disabled = (current_page >= total_pages - 1)

func _refresh_current_page() -> void:
	"""Refreshes the current page display"""
	_show_page(current_page)

func _on_prev_page() -> void:
	"""Goes to previous page"""
	if current_page > 0:
		_show_page(current_page - 1)

func _on_next_page() -> void:
	"""Goes to next page"""
	if current_page < total_pages - 1:
		_show_page(current_page + 1)

func _on_binding_changed_anywhere(action_name: String, binding_type: String) -> void:
	"""Called when any binding changes"""
	# Only track keyboard changes (this is the keyboard view)
	if binding_type == "keyboard":
		has_unsaved_changes = true
		_update_save_button_visibility()

func _update_save_button_visibility() -> void:
	"""Enables or disables the save button based on unsaved changes"""
	if save_button:
		save_button.disabled = not has_unsaved_changes

func _on_save_pressed() -> void:
	"""Called when Save button is pressed"""
	Keybinds.save_bindings()

	# Update original bindings to current state
	original_bindings = Keybinds.get_all_bindings()
	has_unsaved_changes = false
	_update_save_button_visibility()

func _on_reset_all_pressed() -> void:
	"""Called when Reset All button is pressed"""
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.theme = BaseTheme
	dialog.dialog_text = "Reset all keyboard bindings to defaults?"
	dialog.title = "Confirm Reset"
	dialog.get_label().add_theme_font_size_override("font_size", 16)

	dialog.confirmed.connect(func():
		# Only reset keyboard bindings, not gamepad
		for action_name in Keybinds.get_all_actions():
			Keybinds.reset_action_to_default(action_name, "keyboard")
		has_unsaved_changes = true
		_update_save_button_visibility()
		_refresh_current_page()
	)

	# Add to scene and show
	get_tree().root.add_child(dialog)
	dialog.popup_centered()

func _on_back_pressed() -> void:
	"""Called when back/cancel is pressed"""
	if has_unsaved_changes:
		# Show confirmation dialog
		var dialog = ConfirmationDialog.new()
		dialog.theme = BaseTheme
		dialog.dialog_text = "You have unsaved changes. Discard them?"
		dialog.title = "Unsaved Changes"
		dialog.get_label().add_theme_font_size_override("font_size", 16)

		dialog.confirmed.connect(func():
			# Revert changes
			Keybinds.restore_all_bindings(original_bindings)
			has_unsaved_changes = false
			_update_save_button_visibility()
			_refresh_current_page()
			get_tree().call_group(Group.INTERFACE, "close_keybinds_view")
		)

		# Add to scene and show
		get_tree().root.add_child(dialog)
		dialog.popup_centered()
	else:
		# No unsaved changes, just close
		get_tree().call_group(Group.INTERFACE, "close_keybinds_view")

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Cancel action is handled by UIStateMachine via interface.gd
	# We only handle pagination here
	if event.is_action_pressed("menu_previous_page") or Keybinds.is_action_just_pressed(Keybinds.DECREMENT_TARGET):
		_on_prev_page()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("menu_next_page") or Keybinds.is_action_just_pressed(Keybinds.INCREMENT_TARGET):
		_on_next_page()
		get_viewport().set_input_as_handled()
