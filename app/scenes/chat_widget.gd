extends Widget

const TICK_RATE: float = 0.66 # Seconds
const MAX_MESSAGE_HISTORY: int = 1000

var chat_queue: Array[Chat] = []
var message_history: Array[Chat] = []  # Persistent history for Feeds view
var needs_render: bool = true
var ui_state_machine: Node
var active_channel: int = Chat.Channel.PUBLIC
var enabled_channels: Dictionary = {
	Chat.Channel.WHISPER: true,
	Chat.Channel.SAY: true,
	Chat.Channel.FOCUS: true,
	Chat.Channel.GROUP: true,
	Chat.Channel.PUBLIC: true,
	Chat.Channel.MAP: true,
	Chat.Channel.YELL: true,
	Chat.Channel.LOG: false  # Disabled by default
}

func _ready() -> void:
	ui_state_machine = get_node("/root/UIStateMachine")
	$Timer.wait_time = TICK_RATE
	$Timer.timeout.connect(_process_chat)
	$Timer.autostart = true
	$Timer.start()
	$VBox/InputRow/LineEdit.text_submitted.connect(_on_text_submitted)
	$VBox/InputRow/LineEdit.focus_entered.connect(_on_chat_focus_entered)
	$VBox/InputRow/LineEdit.focus_exited.connect(_on_chat_focus_exited)
	add_to_group(Group.UI_CHAT_WIDGET)
	_update_channel_prefix()
	# Start with input row hidden and margin spacer visible
	$VBox/InputRow.visible = false
	$VBox/MarginSpacer.visible = true

func submit_message(author: String, message: String, channel: int = Chat.Channel.PUBLIC, recipient: String = "") -> void:
	var new_chat: Chat = Chat.builder().text(message).author(author).channel(channel).recipient(recipient).build()

	# Add to history (keep last MAX_MESSAGE_HISTORY messages)
	message_history.append(new_chat)
	if message_history.size() > MAX_MESSAGE_HISTORY:
		message_history.pop_front()

	# Only add to display queue if channel is enabled
	if enabled_channels.get(channel, true):
		chat_queue.append(new_chat)
		needs_render = true
	
func pop_n_chat(n: int) -> void:
	if n > 0: 
		needs_render = true
	chat_queue = chat_queue.slice(n, chat_queue.size())

func render() -> void:
	$VBox/Text.clear()
	for chat: Chat in chat_queue:
		$VBox/Text.append_text(chat.render())
	needs_render = false

func _on_text_submitted(new_text: String) -> void:
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
				$VBox/InputRow/LineEdit.clear()
				$VBox/InputRow/LineEdit.release_focus()
				return
		# If not a channel command, pass through as-is (for future extensibility)

	# Check if final message is empty or whitespace-only
	if new_text.strip_edges().is_empty():
		$VBox/InputRow/LineEdit.clear()
		$VBox/InputRow/LineEdit.release_focus()
		return

	$VBox/InputRow/LineEdit.clear()
	$VBox/InputRow/LineEdit.release_focus()
	var primary_actor: Actor = Finder.get_primary_actor()
	Controller.submit_chat_request_to_server.rpc_id(1, primary_actor.name, new_text, active_channel)
	# State transition happens in focus_exited

func _on_chat_focus_entered() -> void:
	$VBox/InputRow.visible = true
	$VBox/MarginSpacer.visible = false
	ui_state_machine.transition_to(ui_state_machine.State.CHAT_ACTIVE)

func _on_chat_focus_exited() -> void:
	$VBox/InputRow.visible = false
	$VBox/MarginSpacer.visible = true
	ui_state_machine.transition_to(ui_state_machine.State.GAMEPLAY)

func _process_chat() -> void:
	var now: int = Time.get_unix_time_from_system()
	var num_expired_chats: int = chat_queue.filter(func(chat: Chat): return chat.get_expiry() < now).size()
	pop_n_chat(num_expired_chats)
	if needs_render:
		render()

func focus_chat_input() -> void:
	"""Focus the chat input field"""
	$VBox/InputRow.visible = true
	$VBox/MarginSpacer.visible = false
	$VBox/InputRow/LineEdit.grab_focus()

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
	$VBox/InputRow/ChannelLabel.text = "[%s]" % channel_name
	$VBox/InputRow/ChannelLabel.add_theme_color_override("font_color", channel_color)

func toggle_channel(channel: int, enabled: bool) -> void:
	"""Enable or disable a specific channel from being displayed"""
	enabled_channels[channel] = enabled
	# Re-filter the chat queue
	_refilter_chat_queue()

func _refilter_chat_queue() -> void:
	"""Rebuild chat queue based on enabled channels"""
	chat_queue.clear()
	for chat in message_history:
		if enabled_channels.get(chat.get_channel(), true) and chat.get_expiry() >= Time.get_unix_time_from_system():
			chat_queue.append(chat)
	needs_render = true

func get_message_history() -> Array[Chat]:
	"""Return the full message history for the Feeds view"""
	return message_history

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
