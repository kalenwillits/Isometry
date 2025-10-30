extends Node

func _ready() -> void:
	add_to_group(Group.INTERFACE)

func _process(_delta: float) -> void:
	update_primary_actor_info()
		
func update_primary_actor_info() -> void:
	if $DebugView.visible:
		var primary_actor: Actor = Finder.get_primary_actor()
		if primary_actor:
			var actor_ent: Entity = Repo.query([primary_actor.actor]).pop_front()
			set_display_name(primary_actor.display_name)
			set_position(str(primary_actor.position))
			set_origin(str(primary_actor.origin))
			set_destination(str(primary_actor.destination))
			set_speed(str(primary_actor.speed))
			set_heading(primary_actor.heading)
			set_state(primary_actor.state)
			set_target(primary_actor.target)
			if actor_ent.skills:
				var skills_list = actor_ent.skills.lookup()
				if skills_list:
					var max_skills = min(skills_list.size(), 9)
					for i in range(max_skills):
						var skill_ent = skills_list[i]
						if skill_ent and skill_ent.key():
							var slot_number = i + 1
							$DebugView/VBox/HBox/VBoxLeft/VBoxBot.get_node("ActionLabel%s" % slot_number).set_text("%s: %s" % [slot_number, skill_ent.key()])	

func set_display_name(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/DisplayNameLabel.set_text("DISPLAY NAME: %s" % value)
	
func set_position(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/LocationLabel.set_text("POSITION: %s" % value)
	
func set_origin(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/OriginLabel.set_text("ORIGIN: %s" % value)
	
func set_destination(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/DestinationLabel.set_text("DESTINATION: %s" % value)
	
func set_speed(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/SpeedLabel.set_text("SPEED: %s" % value)

func set_heading(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/HeadingLabel.set_text("HEADING: %s" % value)
	
func set_state(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/StateLabel.set_text("STATE: %s" % value)
	
func set_target(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/TargetLabel.set_text("TARGET: %s" % value)

func open_selection_menu_for_actor(target_actor_name: String) -> void:
	var target_actor = Finder.get_actor(target_actor_name)
	if not target_actor:
		Logger.warn("Target actor not found: %s" % target_actor_name, self)
		return

	var actor_ent: Entity = Repo.select(target_actor.actor)
	if actor_ent and actor_ent.menu:
		var menu_ent: Entity = actor_ent.menu.lookup()
		if menu_ent:
			var primary_actor = Finder.get_primary_actor()
			if primary_actor:
				$ContextMenu.open_menu(target_actor.display_name, menu_ent, primary_actor.name, target_actor_name)
			else:
				Logger.warn("Primary actor not found", self)
		else:
			Logger.warn("Menu entity not found in Repo", self)
	else:
		Logger.warn("Actor entity has no menu or entity not found", self)

func open_selection_menu_for_entity(entity_key: String, actor_name: String) -> void:
	var entity: Entity = Repo.select(entity_key)
	if not entity or not entity.menu:
		return

	var menu_ent: Entity = entity.menu.lookup()
	if menu_ent:
		$ContextMenu.open_menu(entity.name_ if entity.get("name_") else entity_key, menu_ent, actor_name, actor_name)

func open_plate_for_actor(plate_key: String, caller: String, target: String) -> void:
	var plate_ent: Entity = Repo.select(plate_key)
	if plate_ent == null:
		Logger.warn("Plate entity not found: %s" % plate_key, self)
		return

	$PlateView.open_plate(plate_ent, caller, target)

func open_global_menu() -> void:
	$GlobalMenuView.open_menu()

func open_system_menu() -> void:
	$SystemMenuView.open_menu()

func open_resources_menu() -> void:
	$ResourcesMenuView.open_menu()

func open_options_view() -> void:
	$OptionsView.open_view()

func close_options_view() -> void:
	$OptionsView.close_view()

func open_keybinds_view() -> void:
	$KeybindsView.visible = true

func close_keybinds_view() -> void:
	$KeybindsView.visible = false

func open_gamepad_view() -> void:
	$GamepadView.visible = true

func close_gamepad_view() -> void:
	$GamepadView.visible = false

func open_map_view() -> void:
	Logger.info("Interface: Opening map view", self)
	$MapView.open_view()

func toggle_map_view() -> void:
	Logger.info("Interface: Toggling map view (current visible: %s)" % $MapView.visible, self)
	if $MapView.visible:
		$MapView.close_view()
	else:
		$MapView.open_view()

func open_close_confirmation() -> void:
	$ConfirmationModal.open_modal(
		"Are you sure you want to quit?",
		func(): get_tree().quit(),  # Yes callback
		func(): pass  # No callback (just closes modal)
	)

func _unhandled_input(event: InputEvent) -> void:
	# Check for map view toggle
	if event.is_action_pressed("toggle_map_view"):
		# Don't open map view if other menus are visible
		if not ($GlobalMenuView.visible or $SystemMenuView.visible or $ResourcesMenuView.visible or $OptionsView.visible or $KeybindsView.visible or $GamepadView.visible or $ContextMenu.visible or $PlateView.visible or $ConfirmationModal.visible):
			toggle_map_view()
			get_viewport().set_input_as_handled()
		return

	# Check if escape key is pressed
	if event.is_action_pressed("menu_cancel"):
		# Check if any menu is currently visible
		if $GlobalMenuView.visible:
			# GlobalMenuView handles its own escape
			return
		elif $SystemMenuView.visible:
			# SystemMenuView handles its own escape
			return
		elif $ResourcesMenuView.visible:
			# ResourcesMenuView handles its own escape
			return
		elif $OptionsView.visible:
			# OptionsView handles its own escape
			return
		elif $KeybindsView.visible:
			# KeybindsView handles its own escape
			return
		elif $GamepadView.visible:
			# GamepadView handles its own escape
			return
		elif $MapView.visible:
			# MapView handles its own escape
			return
		elif $ContextMenu.visible:
			# ContextMenu handles its own escape
			return
		elif $PlateView.visible:
			# PlateView handles its own escape
			return
		elif $ConfirmationModal.visible:
			# ConfirmationModal handles its own escape
			return
		else:
			# No menus open - open global menu
			open_global_menu()
			get_viewport().set_input_as_handled()
