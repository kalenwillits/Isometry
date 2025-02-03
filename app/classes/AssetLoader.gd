extends Object
class_name AssetLoader

## Note that loading audio requires a 44,100 sample rate. Any different sample rate will sound awful.

enum Type {
	OBJECT, # JSON is already in Godot's namespace
	IMAGE,
	TEXT,
	MP3,
	WAV
}

var key: String
var archive: String
var type: Type
var loop: bool = false  # Audio files only

class Builder:
	var obj := AssetLoader.new()
	
	func key(value: String) -> Builder:
		obj.key = value
		return self
		
	func archive(value: String) -> Builder:
		obj.archive = value
		return self
	
	func loop(value: bool) -> Builder:
		obj.loop = value
		return self

	func type(value: Type) -> Builder:
		obj.type = value
		return self

	func build() -> AssetLoader:
		return obj

static func builder() -> Builder:
	return Builder.new()

func pull():
	match type:
		Type.OBJECT:
			return _load_record_as_dict()
		Type.IMAGE:
			return _load_record_as_image_texture()
		Type.TEXT:
			return _load_record_as_string()
		Type.WAV:
			return _load_record_as_wav()
		Type.MP3:
			return _load_record_as_mp3()
	
func _load_record_as_bytes() -> PackedByteArray:
	var archive_zip_reader := ZIPReader.new()
	var archive_path: String = Path.builder()\
		.root()\
		.part(io.get_dir())\
		.part(Cache.dir)\
		.part(archive)\
		.extension(".zip")\
		.build()\
		.render()
	var err := archive_zip_reader.open(archive_path)
	if err:
		Logger.error("Failed to open archive from archive [%s]" % archive_path)
	var record_path = Path.builder().part(archive).part(key).build().render()
	var result: PackedByteArray = archive_zip_reader.read_file(record_path)
	archive_zip_reader.close()
	return result
	
func _load_record_as_dict() -> Dictionary:
	var data: PackedByteArray = _load_record_as_bytes()
	return io.parse_json(data.get_string_from_utf8())
	
func _load_record_as_image_texture() -> ImageTexture:
	var data: PackedByteArray = _load_record_as_bytes()
	var img: Image = Image.new()
	if img.load_png_from_buffer(data) != OK:
		Logger.error("Failed to load image from archive %s" % key)
	return ImageTexture.create_from_image(img)
	
func _load_record_as_mp3() -> AudioStreamMP3:
	var data: PackedByteArray = _load_record_as_bytes()
	var mp3_stream: AudioStreamMP3 = AudioStreamMP3.new()
	mp3_stream.set_data(data)
	mp3_stream.set_loop(loop)
	return mp3_stream

func _load_record_as_wav() -> AudioStreamWAV:
	var data: PackedByteArray = _load_record_as_bytes()
	var wav_stream: AudioStreamWAV = AudioStreamWAV.new()
	wav_stream.set_data(data)
	wav_stream.set_loop_mode(AudioStreamWAV.LoopMode.LOOP_FORWARD if loop else AudioStreamWAV.LoopMode.LOOP_DISABLED)
	return wav_stream
	
func _load_record_as_string() -> String:
	var data: PackedByteArray = _load_record_as_bytes()
	return data.get_string_from_utf8()
	
static func derive_type_from_path(path: String) -> Optional:
	path = path.to_lower()
	if path.ends_with(".json"): return Optional.of(Type.OBJECT)
	if path.ends_with(".png"): return Optional.of(Type.IMAGE)
	if path.ends_with(".jpg"): return Optional.of(Type.IMAGE)
	if path.ends_with(".jpeg"): return Optional.of(Type.IMAGE)
	if path.ends_with(".wav"): return Optional.of(Type.WAV)
	if path.ends_with(".mp3"): return Optional.of(Type.MP3)
	if path.ends_with(".txt"): return Optional.of(Type.TEXT)
	return Optional.empty()
	
