extends CanvasLayer

const ResourceBlockScene = preload("res://scenes/resource_block.tscn")

var resource_keys: Array[String] = []
var current_page: int = 0
var items_per_page: int = 12  # 12 columns × 1 row
var selected_index: int = 0
var grid_columns: int = 12

func _ready() -> void:
	visible = false
	add_to_group(Group.RESOURCES_MENU)

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		var theme_mgr = get_node_or_null("/root/ThemeManager")
		if theme_mgr:
			theme_mgr._apply_theme_recursive(self)

func open_menu() -> void:
	load_resources()
	current_page = 0
	selected_index = 0
	render_page()
	visible = true

func close_menu() -> void:
	visible = false
	clear_grid()
	resource_keys.clear()

func load_resources() -> void:
	resource_keys.clear()
	var primary_actor: Actor = Finder.get_primary_actor()
	if not primary_actor:
		return

	for resource_key in primary_actor.resources.keys():
		var entity: Entity = Repo.select(resource_key)
		if not entity:
			continue

		# Respect reveal threshold
		var reveal_threshold = entity.get("reveal") if entity.get("reveal") != null else 0
		var current_value = primary_actor.get_resource(resource_key)

		if current_value >= reveal_threshold:
			resource_keys.append(resource_key)

func render_page() -> void:
	clear_grid()

	var start_index = current_page * items_per_page
	var end_index = min(start_index + items_per_page, resource_keys.size())

	var primary_actor: Actor = Finder.get_primary_actor()
	if not primary_actor:
		return

	# Create resource blocks for this page
	for i in range(start_index, end_index):
		var resource_key = resource_keys[i]
		var resource_block = ResourceBlockScene.instantiate()
		resource_block.set_actor(primary_actor.name)
		resource_block.set_key(resource_key)

		# Add tooltip from Resource entity
		var entity: Entity = Repo.select(resource_key)
		if entity and entity.get("tooltip"):
			resource_block.get_node("Button").tooltip_text = entity.tooltip

		$Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.add_child(resource_block)

	# Fill remaining slots with empty widgets to complete the grid
	var items_on_page = end_index - start_index
	var empty_slots_needed = items_per_page - items_on_page
	for i in range(empty_slots_needed):
		var empty_widget = Control.new()
		empty_widget.custom_minimum_size = Vector2(28, 28)
		$Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.add_child(empty_widget)

	# Update pagination label
	var total_pages = max(1, ceil(float(resource_keys.size()) / float(items_per_page)))
	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationLabel.set_text("%d/%d" % [current_page + 1, total_pages])

	# Hide pagination when only 1 page
	if total_pages == 1:
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationLabel.visible = false
	else:
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationLabel.visible = true

	update_selection_highlight()

func clear_grid() -> void:
	for child in $Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.get_children():
		child.queue_free()

func update_selection_highlight() -> void:
	var children = $Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.get_children()
	for i in range(children.size()):
		var item = children[i]
		if i == selected_index:
			item.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Highlight
		else:
			item.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal

func move_selection_up() -> void:
	var items_on_page = $Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.get_child_count()
	if items_on_page == 0:
		return

	selected_index -= grid_columns
	if selected_index < 0:
		# Wrap to bottom
		var rows = ceil(float(items_on_page) / float(grid_columns))
		selected_index = min(selected_index + int(rows) * grid_columns, items_on_page - 1)

	update_selection_highlight()

func move_selection_down() -> void:
	var items_on_page = $Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.get_child_count()
	if items_on_page == 0:
		return

	selected_index += grid_columns
	if selected_index >= items_on_page:
		# Wrap to top
		selected_index = selected_index % grid_columns

	update_selection_highlight()

func move_selection_left() -> void:
	var items_on_page = $Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.get_child_count()
	if items_on_page == 0:
		return

	selected_index -= 1
	if selected_index < 0:
		selected_index = items_on_page - 1  # Wrap to end

	update_selection_highlight()

func move_selection_right() -> void:
	var items_on_page = $Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.get_child_count()
	if items_on_page == 0:
		return

	selected_index += 1
	if selected_index >= items_on_page:
		selected_index = 0  # Wrap to start

	update_selection_highlight()

func next_page() -> void:
	if resource_keys.size() == 0:
		return
	var total_pages = max(1, ceil(float(resource_keys.size()) / float(items_per_page)))
	current_page = (current_page + 1) % int(total_pages)
	selected_index = 0
	render_page()

func previous_page() -> void:
	if resource_keys.size() == 0:
		return
	var total_pages = max(1, ceil(float(resource_keys.size()) / float(items_per_page)))
	current_page = (current_page - 1 + int(total_pages)) % int(total_pages)
	selected_index = 0
	render_page()

func activate_selected() -> void:
	var children = $Overlay/CenterContainer/PanelContainer/VBox/ResourceGrid.get_children()
	if selected_index < children.size():
		var resource_block = children[selected_index]
		if resource_block.has_node("Button"):
			var button = resource_block.get_node("Button")
			button.emit_signal("pressed")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Cancel action is handled by UIStateMachine via interface.gd
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
	elif event.is_action_pressed("ui_left"):
		move_selection_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		move_selection_right()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_next_page"):
		next_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_previous_page"):
		previous_page()
		get_viewport().set_input_as_handled()
