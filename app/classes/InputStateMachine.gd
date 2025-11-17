extends Object
class_name InputStateMachine

var root: InputNode
var held_buttons: Array = []  # Array of button_key strings
var triggered_actions: Array = []  # All actions triggered this frame

# CACHED DATA - Rebuilt when bindings change
var cached_paths: Dictionary = {}  # button_key -> Array of {path: Array, action: String}

class Builder extends Object:
	var this: InputStateMachine = InputStateMachine.new()

	func root(value: InputNode) -> Builder:
		this.root = value
		return self

	func build() -> InputStateMachine:
		if this.root == null:
			this.root = InputNode.new()
		return this

static func builder() -> Builder:
	return Builder.new()

func register_binding(buttons: Array, action_name: String) -> void:
	"""
	Registers a button combination with an action.
	buttons: Array of button_key strings (e.g., ["joy_btn_4", "joy_btn_3"])
	action_name: The action constant to trigger

	For multi-button combos, generates all permutations where:
	- Earlier buttons must be held
	- Last button triggers the action

	IMPORTANT: Caches all paths after registration.
	"""
	if buttons.size() == 0:
		return

	if buttons.size() == 1:
		# Single button: just press to trigger
		var node = root.add_child(buttons[0])
		node.set_action_name(action_name)
	else:
		# Multi-button: generate all permutations
		var trigger_button = buttons[-1]
		var hold_buttons = buttons.slice(0, buttons.size() - 1)

		var permutations = _generate_permutations(hold_buttons)

		for perm in permutations:
			# Build path: held buttons in this order, then trigger
			var current = root
			for held_btn in perm:
				current = current.add_child(held_btn)

			# Add trigger button as final child
			var leaf = current.add_child(trigger_button)
			leaf.set_action_name(action_name)

	# Rebuild cache after registration
	_rebuild_path_cache()

func _rebuild_path_cache() -> void:
	"""
	Rebuilds the cached paths dictionary.
	Called whenever bindings change.

	Structure: {
		"joy_btn_3": [
			{path: [], action: "action_2"},  # Just Y
			{path: ["joy_btn_4"], action: "action_1"}  # LB then Y
		]
	}
	"""
	cached_paths.clear()
	_traverse_and_cache(root, [])

func _traverse_and_cache(node: InputNode, path_so_far: Array) -> void:
	"""
	Recursively traverses the tree and caches all paths.
	"""
	for button_key in node.children.keys():
		var child = node.children[button_key]

		if child.has_action():
			# This is a leaf - cache the path
			if button_key not in cached_paths:
				cached_paths[button_key] = []

			cached_paths[button_key].append({
				"path": path_so_far.duplicate(),
				"action": child.get_action()
			})

		# Continue traversing
		var new_path = path_so_far.duplicate()
		new_path.append(button_key)
		_traverse_and_cache(child, new_path)

func update(button_events: Array) -> void:
	"""
	Updates state machine with button events for this frame.
	button_events: Array of ButtonEvent objects

	Uses CACHED PATHS for efficient lookup.
	"""
	triggered_actions.clear()

	# Update held buttons list
	for event in button_events:
		if event.is_just_pressed():
			if event.get_button_key() not in held_buttons:
				held_buttons.append(event.get_button_key())
		elif event.is_released():
			held_buttons.erase(event.get_button_key())

	# Check for ALL triggered actions (don't break after first)
	for event in button_events:
		if event.is_just_pressed():
			var action = _check_action_for_button_cached(event.get_button_key())
			if action != "":
				triggered_actions.append(action)

func get_triggered_actions() -> Array:
	return triggered_actions

func clear_triggered_actions() -> void:
	triggered_actions.clear()

func _check_action_for_button_cached(just_pressed_button: String) -> String:
	"""
	Checks if pressing this button triggers an action using CACHED PATHS.
	Much faster than generating permutations every frame.
	"""
	if just_pressed_button not in cached_paths:
		return ""

	# Get buttons that were held BEFORE this press
	var held_before_press = held_buttons.duplicate()
	held_before_press.erase(just_pressed_button)

	# Check all cached paths for this button
	var paths = cached_paths[just_pressed_button]

	# Sort paths by length (longest first) for priority
	paths.sort_custom(func(a, b): return a.path.size() > b.path.size())

	for path_entry in paths:
		var required_path = path_entry.path

		# Check if all buttons in required_path are held
		var all_held = true
		for required_btn in required_path:
			if required_btn not in held_before_press:
				all_held = false
				break

		if all_held:
			# All required buttons held - this path wins
			return path_entry.action

	return ""

func _generate_permutations(arr: Array) -> Array:
	"""
	Generates all permutations of an array.
	Only called during binding registration, not every frame.
	"""
	if arr.size() == 0:
		return [[]]

	if arr.size() == 1:
		return [arr]

	var result = []
	for i in range(arr.size()):
		var elem = arr[i]
		var rest = arr.duplicate()
		rest.remove_at(i)
		var perms = _generate_permutations(rest)
		for perm in perms:
			result.append([elem] + perm)

	return result
