extends CanvasLayer

const CONFIG_FILE_PATH: String = "user://options.cfg"
const CONFIG_SECTION_CHAT: String = "chat"

var channel_filters: Dictionary = {
	Chat.Channel.WHISPER: true,
	Chat.Channel.SAY: true,
	Chat.Channel.FOCUS: true,
	Chat.Channel.GROUP: true,
	Chat.Channel.PUBLIC: true,
	Chat.Channel.MAP: true,
	Chat.Channel.YELL: true,
	Chat.Channel.LOG: false  # Disabled by default
}

var active_channel: int = Chat.Channel.PUBLIC
var config: ConfigFile = ConfigFile.new()
var last_message_count: int = 0  # Track message count to detect new messages
var refresh_timer: Timer = null

func _ready() -> void:
	visible = false
	add_to_group(Group.FEEDS_VIEW)

	# Load config
	config.load(CONFIG_FILE_PATH)

	# Load channel filter preferences
	_load_channel_filters()

	# Create and configure refresh timer
	refresh_timer = Timer.new()
	refresh_timer.wait_time = 0.5  # Check for new messages every 0.5 seconds
	refresh_timer.autostart = false
	refresh_timer.timeout.connect(_check_for_new_messages)
	add_child(refresh_timer)

	# Connect visibility changed signal to apply theme when visible
	visibility_changed.connect(_on_visibility_changed)

	# Connect channel filter checkboxes
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/WhisperCheck.toggled.connect(_on_whisper_toggled)
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/SayCheck.toggled.connect(_on_say_toggled)
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/FocusCheck.toggled.connect(_on_focus_toggled)
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/GroupCheck.toggled.connect(_on_group_toggled)
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/PublicCheck.toggled.connect(_on_public_toggled)
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/MapCheck.toggled.connect(_on_map_toggled)
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/YellCheck.toggled.connect(_on_yell_toggled)
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/LogCheck.toggled.connect(_on_log_toggled)

	# Connect chat input
	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/LineEdit.text_submitted.connect(_on_text_submitted)

	# Initialize channel label
	_update_channel_prefix()

func _load_channel_filters() -> void:
	"""Load channel filter preferences from config file"""
	channel_filters[Chat.Channel.WHISPER] = config.get_value(CONFIG_SECTION_CHAT, "channel_whisper", true)
	channel_filters[Chat.Channel.SAY] = config.get_value(CONFIG_SECTION_CHAT, "channel_say", true)
	channel_filters[Chat.Channel.FOCUS] = config.get_value(CONFIG_SECTION_CHAT, "channel_focus", true)
	channel_filters[Chat.Channel.GROUP] = config.get_value(CONFIG_SECTION_CHAT, "channel_group", true)
	channel_filters[Chat.Channel.PUBLIC] = config.get_value(CONFIG_SECTION_CHAT, "channel_public", true)
	channel_filters[Chat.Channel.MAP] = config.get_value(CONFIG_SECTION_CHAT, "channel_map", true)
	channel_filters[Chat.Channel.YELL] = config.get_value(CONFIG_SECTION_CHAT, "channel_yell", true)
	channel_filters[Chat.Channel.LOG] = config.get_value(CONFIG_SECTION_CHAT, "channel_log", false)

	# Update checkboxes to match loaded preferences
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/WhisperCheck.button_pressed = channel_filters[Chat.Channel.WHISPER]
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/SayCheck.button_pressed = channel_filters[Chat.Channel.SAY]
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/FocusCheck.button_pressed = channel_filters[Chat.Channel.FOCUS]
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/GroupCheck.button_pressed = channel_filters[Chat.Channel.GROUP]
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/PublicCheck.button_pressed = channel_filters[Chat.Channel.PUBLIC]
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/MapCheck.button_pressed = channel_filters[Chat.Channel.MAP]
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/YellCheck.button_pressed = channel_filters[Chat.Channel.YELL]
	$Overlay/CenterContainer/PanelContainer/VBox/FilterBar/LogCheck.button_pressed = channel_filters[Chat.Channel.LOG]

func _save_channel_filter(channel_key: String, enabled: bool) -> void:
	"""Save a channel filter preference to config file"""
	config.set_value(CONFIG_SECTION_CHAT, channel_key, enabled)
	config.save(CONFIG_FILE_PATH)

func _on_visibility_changed() -> void:
	if visible:
		ThemeManager._apply_theme_recursive(self)

func open_menu() -> void:
	visible = true
	_update_filter_colors()
	refresh_feeds()
	# Start timer to check for new messages
	if refresh_timer:
		var chat_widget = Finder.select(Group.UI_CHAT_WIDGET)
		if chat_widget:
			last_message_count = chat_widget.message_history.size()
		refresh_timer.start()

