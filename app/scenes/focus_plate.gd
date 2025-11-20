extends Widget

const resource_block_packed_scene: PackedScene = preload("res://scenes/resource_block.tscn")

@export var actor: String ## The actor's name that this plate represents
@export var check_in_view: bool = false ## If true, resource blocks will show "---" when out of view

var update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.1

# Theme name to file suffix mapping
const THEME_FILE_NAMES: Dictionary = {
	"Dark": "dark",
	"Light": "light",
	"Monokai": "monokai",
	"Dracula": "dracula",
	"Solarized Dark": "solarized-dark",
	"Nord": "nord",
	"Gruvbox": "gruvbox",
	"One Dark": "one-dark",
	"Tokyo Night": "tokyo-night",
	"Cobalt": "cobalt",
	"Material": "material",
	"Atom One Light": "atom-one-light",
}

func _ready() -> void:
	# Load themed icons FIRST (before any theme processing)
	var theme_mgr = get_node_or_null("/root/ThemeManager")
	if theme_mgr:
		_load_themed_icons(theme_mgr.current_theme)
		# THEN apply current theme to this widget
		theme_mgr._apply_theme_recursive(self)

	if actor == null: return
	if actor == "": return
	var actor_node: Actor = Finder.get_actor(actor)
	if actor_node == null:
		queue_free()
		return
	var actor_ent: Entity = Repo.select(actor_node.actor)

	# Set actor name label
	set_actor_label(actor_node.display_name)

	# Set group label if actor has a valid group
	if actor_node.target_group != "" and actor_node.target_group != Group.DEFAULT_TARGET_GROUP:
		var group_ent: Entity = Repo.select(actor_node.target_group)
		if group_ent != null:
			var group_name: String = ""
			var group_color_hex: String = ""

			if group_ent.name != null:
				group_name = group_ent.name
			if group_ent.color != null:
				group_color_hex = group_ent.color

			if group_name != "" and group_color_hex != "":
				set_group_label(group_name, _parse_hex_color(group_color_hex))
			else:
				hide_group_label()
		else:
			hide_group_label()
	else:
		hide_group_label()

	if actor_ent.public != null:
		for public_resource_key: String in actor_ent.public.keys():
			add_public_resource(public_resource_key)
	# Add public measures
	if actor_ent.measures != null:
		for measure_key: String in actor_ent.measures.keys():
			var measure_ent: Entity = Repo.select(measure_key)
			if measure_ent != null and measure_ent.get("public") == true:
				add_public_resource(measure_key)
	add_to_group(Group.UI_FOCUS_PLATE)
	add_to_group(actor_node.name)

func set_actor_label(text: String) -> void:
	$VBox/HBox/ActorLabel.text = text

func set_group_label(text: String, color: Color) -> void:
	$VBox/GroupLabel.text = text
	$VBox/GroupLabel.add_theme_color_override("font_color", color)
	$VBox/GroupLabel.visible = true

func hide_group_label() -> void:
	$VBox/GroupLabel.visible = false

func set_actor(value: String) -> void:
	actor = value

func add_public_resource(resource_key: String) -> void:
	var resource_block: Widget = resource_block_packed_scene.instantiate()
	resource_block.set_actor(actor)
	resource_block.set_key(resource_key)
	resource_block.set_check_in_view(check_in_view)
	$HBox.add_child(resource_block)

func set_check_in_view(value: bool) -> void:
	check_in_view = value
	for child in $HBox.get_children():
		if child.has_method("set_check_in_view"):
			child.set_check_in_view(value)

func calculate_direction(from_pos: Vector2, to_pos: Vector2) -> String:
	# Calculate the angle between two positions and return 8-way cardinal direction
	var delta = to_pos - from_pos
	var angle = atan2(delta.y, delta.x)

	# Convert angle to degrees (0-360)
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360

	# Map to 8 directions (45 degree segments)
	# East = 0°, South = 90°, West = 180°, North = 270°
	if degrees >= 337.5 or degrees < 22.5:
		return "E"
	elif degrees >= 22.5 and degrees < 67.5:
		return "SE"
	elif degrees >= 67.5 and degrees < 112.5:
		return "S"
	elif degrees >= 112.5 and degrees < 157.5:
		return "SW"
	elif degrees >= 157.5 and degrees < 202.5:
		return "W"
	elif degrees >= 202.5 and degrees < 247.5:
		return "NW"
	elif degrees >= 247.5 and degrees < 292.5:
		return "N"
	else:  # 292.5 to 337.5
		return "NE"

func get_direction_display(direction: String) -> String:
	# Return symbol + text for each direction
	match direction:
		"N":
			return "↑ N"
		"NE":
			return "↗ NE"
		"E":
			return "→ E "
		"SE":
			return "↘ SE"
		"S":
			return "↓ S "
		"SW":
			return "↙ SW"
		"W":
			return "← W "
		"NW":
			return "↖ NW"
		_:
			return " ---"

func check_line_of_sight(from_actor: Actor, to_actor: Actor) -> bool:
	# Check if there's a clear line of sight (no walls blocking)
	if from_actor == null or to_actor == null:
		return false
	return from_actor.line_of_sight_to_point(to_actor.global_position)

