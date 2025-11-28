extends Node

func load_json(json_file_path: String):
	if FileAccess.file_exists(json_file_path):
		var start_time = Time.get_ticks_usec()
		Logger.debug("Loading JSON file: %s" % json_file_path)

		var result
		var file = FileAccess.open(json_file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error:
			Logger.error("I/O: JSON parse error in %s - %s" % [json_file_path, json.get_error_message()])
			result = error
		else:
			result = json.get_data()
		file.close()

		var elapsed = Time.get_ticks_usec() - start_time
		Logger.debug("JSON file loaded: %s (took %d µs)" % [json_file_path, elapsed])
		return result

	Logger.error("I/O: JSON file not found: %s" % json_file_path)
	return FAILED

func parse_json(json_string: String):
	var json = JSON.new()
	if json.parse(json_string) == OK:
		return json.get_data()
	else:
		Logger.error(json.get_error_message())
		
func save_buffer(path: String, data: PackedByteArray) -> void:
	var start_time = Time.get_ticks_usec()
	Logger.debug("Saving buffer: %s (%d bytes)" % [path, data.size()])

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		Logger.error("I/O: Failed to save buffer %s (error_code=%d)" % [path, error])
		return

	file.store_buffer(data)
	var elapsed = Time.get_ticks_usec() - start_time
	Logger.debug("Buffer saved: %s (took %d µs)" % [path, elapsed]) 
	
func load_buffer(path: String) -> PackedByteArray:
	var start_time = Time.get_ticks_usec()
	Logger.debug("Loading buffer: %s" % path)

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		Logger.error("I/O: Failed to load buffer %s (error_code=%d)" % [path, error])
		return PackedByteArray()

	# Maybe this works?
	var buffer = file.get_as_text().to_utf8_buffer()
	var elapsed = Time.get_ticks_usec() - start_time
	Logger.debug("Buffer loaded: %s (%d bytes, took %d µs)" % [path, buffer.size(), elapsed])
	return buffer

func save_json(path: String, data) -> void:
	save_file(path, JSON.stringify(data, "\t"))

func use_dir(dir: String) -> void:
	if !DirAccess.dir_exists_absolute(dir):
		Logger.info("Creating directory: %s" % dir)
		var error = DirAccess.make_dir_recursive_absolute(dir)
		if error != OK:
			Logger.error("I/O: Failed to create directory %s (error_code=%d)" % [dir, error])
		else:
			Logger.debug("Directory created: %s" % dir)
		
func use_file(file_path: String, content: String) -> void:
	if !FileAccess.file_exists(file_path):
		Logger.debug("Creating file: %s" % file_path)
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file == null:
			var error = FileAccess.get_open_error()
			Logger.error("I/O: Failed to create file %s (error_code=%d)" % [file_path, error])
			return
		file.store_string(content)
		file.close()
		Logger.debug("File created: %s (%d bytes)" % [file_path, content.length()])
		
func get_dir() -> String:
	var path_arr = OS.get_executable_path().split("/")
	return "/".join(path_arr.slice(0, -1)) + "/"

func load_asset(key: String, campaign_name: String, flag: int = 0):
	## Dynamic return type
	var start_time = Time.get_ticks_usec()
	Logger.debug("Loading asset: %s from campaign %s" % [key, campaign_name])

	var archive := ZIPReader.new()
	var path: String = Path.builder()\
		.root()\
		.part(get_dir())\
		.part(Cache.dir)\
		.part(campaign_name)\
		.extension(".zip")\
		.build()\
		.render()
	var err := archive.open(path)
	if err != OK:
		Logger.error("I/O: Failed to open campaign archive %s (error_code=%d)" % [path, err])
		return null

	var data = archive.read_file(key)
	archive.close()

	var result = null
	if key.to_lower().ends_with(".json"):
		var json_result = parse_json(data.get_string_from_utf8())
		if json_result != null:
			result = json_result
		else:
			Logger.error("I/O: Failed to parse JSON asset: %s" % key)
	elif key.to_lower().ends_with(".png"):
		var img: Image = Image.new()
		if flag:
			img.convert(flag)
		if img.load_png_from_buffer(data) == OK:
			result = ImageTexture.create_from_image(img)
		else:
			Logger.error("I/O: Failed to load PNG asset: %s" % key)
	else:
		result = data.get_string_from_utf8()

	var elapsed = Time.get_ticks_usec() - start_time
	if result != null:
		Logger.debug("Asset loaded: %s (%d bytes, took %d µs)" % [key, data.size(), elapsed])
	return result

func load_file(path: String):
	var start_time = Time.get_ticks_usec()
	Logger.debug("Loading file: %s" % path)

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		var content = file.get_as_text()
		var elapsed = Time.get_ticks_usec() - start_time
		Logger.debug("File loaded: %s (%d bytes, took %d µs)" % [path, content.length(), elapsed])
		return content

	var error = FileAccess.get_open_error()
	Logger.error("I/O: Failed to load file %s (error_code=%d)" % [path, error])
	return FAILED
	
func save_file(path: String, content: String) -> void:
	var start_time = Time.get_ticks_usec()
	Logger.debug("Saving file: %s (%d bytes)" % [path, content.length()])

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		Logger.error("I/O: Unable to save file %s (error_code=%d)" % [path, error])
		return

	file.store_string(content)
	file.close()

	var elapsed = Time.get_ticks_usec() - start_time
	Logger.debug("File saved: %s (took %d µs)" % [path, elapsed])

func list_dir(path: String) -> Array:
	var results: Array = []
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var src = dir.get_next()
		while src != "":
			if !dir.current_is_dir():
				results.append(path + src)
			src = dir.get_next()
	return results