func close_menu() -> void:
	visible = false
	# Stop timer when view is closed
	if refresh_timer:
		refresh_timer.stop()

func _check_for_new_messages() -> void:
	"""Check if new messages have arrived and refresh if needed"""
	var chat_widget = Finder.select(Group.UI_CHAT_WIDGET)
	if not chat_widget:
		return

	var current_message_count = chat_widget.message_history.size()
	if current_message_count != last_message_count:
		last_message_count = current_message_count
		refresh_feeds()

func refresh_feeds() -> void:
	"""Load and display all messages from chat widget history"""
	var chat_widget = Finder.select(Group.UI_CHAT_WIDGET)
	if not chat_widget:
		return

	var history: Array[Chat] = chat_widget.get_message_history()

	# Clear and rebuild
	$Overlay/CenterContainer/PanelContainer/VBox/ScrollContainer/FeedText.clear()

	for chat in history:
		var channel = chat.get_channel()
		if channel_filters.get(channel, true):
			$Overlay/CenterContainer/PanelContainer/VBox/ScrollContainer/FeedText.append_text(chat.render())

	# Auto-scroll to bottom
	await get_tree().process_frame
	var scrollbar = $Overlay/CenterContainer/PanelContainer/VBox/ScrollContainer.get_v_scroll_bar()
	scrollbar.value = scrollbar.max_value

func _update_filter_colors() -> void:
	"""Update checkbox labels with channel colors"""
	_apply_color_to_checkbox($Overlay/CenterContainer/PanelContainer/VBox/FilterBar/WhisperCheck, Chat.Channel.WHISPER)
	_apply_color_to_checkbox($Overlay/CenterContainer/PanelContainer/VBox/FilterBar/SayCheck, Chat.Channel.SAY)
	_apply_color_to_checkbox($Overlay/CenterContainer/PanelContainer/VBox/FilterBar/FocusCheck, Chat.Channel.FOCUS)
	_apply_color_to_checkbox($Overlay/CenterContainer/PanelContainer/VBox/FilterBar/GroupCheck, Chat.Channel.GROUP)
	_apply_color_to_checkbox($Overlay/CenterContainer/PanelContainer/VBox/FilterBar/PublicCheck, Chat.Channel.PUBLIC)
	_apply_color_to_checkbox($Overlay/CenterContainer/PanelContainer/VBox/FilterBar/MapCheck, Chat.Channel.MAP)
	_apply_color_to_checkbox($Overlay/CenterContainer/PanelContainer/VBox/FilterBar/YellCheck, Chat.Channel.YELL)
	_apply_color_to_checkbox($Overlay/CenterContainer/PanelContainer/VBox/FilterBar/LogCheck, Chat.Channel.LOG)

func _apply_color_to_checkbox(checkbox: CheckBox, channel: int) -> void:
	var color = Chat.CHANNEL_COLORS.get(channel, Color.WHITE)
	checkbox.add_theme_color_override("font_color", color)
	checkbox.add_theme_color_override("font_hover_color", color.lightened(0.2))
	checkbox.add_theme_color_override("font_pressed_color", color.darkened(0.2))

# Channel filter toggle callbacks
func _on_whisper_toggled(enabled: bool) -> void:
	channel_filters[Chat.Channel.WHISPER] = enabled
	_save_channel_filter("channel_whisper", enabled)
	_update_chat_widget_filters()
	refresh_feeds()

func _on_say_toggled(enabled: bool) -> void:
	channel_filters[Chat.Channel.SAY] = enabled
	_save_channel_filter("channel_say", enabled)
	_update_chat_widget_filters()
	refresh_feeds()

func _on_focus_toggled(enabled: bool) -> void:
	channel_filters[Chat.Channel.FOCUS] = enabled
	_save_channel_filter("channel_focus", enabled)
	_update_chat_widget_filters()
	refresh_feeds()

func _on_group_toggled(enabled: bool) -> void:
	channel_filters[Chat.Channel.GROUP] = enabled
	_save_channel_filter("channel_group", enabled)
	_update_chat_widget_filters()
	refresh_feeds()

func _on_public_toggled(enabled: bool) -> void:
	channel_filters[Chat.Channel.PUBLIC] = enabled
	_save_channel_filter("channel_public", enabled)
	_update_chat_widget_filters()
	refresh_feeds()

func _on_map_toggled(enabled: bool) -> void:
	channel_filters[Chat.Channel.MAP] = enabled
	_save_channel_filter("channel_map", enabled)
	_update_chat_widget_filters()
	refresh_feeds()

