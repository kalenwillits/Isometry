extends CanvasLayer

const SkillBlockScene = preload("res://scenes/skill_block.tscn")

var skill_keys: Array[String] = []
var current_page: int = 0
var items_per_page: int = 3  # 3 skills per page
var selected_index: int = 0

func _ready() -> void:
	visible = false
	add_to_group(Group.SKILLS_MENU)

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		var theme_mgr = get_node_or_null("/root/ThemeManager")
		if theme_mgr:
			theme_mgr._apply_theme_recursive(self)

func open_menu() -> void:
	load_skills()
	current_page = 0
	selected_index = 0
	render_page()
	visible = true

func close_menu() -> void:
	visible = false
	clear_list()
	skill_keys.clear()

func load_skills() -> void:
	skill_keys.clear()
	var primary_actor: Actor = Finder.get_primary_actor()
	if not primary_actor:
		return

	# Get the actor entity to access skills
	var actor_ent: Entity = Repo.query([primary_actor.actor]).pop_front()
	if not actor_ent:
		return

	# Get skills from the actor entity
	if actor_ent.get("skills") and actor_ent.skills:
		var skills_list = actor_ent.skills.lookup()
		for skill_ent in skills_list:
			if skill_ent:
				skill_keys.append(skill_ent.key())

func render_page() -> void:
	clear_list()

	var start_index = current_page * items_per_page
	var end_index = min(start_index + items_per_page, skill_keys.size())

	# Create skill blocks for this page
	for i in range(start_index, end_index):
		var skill_key = skill_keys[i]
		var skill_block = SkillBlockScene.instantiate()
		skill_block.set_key(skill_key)

		$Overlay/CenterContainer/PanelContainer/VBox/SkillList.add_child(skill_block)

	# Fill remaining slots with empty widgets to maintain consistent layout
	var items_on_page = end_index - start_index
	var empty_slots_needed = items_per_page - items_on_page
	for i in range(empty_slots_needed):
		var empty_widget = Control.new()
		empty_widget.custom_minimum_size = Vector2(300, 96)
		$Overlay/CenterContainer/PanelContainer/VBox/SkillList.add_child(empty_widget)

	# Update pagination label
	var total_pages = max(1, ceil(float(skill_keys.size()) / float(items_per_page)))
	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationLabel.set_text("%d/%d" % [current_page + 1, total_pages])

	# Hide pagination when only 1 page
	if total_pages == 1:
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationLabel.visible = false
	else:
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/PaginationLabel.visible = true

	update_selection_highlight()

func clear_list() -> void:
	for child in $Overlay/CenterContainer/PanelContainer/VBox/SkillList.get_children():
		child.queue_free()

func update_selection_highlight() -> void:
	var children = $Overlay/CenterContainer/PanelContainer/VBox/SkillList.get_children()
	for i in range(children.size()):
		var item = children[i]
		if i == selected_index:
			item.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Highlight
		else:
			item.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal

func move_selection_up() -> void:
	var items_on_page = $Overlay/CenterContainer/PanelContainer/VBox/SkillList.get_child_count()
	if items_on_page == 0:
		return

	selected_index -= 1
	if selected_index < 0:
		selected_index = items_on_page - 1  # Wrap to bottom

	update_selection_highlight()

func move_selection_down() -> void:
	var items_on_page = $Overlay/CenterContainer/PanelContainer/VBox/SkillList.get_child_count()
	if items_on_page == 0:
		return

	selected_index += 1
	if selected_index >= items_on_page:
		selected_index = 0  # Wrap to top

	update_selection_highlight()

func next_page() -> void:
	if skill_keys.size() == 0:
		return
	var total_pages = max(1, ceil(float(skill_keys.size()) / float(items_per_page)))
	current_page = (current_page + 1) % int(total_pages)
	selected_index = 0
	render_page()

func previous_page() -> void:
	if skill_keys.size() == 0:
		return
	var total_pages = max(1, ceil(float(skill_keys.size()) / float(items_per_page)))
	current_page = (current_page - 1 + int(total_pages)) % int(total_pages)
	selected_index = 0
	render_page()

func activate_selected() -> void:
	var children = $Overlay/CenterContainer/PanelContainer/VBox/SkillList.get_children()
	if selected_index < children.size():
		var skill_block = children[selected_index]
		if skill_block.has_node("Button"):
			var button = skill_block.get_node("Button")
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
	elif event.is_action_pressed("menu_next_page") or Keybinds.is_action_just_pressed(Keybinds.INCREMENT_TARGET):
		next_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_previous_page") or Keybinds.is_action_just_pressed(Keybinds.DECREMENT_TARGET):
		previous_page()
		get_viewport().set_input_as_handled()
