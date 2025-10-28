extends Control

var waypoint_key: String = ""
var waypoint_name: String = ""
var is_selected: bool = false
var is_hovered: bool = false
var icon_rect: TextureRect
var name_label: Label

func set_waypoint_key(key: String) -> void:
	waypoint_key = key

	# Get waypoint name
	var waypoint_ent = Repo.select(waypoint_key)
	if waypoint_ent:
		waypoint_name = waypoint_ent.name_

func set_icon(texture: ImageTexture) -> void:
	if icon_rect:
		icon_rect.texture = texture

func set_selected(selected: bool) -> void:
	is_selected = selected
	update_appearance()

func _ready() -> void:
	# Configure control size
	custom_minimum_size = Vector2(32, 32)
	size = Vector2(32, 32)

	# Create TextureRect for icon with outline shader
	icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(32, 32)
	icon_rect.size = Vector2(32, 32)
	icon_rect.position = Vector2(0, 0)

	# Apply outline shader material (same as actors use)
	var actor_material = load("res://materials/actor_sprite.tres")
	if actor_material:
		# Duplicate the material so each waypoint has its own instance
		var shader_material = actor_material.duplicate()
		shader_material.set_shader_parameter("color", Color.WHITE)
		shader_material.set_shader_parameter("width", 2.5)
		shader_material.set_shader_parameter("glow_strength", 0.6)
		shader_material.set_shader_parameter("glow_falloff", 2.2)
		shader_material.set_shader_parameter("glow_samples", 3)
		icon_rect.material = shader_material

	add_child(icon_rect)

	# Create name label (hidden by default)
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-50, -30)  # Above the icon, centered
	name_label.size = Vector2(132, 26)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 3)
	name_label.visible = false
	add_child(name_label)

	# Enable mouse input
	mouse_filter = Control.MOUSE_FILTER_STOP

	update_appearance()

func update_appearance() -> void:
	# Update name label visibility
	if name_label:
		name_label.text = waypoint_name
		name_label.visible = is_hovered or is_selected

	# Update highlight via modulate
	if is_selected:
		modulate = Color(1.5, 1.5, 0.5, 1.0)  # Yellow highlight
	elif is_hovered:
		modulate = Color(1.2, 1.2, 1.2, 1.0)  # Lighter on hover
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)  # Normal

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			activate_waypoint()
			accept_event()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			is_hovered = true
			update_appearance()
		NOTIFICATION_MOUSE_EXIT:
			is_hovered = false
			update_appearance()

func activate_waypoint() -> void:
	var waypoint_ent = Repo.select(waypoint_key)
	if waypoint_ent and waypoint_ent.menu:
		var primary_actor = Finder.get_primary_actor()
		if primary_actor:
			Logger.info("Activating waypoint: %s" % waypoint_key, self)
			Finder.select(Group.INTERFACE).open_selection_menu_for_entity(
				waypoint_key,
				primary_actor.name
			)
