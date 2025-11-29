extends CanvasLayer

# Normal status color (white)
const STATUS_COLOR = Color(1.0, 1.0, 1.0, 1.0)
# Error status color (red)
const ERROR_COLOR = Color(1.0, 0.3, 0.3, 1.0)

var is_error: bool = false

func _ready() -> void:
	visible = false
	add_to_group(Group.LOADING_MODAL)

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		ThemeManager._apply_theme_recursive(self)


func show_status(message: String) -> void:
	"""Display a status message in normal color"""
	is_error = false
	$Overlay/CenterContainer/PanelContainer/VBox/StatusLabel.text = message
	$Overlay/CenterContainer/PanelContainer/VBox/StatusLabel.modulate = STATUS_COLOR
	visible = true


func show_error(message: String) -> void:
	"""Display an error message in red color and keep modal visible"""
	is_error = true
	$Overlay/CenterContainer/PanelContainer/VBox/StatusLabel.text = message
	$Overlay/CenterContainer/PanelContainer/VBox/StatusLabel.modulate = ERROR_COLOR
	visible = true


func hide_modal() -> void:
	"""Hide the modal (only if not showing an error)"""
	if not is_error:
		visible = false
