extends HBoxContainer
# MenuHints - Displays input hints for common menu actions
# Shows Accept, Cancel, and optionally Page navigation hints
# Now emits signals when hints are clicked

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

func _add_hint(_action_name: String, label_text: String, on_click: Callable) -> void:
	# Create regular button
	var button = Button.new()
	button.text = label_text.strip_edges()
	button.custom_minimum_size = Vector2(60, 24)
	button.pressed.connect(on_click)
	add_child(button)

func _add_spacer() -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(16, 0)
	add_child(spacer)
