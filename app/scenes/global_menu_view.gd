extends CanvasLayer

var selected_index: int = 0
var ui_state_machine: Node

func _ready() -> void:
	visible = false
	ui_state_machine = get_node("/root/UIStateMachine")
	add_to_group(Group.GLOBAL_MENU)
	_create_menu_items()

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		var theme_mgr = get_node_or_null("/root/ThemeManager")
		if theme_mgr:
			theme_mgr._apply_theme_recursive(self)

func _create_menu_items() -> void:
	# Create "Map" button
	var map_button = Button.new()
	map_button.custom_minimum_size = Vector2(256, 24)
	map_button.text = "Map"
	map_button.pressed.connect(_on_map_button_pressed)
	$Overlay/CenterContainer/PanelContainer/VBox/ActionList.add_child(map_button)

	# Create "Resources" button
	var resources_button = Button.new()
	resources_button.custom_minimum_size = Vector2(256, 24)
	resources_button.text = "Resources"
	resources_button.pressed.connect(_on_resources_button_pressed)
	$Overlay/CenterContainer/PanelContainer/VBox/ActionList.add_child(resources_button)

	# Create "System" button
	var system_button = Button.new()
	system_button.custom_minimum_size = Vector2(256, 24)
	system_button.text = "System"
	system_button.pressed.connect(_on_system_button_pressed)
	$Overlay/CenterContainer/PanelContainer/VBox/ActionList.add_child(system_button)

func _on_map_button_pressed() -> void:
	ui_state_machine.open_map_from_menu()

func _on_resources_button_pressed() -> void:
	ui_state_machine.transition_to(ui_state_machine.State.MENU_RESOURCES)

func _on_system_button_pressed() -> void:
	ui_state_machine.transition_to(ui_state_machine.State.MENU_SYSTEM)

func open_menu() -> void:
	selected_index = 0
	update_selection_highlight()
	visible = true

func close_menu() -> void:
	visible = false

func update_selection_highlight() -> void:
	var children = $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_children()
	for i in range(children.size()):
		var item = children[i]
		if i == selected_index:
			item.modulate = Color(1.5, 1.5, 1.5, 1.0) # Highlight
		else:
			item.modulate = Color(1.0, 1.0, 1.0, 1.0) # Normal

func move_selection_up() -> void:
	var item_count = $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_child_count()
	if item_count > 0:
		selected_index = (selected_index - 1 + item_count) % item_count
		update_selection_highlight()

func move_selection_down() -> void:
	var item_count = $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_child_count()
	if item_count > 0:
		selected_index = (selected_index + 1) % item_count
		update_selection_highlight()

func activate_selected() -> void:
	var children = $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_children()
	if selected_index < children.size():
		var button = children[selected_index]
		if button is Button:
			button.emit_signal("pressed")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Cancel and open_menu actions are handled by UIStateMachine via interface.gd
	# We only handle menu navigation here
	if event.is_action_pressed("menu_accept"):
		activate_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		move_selection_up()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		move_selection_down()
		get_viewport().set_input_as_handled()
