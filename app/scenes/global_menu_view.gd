extends CanvasLayer

var selected_index: int = 0

func _ready() -> void:
	visible = false
	add_to_group(Group.GLOBAL_MENU)
	_create_menu_items()

func _create_menu_items() -> void:
	# Create "Close" button directly (no entities needed)
	var close_button = Button.new()
	close_button.custom_minimum_size = Vector2(256, 24)
	close_button.text = "Close"
	close_button.pressed.connect(_on_close_button_pressed)
	$Overlay/CenterContainer/PanelContainer/VBox/ActionList.add_child(close_button)

func _on_close_button_pressed() -> void:
	get_parent().open_close_confirmation()
	close_menu()

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

	if event.is_action_pressed("menu_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_accept"):
		activate_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		move_selection_up()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		move_selection_down()
		get_viewport().set_input_as_handled()
