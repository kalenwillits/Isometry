extends Node

func _ready() -> void:
	add_to_group(Group.INTERFACE)
	ThemeManager._apply_theme_recursive(self)
	UIStateMachine.state_changed.connect(_on_ui_state_changed)

func open_selection_menu_for_actor(target_actor_name: String) -> void:
	var target_actor = Finder.get_actor(target_actor_name)
	if not target_actor:
		Logger.warn("Target actor not found: %s" % target_actor_name)
		return

	var actor_ent: Entity = Repo.select(target_actor.actor)
	if actor_ent and actor_ent.menu:
		var menu_ent: Entity = actor_ent.menu.lookup()
		if menu_ent:
			var primary_actor = Finder.get_primary_actor()
			if primary_actor:
				UIStateMachine.open_context_menu()
				$ContextMenu.open_menu(target_actor.display_name, menu_ent, primary_actor.name, target_actor_name)
			else:
				Logger.warn("Primary actor not found")
		else:
			Logger.warn("Menu entity not found in Repo")
	else:
		Logger.warn("Actor entity has no menu or entity not found")

func open_selection_menu_for_entity(entity_key: String, actor_name: String) -> void:
	var entity: Entity = Repo.select(entity_key)
	if not entity or not entity.menu:
		return

	var menu_ent: Entity = entity.menu.lookup()
	if menu_ent:
		UIStateMachine.open_context_menu()
		$ContextMenu.open_menu(entity.name_ if entity.get("name_") else entity_key, menu_ent, actor_name, actor_name)

func open_plate_for_actor(plate_key: String, caller: String, target: String) -> void:
	var plate_ent: Entity = Repo.select(plate_key)
	if plate_ent == null:
		Logger.warn("Plate entity not found: %s" % plate_key)
		return
	UIStateMachine.transition_to(UIStateMachine.State.PLATE_VIEW)
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
	UIStateMachine.transition_to(UIStateMachine.State.MENU_SYSTEM)

func open_gamepad_view() -> void:
	$GamepadView.visible = true

func close_gamepad_view() -> void:
	$GamepadView.visible = false
	UIStateMachine.transition_to(UIStateMachine.State.MENU_SYSTEM)

func open_info_view() -> void:
	$InfoView.open_view()

func close_info_view() -> void:
	$InfoView.close_view()

func open_map_view() -> void:
	Logger.info("Interface: Opening map view")
	$MapView.open_view()

func toggle_map_view() -> void:
	Logger.info("Interface: Toggling map view (current visible: %s)" % $MapView.visible)
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
	# Handle toggle_map_view action
	if Keybinds.is_action_just_pressed(Keybinds.TOGGLE_MAP_VIEW):
		UIStateMachine.handle_toggle_map()
		get_viewport().set_input_as_handled()
		return

	# Handle toggle_resources_view action
	if Keybinds.is_action_just_pressed(Keybinds.TOGGLE_RESOURCES_VIEW):
		UIStateMachine.handle_toggle_resources()
		get_viewport().set_input_as_handled()
		return

	# Handle toggle_skills_view action
	if Keybinds.is_action_just_pressed(Keybinds.TOGGLE_SKILLS_VIEW):
		UIStateMachine.handle_toggle_skills()
		get_viewport().set_input_as_handled()
		return

	# Handle focus_chat action (Enter key by default)
	if Keybinds.is_action_just_pressed(Keybinds.FOCUS_CHAT):
		# Only focus chat when in gameplay state
		if UIStateMachine.current_state == UIStateMachine.State.GAMEPLAY:
			var chat_widget = Finder.select(Group.UI_CHAT_WIDGET)
			if chat_widget:
				chat_widget.focus_chat_input()
			get_viewport().set_input_as_handled()
		return

	# Handle cycle_chat_channel action (C key by default)
	if Keybinds.is_action_just_pressed(Keybinds.CYCLE_CHAT_CHANNEL):
		# Only cycle channels when in gameplay state
		if UIStateMachine.current_state == UIStateMachine.State.GAMEPLAY:
			var chat_widget = Finder.select(Group.UI_CHAT_WIDGET)
			if chat_widget:
				chat_widget.cycle_channel()
			get_viewport().set_input_as_handled()
		return

	# Handle open_menu action (Home key by default)
	if Keybinds.is_action_just_pressed(Keybinds.OPEN_MENU):
		UIStateMachine.handle_open_menu()
		get_viewport().set_input_as_handled()
		return

	# Handle cancel action (ESC)
	if event.is_action_pressed("cancel"):
		UIStateMachine.handle_cancel()
		get_viewport().set_input_as_handled()
		return

## State machine callback - show/hide views based on state transitions
func _on_ui_state_changed(old_state: int, new_state: int) -> void:
	var state_enum = UIStateMachine.State
	Logger.info("Interface: State changed %s -> %s" % [state_enum.keys()[old_state], state_enum.keys()[new_state]])

	# Hide views based on old state
	var State = UIStateMachine.State
	match old_state:
		State.MENU_GLOBAL:
			$GlobalMenuView.visible = false
		State.MENU_SYSTEM:
			$SystemMenuView.visible = false
		State.MENU_RESOURCES:
			$ResourcesMenuView.visible = false
		State.MENU_SKILLS:
			$SkillsMenuView.close_menu()
		State.MENU_OPTIONS:
			$OptionsView.visible = false
		State.MENU_KEYBINDS:
			$KeybindsView.visible = false
		State.MENU_GAMEPAD:
			$GamepadView.visible = false
		State.MENU_INFO:
			$InfoView.visible = false
		State.MENU_MAP:
			$MapView.close_view()
		State.MENU_FEEDS:
			$FeedsView.close_menu()
		State.CONTEXT_MENU:
			$ContextMenu.visible = false
		State.PLATE_VIEW:
			$PlateView.visible = false
		State.CONFIRMATION_MODAL:
			$ConfirmationModal.visible = false

	# Show views based on new state
	match new_state:
		State.MENU_GLOBAL:
			$GlobalMenuView.open_menu()
		State.MENU_SYSTEM:
			$SystemMenuView.open_menu()
		State.MENU_RESOURCES:
			$ResourcesMenuView.open_menu()
		State.MENU_SKILLS:
			$SkillsMenuView.open_menu()
		State.MENU_OPTIONS:
			$OptionsView.open_view()
		State.MENU_KEYBINDS:
			$KeybindsView.visible = true
		State.MENU_GAMEPAD:
			$GamepadView.visible = true
		State.MENU_INFO:
			$InfoView.open_view()
		State.MENU_MAP:
			$MapView.open_view()
		State.MENU_FEEDS:
			$FeedsView.open_menu()
		State.CONTEXT_MENU:
			# Context menu opens itself via open_selection_menu_for_actor
			pass
		State.PLATE_VIEW:
			# Plate view opens itself via open_plate_for_actor
			pass
		State.CONFIRMATION_MODAL:
			# Confirmation modal opens itself
			pass
