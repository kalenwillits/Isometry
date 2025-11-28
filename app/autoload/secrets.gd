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
	var _campaign_checksum: String
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

		func campaign_checksum(value: String) -> Auth.Builder:
			this.set_campaign_checksum(value)
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

	func get_campaign_checksum() -> String:
		return _campaign_checksum

	func set_campaign_checksum(value: String) -> void:
		_campaign_checksum = value

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
		var raw: PackedStringArray = Secret.decrypt(_token).split(DELIM)
		if raw.size() == 3:
			_username = raw[0]
			_password = raw[1]
			_campaign_checksum = raw[2]
		elif raw.size() == 2:
			# Fallback for old token format without checksum
			_username = raw[0]
			_password = raw[1]
			_campaign_checksum = ""
		_hash = create_hash("%s%s%s" % [_username.strip_edges(), DELIM, _password.strip_edges()])

	func _build_token() -> void:
		if _token.is_empty() and (_username != "" and _password != ""):
			_token = Secret.encrypt("%s%s%s%s%s" % [_username.strip_edges(), DELIM, _password.strip_edges(), DELIM, _campaign_checksum])
			_hash = create_hash("%s%s%s" % [_username.strip_edges(), DELIM, _password.strip_edges()])

	func _is_valid_username(value: String) -> bool:
		return not value.is_empty() and not _contains_invalid_characters(value)

	func _is_valid_password(value: String) -> bool:
		return not value.is_empty() and not _contains_invalid_characters(value)

	func _contains_invalid_characters(value: String) -> bool:
		for character in INVALID_CHARACTERS:
			if character in value:
				return true
		return false

func get_auth() -> Auth:
	return Auth.builder().username(Cache.username).password(Cache.password).build()

func encrypt(value: String) -> PackedByteArray:
	if public_key == null:
		Logger.error("Secrets: Cannot encrypt - public key not set")
		return PackedByteArray()
	Logger.debug("Encrypting data (%d bytes)" % value.length())
	var data = value
	return crypto.encrypt(public_key, data.to_utf8_buffer())

func decrypt(value: PackedByteArray) -> String:
	if private_key == null:
		Logger.error("Secrets: Cannot decrypt - private key not available")
		return ""
	Logger.debug("Decrypting data (%d bytes)" % value.size())
	var decrypted = crypto.decrypt(private_key, value)
	return decrypted.get_string_from_utf8()

func load_or_create_rsa() -> void: # For servers
	io.use_dir(Config.rsa_dir)
	if FileAccess.file_exists(Config.rsa_key) and FileAccess.file_exists(Config.rsa_pub):
		Logger.info("Loading existing RSA keypair")
		private_key = load_key(Config.rsa_key)
		public_key = load_key(Config.rsa_pub)
		if private_key and public_key:
			Logger.debug("RSA keypair loaded successfully")
	else:
		Logger.info("Generating new RSA keypair (2048 bits)")
		var start_time = Time.get_ticks_usec()
		var key = crypto.generate_rsa(2048)
		var elapsed = Time.get_ticks_usec() - start_time
		Logger.info("RSA keypair generated (took %d µs)" % elapsed)

		private_key = key
		public_key = key
		io.save_file(Config.rsa_key, key.save_to_string(false))
		io.save_file(Config.rsa_pub, key.save_to_string(true))
		Logger.debug("RSA keypair saved to: %s" % Config.rsa_dir)

func load_key(path: String) -> CryptoKey:
	Logger.debug("Loading cryptographic key from: %s" % path)
	var key_pem: PackedByteArray = io.load_buffer(path)
	if key_pem.is_empty():
		Logger.error("Secrets: Failed to load key from %s" % path)
		return null
	var key = CryptoKey.new()
	if key.load_from_string(key_pem.get_string_from_utf8(), path == Config.rsa_pub) != OK:
		Logger.error("Secrets: Failed to parse key from %s" % path)
		return null
	Logger.debug("Key loaded successfully from: %s" % path)
	return key

func set_public_key(value: String) -> void:
	Logger.debug("Setting public key from string")
	public_key = CryptoKey.new()
	if public_key.load_from_string(value, true) != OK:
		Logger.error("Secrets: Failed to set public key")
	else:
		Logger.debug("Public key set successfully")

func get_public_key() -> String:
	return public_key.save_to_string(true) if public_key != null else ""