func check_reverse_vision(target_actor: Actor, primary_actor: Actor) -> bool:
	# Check if target actor can see the primary actor
	if target_actor == null or primary_actor == null:
		return false
	return primary_actor.name in target_actor.in_view

func check_mutual_targeting(target_actor: Actor, primary_actor: Actor) -> bool:
	# Check if target actor is targeting the primary actor
	if target_actor == null or primary_actor == null:
		return false
	return target_actor.target == primary_actor.name

func update_vision_state_icons() -> void:
	var primary_actor: Actor = Finder.get_primary_actor()
	if primary_actor == null:
		$VBox/HBox/CompassIcon.visible = false
		$VBox/HBox/EyeIcon.visible = false
		$VBox/HBox/CrosshairsIcon.visible = false
		return

	# Don't show vision state for self
	if actor == primary_actor.name:
		$VBox/HBox/CompassIcon.visible = false
		$VBox/HBox/EyeIcon.visible = false
		$VBox/HBox/CrosshairsIcon.visible = false
		return

	var target_actor: Actor = Finder.get_actor(actor)
	if target_actor == null:
		$VBox/HBox/CompassIcon.visible = false
		$VBox/HBox/EyeIcon.visible = false
		$VBox/HBox/CrosshairsIcon.visible = false
		return

	# Hide vision state if actor is out of view
	if actor not in primary_actor.in_view:
		$VBox/HBox/CompassIcon.visible = false
		$VBox/HBox/EyeIcon.visible = false
		$VBox/HBox/CrosshairsIcon.visible = false
		return

	# Show/hide icons based on vision checks
	# Compass = Target has primary actor in view (reverse vision)
	$VBox/HBox/CompassIcon.visible = check_reverse_vision(target_actor, primary_actor)

	# Eye = Line of sight from primary to target
	$VBox/HBox/EyeIcon.visible = check_line_of_sight(primary_actor, target_actor)

	# Crosshairs = Target is targeting primary actor
	$VBox/HBox/CrosshairsIcon.visible = check_mutual_targeting(target_actor, primary_actor)

func update_cardinal_label() -> void:
	var primary_actor: Actor = Finder.get_primary_actor()
	if primary_actor == null:
		$VBox/HBox/CardinalLabel.text = ""
		return

	# Don't show direction for self
	if actor == primary_actor.name:
		$VBox/HBox/CardinalLabel.text = "    "
		return

	var target_actor: Actor = Finder.get_actor(actor)
	if target_actor == null:
		$VBox/HBox/CardinalLabel.text = "    "
		return

	# Hide direction if actor is out of sight
	if actor not in primary_actor.in_view:
		$VBox/HBox/CardinalLabel.text = " ---"
		return

	# Calculate distance
	var distance = primary_actor.global_position.distance_to(target_actor.global_position)
	
	# Hide direction if very close (within 9 units)
	if distance < 9.0:
		$VBox/HBox/CardinalLabel.text = "    "
		return

	# Calculate and display direction
	var direction = calculate_direction(primary_actor.global_position, target_actor.global_position)
	$VBox/HBox/CardinalLabel.text = get_direction_display(direction)

func _parse_hex_color(hex_string: String) -> Color:
	# Parse hex color string (e.g., "#FF0000" or "FF0000")
	if hex_string == "":
		return Color.WHITE

	var hex = hex_string.strip_edges()
	if hex.begins_with("#"):
		hex = hex.substr(1)

	# Validate hex string length
	if hex.length() != 6:
		return Color.WHITE

	# Parse RGB components
	var r = hex.substr(0, 2).hex_to_int()
	var g = hex.substr(2, 2).hex_to_int()
	var b = hex.substr(4, 2).hex_to_int()

	# Check if parsing was successful
	if r < 0 or g < 0 or b < 0 or r > 255 or g > 255 or b > 255:
		return Color.WHITE

	return Color(r / 255.0, g / 255.0, b / 255.0, 1.0)

func _load_themed_icons(theme_name: String) -> void:
	# Get theme file suffix
	var theme_suffix = THEME_FILE_NAMES.get(theme_name, "dark")

	# Load themed icon textures
	var compass_path = "res://assets/generic-icons/compass-solid-full-%s.svg" % theme_suffix
	var eye_path = "res://assets/generic-icons/eye-solid-full-%s.svg" % theme_suffix
	var crosshairs_path = "res://assets/generic-icons/crosshairs-solid-full-%s.svg" % theme_suffix

	# Set textures on icon nodes
	$VBox/HBox/CompassIcon.texture = load(compass_path)
	$VBox/HBox/EyeIcon.texture = load(eye_path)
	$VBox/HBox/CrosshairsIcon.texture = load(crosshairs_path)

func _process(delta: float) -> void:
	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		# Update vision state icons
		update_vision_state_icons()
		# Update cardinal direction label
		update_cardinal_label()
		# Update visibility alpha for out-of-view actors
		if check_in_view:
			var primary_actor: Actor = Finder.get_primary_actor()
			var is_self: bool = primary_actor and actor == primary_actor.name
			modulate.a = 0.5 if primary_actor and not is_self and not actor in primary_actor.in_view else 1.0
