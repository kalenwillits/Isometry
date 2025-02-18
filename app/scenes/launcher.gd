extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !Cache.network or !Cache.username or !Cache.password or !Cache.uri or !Cache.port or !Cache.archive:
		$VBox/HBox/VBox/UsernameBox/LineEdit.set_text(Cache.username)
		$VBox/HBox/VBox/PasswordBox/LineEdit.set_text(Cache.password)
		$VBox/HBox/VBox/ArchiveBox/LineEdit.set_text(Cache.archive)
		$VBox/HBox/VBox/UriBox/LineEdit.set_text(Cache.uri)
		$VBox/HBox/VBox/PortBox/LineEdit.set_text(str(Cache.port))
	else:
		Route.start()

func on_submit() -> void:
	Cache.username = $VBox/HBox/VBox/UsernameBox/LineEdit.get_text().strip_edges().strip_escapes()
	Cache.password = $VBox/HBox/VBox/PasswordBox/LineEdit.get_text().strip_edges().strip_escapes()
	Cache.archive = $VBox/HBox/VBox/ArchiveBox/LineEdit.get_text().strip_edges().strip_escapes()
	Cache.uri = $VBox/HBox/VBox/UriBox/LineEdit.get_text().strip_edges().strip_escapes()
	Cache.port = $VBox/HBox/VBox/PortBox/LineEdit.get_text().strip_edges().strip_escapes().to_int()

func _on_host_button_button_up() -> void:
	Cache.network = Network.Mode.HOST
	on_submit()
	Route.start()

func _on_join_button_button_up() -> void:
	Cache.network = Network.Mode.HOST
	on_submit()
	Route.start()
