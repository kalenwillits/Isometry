extends Control
class_name Widget
## Base class for any UI item.

func _ready() -> void:
	# Connect to visibility changes
	visibility_changed.connect(_on_visibility_changed)

	# Apply theme immediately if visible
	if visible:
		_apply_theme()


func _on_visibility_changed() -> void:
	# Reload theme when becoming visible
	if visible:
		_apply_theme()


func _apply_theme() -> void:
	var theme_mgr = get_node_or_null("/root/ThemeManager")
	if theme_mgr:
		theme_mgr._apply_theme_recursive(self)
