extends Node

var data_dir: String = Path.builder().root().part(io.get_dir()).part("data").build().render()
var rsa_dir: String = Path.builder().root().part(io.get_dir()).part(".rsa").build().render()
var rsa_key: String = Path.builder().root().part(io.get_dir()).part(".rsa").part("private").extension(".key").build().render()
var rsa_pub: String = Path.builder().root().part(io.get_dir()).part(".rsa").part("public").extension(".pub").build().render()

func _ready() -> void:
	io.use_dir(data_dir)
	
