extends HBoxContainer
# MenuHints - Displays input hints for common menu actions
# Shows Accept, Cancel, and optionally Page navigation hints
# Now emits signals when hints are clicked

const InputIconScene = preload("res://scenes/input_icon.tscn")

signal accept_clicked()
signal cancel_clicked()
signal prev_clicked()
signal next_clicked()

@export var show_accept: bool = true
@export var show_cancel: bool = true
@export var show_pagination: bool = false

func _ready() -> void:
	_build_hints()

func _build_hints() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()

	# Add Accept hint
	if show_accept:
		_add_hint("menu_accept", "Accept", func(): accept_clicked.emit())

	# Add Cancel hint
	if show_cancel:
		if get_child_count() > 0:
			_add_spacer()
		_add_hint("menu_cancel", "Cancel", func(): cancel_clicked.emit())

	# Add Pagination hints
	if show_pagination:
		if get_child_count() > 0:
			_add_spacer()
		_add_hint("menu_previous_page", "Prev", func(): prev_clicked.emit())
		_add_spacer()
		_add_hint("menu_next_page", "Next", func(): next_clicked.emit())

func _add_hint(action_name: String, label_text: String, on_click: Callable) -> void:
	# Create a container for the hint
	var hint_container = HBoxContainer.new()
	hint_container.add_theme_constant_override("separation", 8)

	# Add the InputIcon
	var input_icon = InputIconScene.instantiate()
	input_icon.action_name = action_name
	input_icon.icon_size = Vector2i(16, 16)
	input_icon.text_size = 16
	# Connect the icon's click signal to emit our signal
	input_icon.icon_clicked.connect(on_click)
	hint_container.add_child(input_icon)

	# Add the label
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse
	hint_container.add_child(label)

	add_child(hint_container)

func _add_spacer() -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(16, 0)
	add_child(spacer)
