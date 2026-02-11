extends CanvasLayer

var campaign_dir: String = ""

func _ready() -> void:
	DisplayServer.window_set_title("Isometry Launcher")
	$VBox/HBox/VBox/UsernameBox/LineEdit.set_text("user1")
	$VBox/HBox/VBox/PasswordBox/LineEdit.set_text("pass1")
	$VBox/HBox/VBox/UriBox/LineEdit.set_text("localhost")
	$VBox/HBox/VBox/PortBox/LineEdit.set_text("5000")
	_scan_campaigns()

func _scan_campaigns() -> void:
	var option_button: OptionButton = $VBox/HBox/VBox/ArchiveBox/OptionButton
	option_button.clear()
	# Look for campaign archives in common locations
	var search_dirs: Array = [
		OS.get_executable_path().get_base_dir().path_join("campaigns"),
		OS.get_executable_path().get_base_dir().path_join("maps/target"),
	]
	# Also check the maps symlink in the Godot data dir
	var user_dir = OS.get_user_data_dir()
	var godot_dir = OS.get_executable_path().get_base_dir()
	if DirAccess.dir_exists_absolute(godot_dir.path_join("maps/target")):
		campaign_dir = godot_dir.path_join("maps/target")
	for dir_path in search_dirs:
		if DirAccess.dir_exists_absolute(dir_path):
			campaign_dir = dir_path
			break
	if campaign_dir.is_empty():
		campaign_dir = OS.get_executable_path().get_base_dir().path_join("campaigns")
	var da = DirAccess.open(campaign_dir)
	if da:
		da.list_dir_begin()
		var file_name = da.get_next()
		while file_name != "":
			if file_name.ends_with(".zip"):
				option_button.add_item(file_name.get_basename())
			file_name = da.get_next()
		da.list_dir_end()
	if option_button.item_count == 0:
		option_button.add_item("(no campaigns found)")
		option_button.disabled = true

func _get_game_binary() -> String:
	var exe_dir = OS.get_executable_path().get_base_dir()
	if OS.has_feature("windows"):
		return exe_dir.path_join("isometry_windows.exe")
	elif OS.has_feature("macos"):
		return exe_dir.path_join("isometry_macos.app")
	else:
		return exe_dir.path_join("isometry_linux.x86_64")

func _launch_game(network_mode: String) -> void:
	var option_button: OptionButton = $VBox/HBox/VBox/ArchiveBox/OptionButton
	var campaign = option_button.get_item_text(option_button.selected)
	var username = $VBox/HBox/VBox/UsernameBox/LineEdit.get_text().strip_edges()
	var password = $VBox/HBox/VBox/PasswordBox/LineEdit.get_text().strip_edges()
	var uri = $VBox/HBox/VBox/UriBox/LineEdit.get_text().strip_edges()
	var port = $VBox/HBox/VBox/PortBox/LineEdit.get_text().strip_edges()

	var binary = _get_game_binary()
	var exe_dir = OS.get_executable_path().get_base_dir()
	var relative_dir = campaign_dir.trim_prefix(exe_dir).lstrip("/")
	var args: Array = [
		"--campaign=%s" % campaign,
		"--uri=%s" % uri,
		"--port=%s" % port,
		"--network=%s" % network_mode,
		"--dir=%s" % relative_dir,
		"--username=%s" % username,
		"--password=%s" % password,
	]

	OS.create_process(binary, args)

func _on_host_button_button_up() -> void:
	_launch_game("host")

func _on_join_button_button_up() -> void:
	_launch_game("client")
