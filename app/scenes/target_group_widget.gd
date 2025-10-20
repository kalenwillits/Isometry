extends Widget

## Widget that displays colored dots for each visible target group
## and highlights the currently selected target group

signal group_dot_clicked(group_key: String)

# Dictionary mapping group_key -> Label node
var group_dots: Dictionary = {}
var current_selected_group: String = ""

func _ready() -> void:
	add_to_group(Group.UI_TARGET_GROUP_WIDGET)
	# Connect to primary actor's signals when it becomes available
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.is_in_group(Group.PRIMARY):
		_connect_to_primary_actor(node)
		get_tree().node_added.disconnect(_on_node_added)

func _connect_to_primary_actor(primary_actor: Actor) -> void:
	if primary_actor.has_signal("visible_groups_changed"):
		primary_actor.visible_groups_changed.connect(_on_visible_groups_changed)
	if primary_actor.has_signal("target_group_changed"):
		primary_actor.target_group_changed.connect(_on_target_group_changed)

	# Initial sync with current visible groups
	_sync_with_visible_groups(primary_actor.visible_groups)

func _on_visible_groups_changed(visible_groups: Dictionary) -> void:
	_sync_with_visible_groups(visible_groups)

func _on_target_group_changed(group_key: String) -> void:
	_update_selection_indicator(group_key)

func _sync_with_visible_groups(visible_groups: Dictionary) -> void:
	# Remove dots for groups that are no longer visible
	for group_key in group_dots.keys():
		if not visible_groups.has(group_key) or visible_groups[group_key] <= 0:
			_remove_group_dot(group_key)

	# Add dots for new visible groups
	for group_key in visible_groups.keys():
		if visible_groups[group_key] > 0 and not group_dots.has(group_key):
			_add_group_dot(group_key)

func _add_group_dot(group_key: String) -> void:
	# Get group color from entity
	var group_ent = Repo.query([group_key]).pop_front()
	if not group_ent or not group_ent.color:
		return

	var color: Color = _parse_hex_color(group_ent.color)

	# Create label with colored dot
	var label: Label = Label.new()
	label.text = "○"  # Unicode open circle (unselected state)
	label.add_theme_color_override("font_color", color)
	label.name = group_key
	label.mouse_filter = Control.MOUSE_FILTER_PASS

	# Add to HBox
	$HBox.add_child(label)
	group_dots[group_key] = label

func _remove_group_dot(group_key: String) -> void:
	if group_dots.has(group_key):
		var label: Label = group_dots[group_key]
		label.queue_free()
		group_dots.erase(group_key)

		# Clear selection if this was the selected group
		if current_selected_group == group_key:
			current_selected_group = ""

func _update_selection_indicator(group_key: String) -> void:
	# Clear previous selection - revert to open circle
	if current_selected_group != "" and group_dots.has(current_selected_group):
		var prev_label: Label = group_dots[current_selected_group]
		prev_label.text = "○"

	# Set new selection
	current_selected_group = group_key

	# Change selected group to filled circle
	if group_key != "" and group_dots.has(group_key):
		var label: Label = group_dots[group_key]
		label.text = "●"  # Filled circle (selected state)

func _parse_hex_color(hex_string: String) -> Color:
	# Parse hex color string (e.g., "#FF0000" or "FF0000")
	if hex_string == "":
		return Color.WHITE

	var hex = hex_string.strip_edges()
	if hex.begins_with("#"):
		hex = hex.substr(1)

	# Validate hex string length
	if hex.length() != 6:
		return Color.WHITE

	# Parse RGB components
	var r = hex.substr(0, 2).hex_to_int()
	var g = hex.substr(2, 2).hex_to_int()
	var b = hex.substr(4, 2).hex_to_int()

	# Check if parsing was successful
	if r < 0 or g < 0 or b < 0 or r > 255 or g > 255 or b > 255:
		return Color.WHITE

	return Color(r / 255.0, g / 255.0, b / 255.0, 1.0)
