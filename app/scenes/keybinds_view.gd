extends CanvasLayer

const KeybindRowScene = preload("res://scenes/keybind_row.tscn")
const DarkModeTheme = preload("res://themes/DarkMode.res")
const ITEMS_PER_PAGE: int = 8

var current_page: int = 0
var total_pages: int = 0
var all_actions: Array = []
var original_bindings: Dictionary = {}
var has_unsaved_changes: bool = false

@onready var keybinds_list: VBoxContainer = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/RowsContainer/KeybindsList
@onready var page_label: Label = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/NavigationContainer/PageLabel
@onready var menu_hints: HBoxContainer = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/NavigationContainer/MenuHints
@onready var save_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/ButtonsContainer/HBox/SaveButton
@onready var reset_all_button: Button = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/NavigationContainer/ResetAllButton

func _ready() -> void:
	add_to_group(Group.KEYBINDS_MENU)

	# Store original bindings for cancel/revert
	original_bindings = Keybinds.get_all_bindings()

	# Connect signals
	save_button.pressed.connect(_on_save_pressed)
	reset_all_button.pressed.connect(_on_reset_all_pressed)
	menu_hints.cancel_clicked.connect(_on_back_pressed)
	menu_hints.prev_clicked.connect(_on_prev_page)
	menu_hints.next_clicked.connect(_on_next_page)

	# Listen for binding changes
	Keybinds.binding_changed.connect(_on_binding_changed_anywhere)
	Keybinds.bindings_reset.connect(_refresh_current_page)

	# Load actions and build UI
	_load_actions()
	_calculate_pages()
	_show_page(0)

	# Update save button visibility
	_update_save_button_visibility()

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

	# Update page label
	page_label.text = "%d / %d" % [current_page + 1, total_pages]

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
	"""Shows or hides the save button based on unsaved changes"""
	save_button.visible = has_unsaved_changes

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
	dialog.theme = DarkModeTheme
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
		dialog.theme = DarkModeTheme
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

	# Handle escape key
	if event.is_action_pressed("menu_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

	# Handle pagination with keyboard
	elif event.is_action_pressed("menu_previous_page"):
		_on_prev_page()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("menu_next_page"):
		_on_next_page()
		get_viewport().set_input_as_handled()