func _on_yell_toggled(enabled: bool) -> void:
	channel_filters[Chat.Channel.YELL] = enabled
	_save_channel_filter("channel_yell", enabled)
	_update_chat_widget_filters()
	refresh_feeds()

func _on_log_toggled(enabled: bool) -> void:
	channel_filters[Chat.Channel.LOG] = enabled
	_save_channel_filter("channel_log", enabled)
	_update_chat_widget_filters()
	refresh_feeds()

func _update_chat_widget_filters() -> void:
	"""Sync filters to chat widget so HUD chat also respects these settings"""
	var chat_widget = Finder.select(Group.UI_CHAT_WIDGET)
	if chat_widget:
		for channel in channel_filters.keys():
			chat_widget.toggle_channel(channel, channel_filters[channel])

func _on_text_submitted(new_text: String) -> void:
	"""Handle chat message submission"""
	# Check if message starts with "/"
	if new_text.begins_with("/"):
		# Parse command
		var parts = new_text.split(" ", false, 1)
		var command = parts[0].to_lower()

		# Check if it's a channel command
		if _parse_channel_command(command):
			# Command was a channel switch
			if parts.size() > 1:
				# Command has a message after it, send that message on the new channel
				new_text = parts[1]
			else:
				# Command with no message, just clear and return
				$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/LineEdit.clear()
				return
		# If not a channel command, pass through as-is

	# Check if final message is empty or whitespace-only
	if new_text.strip_edges().is_empty():
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/LineEdit.clear()
		return

	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/LineEdit.clear()
	var primary_actor: Actor = Finder.get_primary_actor()
	Controller.submit_chat_request_to_server.rpc_id(1, primary_actor.name, new_text, active_channel)

func cycle_channel() -> void:
	"""Cycle to the next chat channel"""
	var channels = [
		Chat.Channel.PUBLIC,
		Chat.Channel.SAY,
		Chat.Channel.YELL,
		Chat.Channel.WHISPER,
		Chat.Channel.GROUP,
		Chat.Channel.FOCUS,
		Chat.Channel.MAP
	]
	var current_index = channels.find(active_channel)
	active_channel = channels[(current_index + 1) % channels.size()]
	_update_channel_prefix()

func _update_channel_prefix() -> void:
	"""Update the channel label with current channel"""
	var channel_name = Chat.CHANNEL_NAMES.get(active_channel, "Unknown")
	var channel_color = Chat.CHANNEL_COLORS.get(active_channel, Color.WHITE)
	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/ChannelLabel.text = "[%s]" % channel_name
	$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/ChannelLabel.add_theme_color_override("font_color", channel_color)

func _parse_channel_command(command: String) -> bool:
	"""Parse and handle channel commands. Returns true if command was handled."""
	match command:
		"/whisper", "/w":
			active_channel = Chat.Channel.WHISPER
			_update_channel_prefix()
			return true
		"/say", "/s":
			active_channel = Chat.Channel.SAY
			_update_channel_prefix()
			return true
		"/focus", "/f":
			active_channel = Chat.Channel.FOCUS
			_update_channel_prefix()
			return true
		"/group", "/g":
			active_channel = Chat.Channel.GROUP
			_update_channel_prefix()
			return true
		"/public", "/p":
			active_channel = Chat.Channel.PUBLIC
			_update_channel_prefix()
			return true
		"/map", "/m":
			active_channel = Chat.Channel.MAP
			_update_channel_prefix()
			return true
		"/yell", "/y":
			active_channel = Chat.Channel.YELL
			_update_channel_prefix()
			return true
		_:
			return false  # Not a recognized command

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Handle focus_chat action (Enter key)
	if Keybinds.is_action_just_pressed(Keybinds.FOCUS_CHAT):
		$Overlay/CenterContainer/PanelContainer/VBox/BottomBar/LineEdit.grab_focus()
		get_viewport().set_input_as_handled()
		return

	# Handle cycle_chat_channel action (C key)
	if Keybinds.is_action_just_pressed(Keybinds.CYCLE_CHAT_CHANNEL):
		cycle_channel()
		get_viewport().set_input_as_handled()
		return

	# Allow manual scrolling with arrow keys
	if event.is_action_pressed("ui_up"):
		var scrollbar = $Overlay/CenterContainer/PanelContainer/VBox/ScrollContainer.get_v_scroll_bar()
		scrollbar.value -= 50
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down"):
		var scrollbar = $Overlay/CenterContainer/PanelContainer/VBox/ScrollContainer.get_v_scroll_bar()
		scrollbar.value += 50
		get_viewport().set_input_as_handled()
