extends Node

func load_json(json_file_path: String):
	if FileAccess.file_exists(json_file_path):
		var result
		var file = FileAccess.open(json_file_path, FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error:
			Logger.error(json.get_error_message())
			result = error
		else:
			result = json.get_data()
		file.close()
		return result
	return FAILED

func parse_json(json_string: String):
	var json = JSON.new()
	if json.parse(json_string) == OK:
		return json.get_data()
	else:
		Logger.error(json.get_error_message())

func save_json(path: String, data) -> void:
	save_file(path, JSON.stringify(data, "\t"))

func use_dir(dir: String) -> void:
	if !DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_absolute(dir)
		
func use_file(file_path: String, content: String) -> void:
	if !FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		if file == null:
			push_error(FileAccess.get_open_error())
		file.store_string(content)
		file.close()
		
func get_dir() -> String:
	var path_arr = OS.get_executable_path().split("/")
	return "/".join(path_arr.slice(0, -1)) + "/"

func load_asset(key: String, map_name: String, flag: int = 0):
	var archive := ZIPReader.new()
	var path: String = Path.builder()\
		.root()\
		.part(get_dir())\
		.part(Cache.dir)\
		.part(map_name)\
		.extension(".zip")\
		.build()\
		.render()
	var err := archive.open(path)
	if err != OK:
		return null
	var data = archive.read_file(key)
	archive.close()
	if key.to_lower().ends_with(".json"):
		var json_result = parse_json(data.get_string_from_utf8())
		if json_result != null:
			return json_result
		else:
			return null
	elif key.to_lower().ends_with(".png"):
		var img: Image = Image.new()
		if flag:
			img.convert(flag)
		if img.load_png_from_buffer(data) == OK:
			return ImageTexture.create_from_image(img)
		else:
			return null
	else:
		return data.get_string_from_utf8()

func load_file(path: String):
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		return file.get_as_text()
	return FAILED
	
func save_file(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Unable to save file [%s]" % path)
	file.store_string(content)
	file.close()

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
