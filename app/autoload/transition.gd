extends CanvasLayer


func _ready() -> void:
	Fader.builder().target($VBoxContainer/HBoxContainer/DarkScreen).build().deploy(self)
	
func at_next_fade(callable: Callable) -> void:
	get_node("Fader").at_next_fade(callable)
	
func at_next_appear(callable: Callable) -> void:
	get_node("Fader").at_next_appear(callable)
	
func fade() -> void:
	get_node("Fader").fade()
	
func appear() -> void:
	get_node("Fader").appear()
