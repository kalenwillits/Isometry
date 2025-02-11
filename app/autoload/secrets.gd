extends Node

var crypto: Crypto = Crypto.new()
var public_key: CryptoKey
var private_key: CryptoKey

func encrypt(value: String) -> String:
	if public_key == null:
		push_error("Public key not set!")
		return ""
	var data = value.to_utf8_buffer()
	var encrypted = crypto.encrypt(public_key, data)
	return Marshalls.raw_to_base64(encrypted)

func decrypt(value: String) -> String:
	if private_key == null:
		push_error("Private key not available!")
		return ""
	var encrypted = Marshalls.base64_to_raw(value)
	var decrypted = crypto.decrypt(private_key, encrypted)
	return decrypted.get_string_from_utf8()

func load_or_create_rsa() -> void: # For servers
	io.use_dir(Config.rsa_dir)
	if FileAccess.file_exists(Config.rsa_key) and FileAccess.file_exists(Config.rsa_pub):
		private_key = load_key(Config.rsa_key)
		public_key = load_key(Config.rsa_key)
	else:
		var key = crypto.generate_rsa(2048)
		private_key = key
		public_key = key
		io.save_file(Config.rsa_key, key.save_to_string(false))
		io.save_file(Config.rsa_pub, key.save_to_string(true))

func load_key(path: String) -> CryptoKey:
	var key_pem = io.load_file(path)
	if key_pem == "":
		push_error("Failed to load key from %s" % path)
		return null
	var key = CryptoKey.new()
	if key.load_from_string(key_pem, path == Config.rsa_pub) != OK:
		push_error("Failed to parse key from %s" % path)
		return null
	return key

func set_public_key(value: String) -> void:
	public_key = CryptoKey.new()
	if public_key.load_from_string(value, true) != OK:
		push_error("Failed to set public key")

func get_public_key() -> String:
	return public_key.save_to_string(true) if public_key != null else ""
