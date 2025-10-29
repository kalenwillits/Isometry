extends CanvasLayer

const ActionMenuItem = preload("res://scenes/action_menu_item.tscn")

var actions: Array = [] # Array of Action entities
var current_page: int = 0
var items_per_page: int = 12
var selected_index: int = 0
var caller_name: String = ""
var target_name: String = ""

func _ready() -> void:
	visible = false
	add_to_group(Group.CONTEXT_MENU)

	# Connect pagination button signals
	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/PrevButton.pressed.connect(previous_page)
	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/NextButton.pressed.connect(next_page)

func open_menu(title: String, menu_ent: Entity, caller: String, target: String) -> void:
	if menu_ent == null or menu_ent.actions == null:
		Logger.warn("Cannot open menu: invalid menu entity", self)
		return

	caller_name = caller
	target_name = target
	actions = menu_ent.actions.lookup()

	# Check if actions array is empty
	if actions.size() == 0:
		Logger.warn("Cannot open menu: no actions available", self)
		return

	current_page = 0
	selected_index = 0

	$Overlay/CenterContainer/PanelContainer/VBox/Title.set_text(title)
	render_page()
	visible = true

func close_menu() -> void:
	visible = false
	actions.clear()
	current_page = 0
	selected_index = 0
	caller_name = ""
	target_name = ""
	# Clear action list
	for child in $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_children():
		child.queue_free()

func render_page() -> void:
	# Clear existing items
	for child in $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_children():
		child.queue_free()

	var start_index = current_page * items_per_page
	var end_index = min(start_index + items_per_page, actions.size())

	# Create action items for this page
	for i in range(start_index, end_index):
		var action_ent: Entity = actions[i]
		var item = ActionMenuItem.instantiate()
		item.setup(action_ent, i - start_index)
		item.item_clicked.connect(_on_action_item_clicked)
		$Overlay/CenterContainer/PanelContainer/VBox/ActionList.add_child(item)

	# Update pagination label
	var total_pages = max(1, ceil(float(actions.size()) / float(items_per_page)))
	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/PaginationLabel.set_text("%d/%d" % [current_page + 1, total_pages])

	# Hide pagination when only 1 page
	if total_pages == 1:
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/PrevButton.visible = false
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/PaginationLabel.visible = false
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/NextButton.visible = false
	else:
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/PrevButton.visible = true
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/PaginationLabel.visible = true
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationRow/NextButton.visible = true

	update_selection_highlight()

func update_selection_highlight() -> void:
	var children = $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_children()
	for i in range(children.size()):
		var item = children[i]
		if i == selected_index:
			item.modulate = Color(1.5, 1.5, 1.5, 1.0) # Highlight
		else:
			item.modulate = Color(1.0, 1.0, 1.0, 1.0) # Normal

func next_page() -> void:
	if actions.size() == 0:
		return
	var total_pages = max(1, ceil(float(actions.size()) / float(items_per_page)))
	current_page = (current_page + 1) % int(total_pages)
	selected_index = 0
	render_page()

func previous_page() -> void:
	if actions.size() == 0:
		return
	var total_pages = max(1, ceil(float(actions.size()) / float(items_per_page)))
	current_page = (current_page - 1 + int(total_pages)) % int(total_pages)
	selected_index = 0
	render_page()

func move_selection_up() -> void:
	var page_item_count = $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_child_count()
	if page_item_count > 0:
		selected_index = (selected_index - 1 + page_item_count) % page_item_count
		update_selection_highlight()

func move_selection_down() -> void:
	var page_item_count = $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_child_count()
	if page_item_count > 0:
		selected_index = (selected_index + 1) % page_item_count
		update_selection_highlight()

func activate_selected() -> void:
	var children = $Overlay/CenterContainer/PanelContainer/VBox/ActionList.get_children()
	if selected_index < children.size():
		var item = children[selected_index]
		var action_key = item.get_meta("action_key")
		Finder.select(Group.ACTIONS).invoke_action.rpc_id(1, action_key, caller_name, target_name)
		close_menu()

func _on_action_item_clicked(index: int) -> void:
	selected_index = index
	update_selection_highlight()
	activate_selected()

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
	elif event.is_action_pressed("menu_next_page"):
		next_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_previous_page"):
		previous_page()
		get_viewport().set_input_as_handled()
