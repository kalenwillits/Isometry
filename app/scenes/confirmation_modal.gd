extends CanvasLayer

var on_yes_callback: Callable
var on_no_callback: Callable
var selected_button: int = 1  # 0 = Yes, 1 = No (default to No for safety)

# Countdown variables
var countdown_enabled: bool = false
var countdown_seconds: int = 0
var base_question: String = ""

func _ready() -> void:
	visible = false
	add_to_group(Group.CONFIRMATION_MODAL)
	$Overlay/CenterContainer/PanelContainer/VBox/ButtonBox/YesButton.pressed.connect(_on_yes_pressed)
	$Overlay/CenterContainer/PanelContainer/VBox/ButtonBox/NoButton.pressed.connect(_on_no_pressed)
	$CountdownTimer.timeout.connect(_on_countdown_tick)

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		var theme_mgr = get_node_or_null("/root/ThemeManager")
		if theme_mgr:
			theme_mgr._apply_theme_recursive(self)

func open_modal(question: String, yes_callback: Callable, no_callback: Callable = Callable(), countdown: int = 0) -> void:
	base_question = question
	on_yes_callback = yes_callback
	on_no_callback = no_callback
	selected_button = 1  # Default to No
	update_button_highlight()
	visible = true

	# Start countdown if specified
	if countdown > 0:
		_start_countdown(countdown)
	else:
		countdown_enabled = false
		$Overlay/CenterContainer/PanelContainer/VBox/QuestionLabel.text = question

func close_modal() -> void:
	_stop_countdown()
	visible = false
	on_yes_callback = Callable()
	on_no_callback = Callable()

func _on_yes_pressed() -> void:
	_stop_countdown()
	if on_yes_callback.is_valid():
		on_yes_callback.call()
	close_modal()

func _on_no_pressed() -> void:
	_stop_countdown()
	if on_no_callback.is_valid():
		on_no_callback.call()
	close_modal()

func update_button_highlight() -> void:
	var yes_button = $Overlay/CenterContainer/PanelContainer/VBox/ButtonBox/YesButton
	var no_button = $Overlay/CenterContainer/PanelContainer/VBox/ButtonBox/NoButton

	if selected_button == 0:
		yes_button.modulate = Color(1.5, 1.5, 1.5, 1.0)  # Highlight
		no_button.modulate = Color(1.0, 1.0, 1.0, 1.0)   # Normal
	else:
		yes_button.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal
		no_button.modulate = Color(1.5, 1.5, 1.5, 1.0)   # Highlight

func move_selection_left() -> void:
	selected_button = 0  # Yes
	update_button_highlight()

func move_selection_right() -> void:
	selected_button = 1  # No
	update_button_highlight()

func activate_selected() -> void:
	if selected_button == 0:
		_on_yes_pressed()
	else:
		_on_no_pressed()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Cancel action is handled by UIStateMachine via interface.gd (acts as "No")
	# We only handle navigation and confirmation here
	if event.is_action_pressed("menu_accept"):
		# Enter activates selected button
		activate_selected()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		_stop_countdown()
		move_selection_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_stop_countdown()
		move_selection_right()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up"):
		# Tab-like behavior
		_stop_countdown()
		move_selection_left()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		# Tab-like behavior
		_stop_countdown()
		move_selection_right()
		get_viewport().set_input_as_handled()

# Countdown methods
func _start_countdown(seconds: int) -> void:
	countdown_enabled = true
	countdown_seconds = seconds
	_update_countdown_display()
	$CountdownTimer.start()

func _stop_countdown() -> void:
	if countdown_enabled:
		countdown_enabled = false
		$CountdownTimer.stop()
		# Restore base question without countdown
		$Overlay/CenterContainer/PanelContainer/VBox/QuestionLabel.text = base_question

func _update_countdown_display() -> void:
	if countdown_enabled:
		var display_text = "%s Reverting in %d seconds..." % [base_question, countdown_seconds]
		$Overlay/CenterContainer/PanelContainer/VBox/QuestionLabel.text = display_text

func _on_countdown_tick() -> void:
	if not countdown_enabled:
		return

	countdown_seconds -= 1

	if countdown_seconds <= 0:
		# Auto-execute No callback (revert)
		_stop_countdown()
		_on_no_pressed()
	else:
		_update_countdown_display()
