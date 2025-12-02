## ValidationErrorModal
## Displays campaign validation errors in a modal popup.
##
extends CanvasLayer

@onready var error_list: VBoxContainer = $Overlay/CenterContainer/PanelContainer/VBox/ScrollContainer/ErrorList
@onready var error_count_label: Label = $Overlay/CenterContainer/PanelContainer/VBox/ErrorCountLabel
@onready var close_button: Button = $Overlay/CenterContainer/PanelContainer/VBox/ButtonContainer/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)

## Shows the modal with validation errors
func show_errors(result: ValidationResult) -> void:
	# Clear previous errors
	for child in error_list.get_children():
		child.queue_free()

	var errors := result.get_errors()

	# Update error count
	error_count_label.text = "Found %d error(s)" % errors.size()

	# Add each error to the list
	for error in errors:
		var error_label := Label.new()
		error_label.text = _format_error(error)
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		error_label.add_theme_color_override("font_color", Color.WHITE)
		error_label.add_theme_font_size_override("font_size", 11)
		error_list.add_child(error_label)

	# Show the modal
	visible = true

## Formats a validation error for display
func _format_error(error: ValidationError) -> String:
	var type_str: String = ValidationError.Type.keys()[error.type]

	if error.field_name.is_empty():
		return "[%s] %s.%s: %s" % [
			type_str,
			error.entity_type,
			error.entity_key,
			error.message
		]
	else:
		return "[%s] %s.%s: %s - %s" % [
			type_str,
			error.entity_type,
			error.entity_key,
			error.field_name,
			error.message
		]

## Exits the game
func _on_close_button_pressed() -> void:
	get_tree().quit()
