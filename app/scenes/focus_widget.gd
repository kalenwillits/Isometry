extends Widget

const focus_plate_packed_scene: PackedScene = preload("res://scenes/focus_plate.tscn")

@export var check_in_view: bool = false ## If true, plates will show "---" for resources when out of view

func _ready() -> void:
	add_to_group(Group.UI_TARGET_WIDGET)

	# Apply current theme to this widget
	ThemeManager._apply_theme_recursive(self)
	
func append_plate(plate_target: String) -> void:
	if $HBox.has_node(plate_target): return
	var focus_plate: Widget = focus_plate_packed_scene.instantiate()
	focus_plate.set_actor(plate_target)
	focus_plate.set_name(plate_target)
	focus_plate.set_check_in_view(check_in_view)
	$HBox.add_child(focus_plate)
	
func remove_plate(plate_target: String) -> void:
	var plate: Widget = $HBox.get_node_or_null(plate_target)
	if plate != null:
		$HBox.get_node(plate_target).queue_free()

func set_check_in_view(value: bool) -> void:
	check_in_view = value
	# Update existing plates
	for child in $HBox.get_children():
		if child.has_method("set_check_in_view"):
			child.set_check_in_view(value)
