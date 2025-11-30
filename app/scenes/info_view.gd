extends CanvasLayer

func _ready() -> void:
	visible = false
	add_to_group(Group.INFO_VIEW)
	_create_info_display()

	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		ThemeManager._apply_theme_recursive(self)
		_refresh_info()

func _create_info_display() -> void:
	pass

func _refresh_info() -> void:
	var info_list = $Overlay/CenterContainer/PanelContainer/MarginContainer/VBox/ScrollContainer/InfoList
	for child in info_list.get_children():
		child.queue_free()

	_add_section_header(info_list, "Application")
	_add_info_row(info_list, "Name", ProjectSettings.get_setting("application/config/name"))
	_add_info_row(info_list, "Version", ProjectSettings.get_setting("application/config/version"))

	_add_section_header(info_list, "Command Line Arguments")
	if Cache.cliargs.size() > 0:
		for key in Cache.cliargs.keys():
			if key != "password":
				var value = str(Cache.cliargs[key])
				_add_info_row(info_list, key, value)
	else:
		_add_info_row(info_list, "", "No CLI arguments provided")

	_add_section_header(info_list, "External Directories")
	_add_info_row(info_list, "Data Directory", Config.data_dir)
	_add_info_row(info_list, "RSA Directory", Config.rsa_dir)
	_add_info_row(info_list, "User Directory", OS.get_user_data_dir())
	var working_dir = Cache.dir if Cache.dir != "" else io.get_dir()
	_add_info_row(info_list, "Working Directory", working_dir)

	_add_section_header(info_list, "Campaign")
	_add_info_row(info_list, "Name", Cache.campaign if Cache.campaign != "" else "No campaign loaded")

	var main_entities = Repo.query([Group.MAIN_ENTITY])
	if main_entities.size() > 0:
		var main_entity = main_entities[0]
		var notes_text = main_entity.get("notes") if main_entity.get("notes") else "No notes"
		_add_info_row(info_list, "Notes", notes_text)
	else:
		_add_info_row(info_list, "Notes", "No campaign loaded")

func _add_section_header(parent: VBoxContainer, title: String) -> void:
	if parent.get_child_count() > 0:
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 12)
		parent.add_child(spacer)

	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	parent.add_child(label)

func _add_info_row(parent: VBoxContainer, key: String, value: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	if key != "":
		var key_label = Label.new()
		key_label.text = key + ":"
		key_label.custom_minimum_size = Vector2(160, 0)
		key_label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(key_label)

	var value_label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(value_label)

	parent.add_child(hbox)

func open_view() -> void:
	_refresh_info()
	visible = true

func close_view() -> void:
	visible = false

func _unhandled_input(_event: InputEvent) -> void:
	if not visible:
		return
