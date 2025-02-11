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
	io.use_dir(Config.RSA_DIR)
	if FileAccess.file_exists(Config.RSA_KEY) and FileAccess.file_exists(Config.RSA_PUB):
		private_key = load_key(Config.RSA_KEY)
		public_key = load_key(Config.RSA_PUB)
	else:
		var keys = crypto.generate_rsa(2048)
		private_key = keys.private
		public_key = keys.public
		io.save_file(Config.RSA_KEY, crypto.save_key_pem(private_key, true))
		io.save_file(Config.RSA_PUB, crypto.save_key_pem(public_key, false))

func load_key(path: String) -> CryptoKey:
	var key_pem = io.load_file(path)
	if key_pem == FAILED:
		push_error("Failed to load key from %s" % path)
		return null
	return crypto.load_from(key_pem, path == Config.RSA_KEY)

func set_public_key(value: String) -> void:
	public_key.load_from_string(value, true)

func get_public_key() -> String:
	return public_key.save_to_string(true)
