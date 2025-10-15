extends Widget

const focus_plate_packed_scene: PackedScene = preload("res://scenes/focus_plate.tscn")

@export var check_line_of_sight: bool = false ## If true, plates will show "---" for resources when out of LOS

func _ready() -> void:
	add_to_group(Group.UI_TARGET_WIDGET)
	
func append_plate(plate_target: String) -> void:
	if $HBox.has_node(plate_target): return
	var focus_plate: Widget = focus_plate_packed_scene.instantiate()
	focus_plate.set_actor(plate_target)
	focus_plate.set_name(plate_target)
	focus_plate.set_check_line_of_sight(check_line_of_sight)
	$HBox.add_child(focus_plate)
	
func remove_plate(plate_target: String) -> void:
	var plate: Widget = $HBox.get_node_or_null(plate_target)
	if plate != null:
		$HBox.get_node(plate_target).queue_free()

func set_check_line_of_sight(value: bool) -> void:
	check_line_of_sight = value
	# Update existing plates
	for child in $HBox.get_children():
		if child.has_method("set_check_line_of_sight"):
			child.set_check_line_of_sight(value)
