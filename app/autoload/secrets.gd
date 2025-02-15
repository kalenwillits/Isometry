extends Node

var crypto: Crypto = Crypto.new()
var public_key: CryptoKey
var private_key: CryptoKey

class Auth extends Object:
	const HASH_LEN: int = 9
	const DELIM: String = "."
	const INVALID_CHARACTERS: String = """<>:"'/\\|?*~!@#$%^&()={}[];.`"""

	var _username: String
	var _password: String
	var _token: PackedByteArray
	var _hash: String
	var _path: String = ""

	class Builder extends Object:
		var this: Auth = Auth.new()

		func token(value: PackedByteArray) -> Auth.Builder:
			this.set_token(value)
			return self

		func username(value: String) -> Auth.Builder:
			this.set_username(value)
			return self

		func password(value: String) -> Auth.Builder:
			this.set_password(value)
			return self

		func build() -> Auth:
			this._build_token()
			this._build_path()
			return this

	static func builder() -> Auth.Builder:
		return Auth.Builder.new()

	func is_valid() -> bool:
		return _is_valid_username(_username) and _is_valid_password(_password) and !OS.has_feature("trial")

	func get_token() -> PackedByteArray:
		return _token

	func get_username() -> String:
		return _username

	func get_password() -> String:
		return _password

	func get_hash() -> String:
		return _hash

	func get_path() -> String:
		return _path

	func _build_path():
		_path = Path.builder().root().part(io.get_dir()).part("data").part(get_hash()).extension(".json").build().render()

	func set_username(value: String) -> void:
		_username = value.strip_edges()

	func set_password(value: String) -> void:
		_password = value.strip_edges()
		
	func create_hash(input: String) -> String:
		return str(hash(input))

	func set_token(value: PackedByteArray) -> void:
		_token = value
		var raw = Secret.decrypt(_token).split(DELIM)
		if raw.size() == 2:
			_username = raw[0]
			_password = raw[1]
		_hash = create_hash("%s%s%s" % [_username.strip_edges(), DELIM, _password.strip_edges()])

	func _build_token() -> void:
		if _token.is_empty() and (_username != "" and _password != ""):
			_token = Secret.encrypt("%s%s%s" % [_username.strip_edges(), DELIM, _password.strip_edges()])
			_hash = create_hash("%s%s%s" % [_username.strip_edges(), DELIM, _password.strip_edges()])

	func _is_valid_username(value: String) -> bool:
		return not value.is_empty() and not _contains_invalid_characters(value)

	func _is_valid_password(value: String) -> bool:
		return not value.is_empty() and not _contains_invalid_characters(value)

	func _contains_invalid_characters(value: String) -> bool:
		for char in INVALID_CHARACTERS:
			if char in value:
				return true
		return false

func get_auth() -> Auth:
	return Auth.builder().username(Cache.username).password(Cache.password).build()

func encrypt(value: String) -> PackedByteArray:
	if public_key == null:
		push_error("Public key not set!")
		return PackedByteArray()
	var data = value
	return crypto.encrypt(public_key, data.to_utf8_buffer())

func decrypt(value: PackedByteArray) -> String:
	if private_key == null:
		push_error("Private key not available!")
		return ""
	var decrypted = crypto.decrypt(private_key, value)
	return decrypted.get_string_from_utf8()

func load_or_create_rsa() -> void: # For servers
	io.use_dir(Config.rsa_dir)
	if FileAccess.file_exists(Config.rsa_key) and FileAccess.file_exists(Config.rsa_pub):
		private_key = load_key(Config.rsa_key)
		public_key = load_key(Config.rsa_pub)
	else:
		var key = crypto.generate_rsa(2048)
		private_key = key
		public_key = key
		io.save_file(Config.rsa_key, key.save_to_string(false))
		io.save_file(Config.rsa_pub, key.save_to_string(true))

func load_key(path: String) -> CryptoKey:
	var key_pem: PackedByteArray = io.load_buffer(path)
	if key_pem.is_empty():
		push_error("Failed to load key from %s" % path)
		return null
	var key = CryptoKey.new()
	if key.load_from_string(key_pem.get_string_from_utf8(), path == Config.rsa_pub) != OK:
		push_error("Failed to parse key from %s" % path)
		return null
	return key

func set_public_key(value: String) -> void:
	public_key = CryptoKey.new()
	if public_key.load_from_string(value, true) != OK:
		push_error("Failed to set public key")

func get_public_key() -> String:
	return public_key.save_to_string(true) if public_key != null else ""
