extends Object
class_name Chat

const TTL: int = 60 # Seconds

var text: String
var timestamp: int
var expiry: int
var author: String

class Builder extends Object:
	var this: Chat = Chat.new()

	func text(value: String) -> Builder:
		this.text = Chat.strip_bbcode(value).strip_edges().strip_escapes()
		return self

	func author(value: String) -> Builder:
		this.author = value
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

func render() -> String:
	var content: String = "[i]%s[/i]: %s" % [author, text]
	return "\n%s" % content
