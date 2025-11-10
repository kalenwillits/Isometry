extends Object
class_name InputNode

var children: Dictionary = {}  # button_key (String) -> InputNode
var action: String = ""  # Action to trigger (empty if not leaf)

class Builder extends Object:
	var this: InputNode = InputNode.new()

	func children(value: Dictionary) -> Builder:
		this.children = value
		return self

	func action(value: String) -> Builder:
		this.action = value
		return self

	func build() -> InputNode:
		return this

static func builder() -> Builder:
	return Builder.new()

func add_child(button_key: String) -> InputNode:
	if button_key not in children:
		children[button_key] = InputNode.new()
	return children[button_key]

func get_child(button_key: String) -> InputNode:
	return children.get(button_key, null)

func has_action() -> bool:
	return action != ""

func get_action() -> String:
	return action

func set_action_name(action_name: String) -> void:
	action = action_name
