extends Object
class_name Config

const RSA_DIR: String = ".rsa/"
const RSA_KEY: String = ".rsa/.key"
const RSA_PUB: String = ".rsa/.pub"

func _init() -> void:
	push_error("static class, do not instantiate!")
