extends Object
class_name Chat

const TTL: int = 60 # Seconds

enum Channel {
	WHISPER,  # Magenta - DM to target
	SAY,      # White - actors with sender in view
	FOCUS,    # Cyan - actors in sender's focus slots
	GROUP,    # Blue - actors in same target_group
	PUBLIC,   # Yellow/Golden - broadcast to all
	MAP,      # Orange - all actors on current map
	YELL,     # Red - actors within 2x(salience+perception)
	LOG       # Gray - system messages and errors
}

const CHANNEL_COLORS: Dictionary = {
	Channel.WHISPER: Color("#FF00FF"),  # Magenta
	Channel.SAY: Color("#FFFFCC"),      # Pale Yellow
	Channel.FOCUS: Color("#00FFFF"),    # Cyan
	Channel.GROUP: Color("#0080FF"),    # Blue
	Channel.PUBLIC: Color("#FFFFFF"),   # White
	Channel.MAP: Color("#FF8C00"),      # Orange
	Channel.YELL: Color("#FF0000"),     # Red
	Channel.LOG: Color("#808080")       # Gray
}

const CHANNEL_NAMES: Dictionary = {
	Channel.WHISPER: "Whisper",
	Channel.SAY: "Say",
	Channel.FOCUS: "Focus",
	Channel.GROUP: "Group",
	Channel.PUBLIC: "Public",
	Channel.MAP: "Map",
	Channel.YELL: "Yell",
	Channel.LOG: "Log"
}

var text: String
var timestamp: int
var expiry: int
var author: String
var channel: int = Channel.PUBLIC
var recipient: String = ""

class Builder extends Object:
	var this: Chat = Chat.new()

	func text(value: String) -> Builder:
		this.text = Chat.strip_bbcode(value).strip_edges().strip_escapes()
		return self

	func author(value: String) -> Builder:
		this.author = value
		return self

	func channel(value: int) -> Builder:
		this.channel = value
		return self

	func recipient(value: String) -> Builder:
		this.recipient = value
		return self

	func build() -> Chat:
		this.timestamp = Time.get_unix_time_from_system()
		this.expiry = this.timestamp + TTL
		return this

static func builder() -> Builder:
	return Builder.new()

static func strip_bbcode(value: String) -> String:
	var regex: RegEx = RegEx.new()
	regex.compile("\\[.*?\\]")
	return regex.sub(value, "", true)

func get_text() -> String:
	return text

func get_timestamp() -> int:
	return timestamp

func get_author() -> String:
	return author

func get_expiry() -> int:
	return expiry

func get_channel() -> int:
	return channel

func get_recipient() -> String:
	return recipient

func get_channel_name() -> String:
	return CHANNEL_NAMES.get(channel, "Unknown")

func get_channel_color() -> Color:
	return CHANNEL_COLORS.get(channel, Color.WHITE)

func render() -> String:
	var color_hex: String = get_channel_color().to_html(false)
	var author_text: String = ""

	if channel == Channel.WHISPER and not recipient.is_empty():
		author_text = "[i]%s→%s:[/i] " % [author, recipient]
	else:
		author_text = "[i]%s:[/i] " % author

	var content: String = "[color=#%s]%s%s[/color]" % [color_hex, author_text, text]
	return "\n%s" % content
