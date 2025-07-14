extends Node

func _ready() -> void:
	add_to_group(Group.INTEFACE)

func set_primary_actor_display_name(value: String) -> void:
	# TODO, set actual interface nodes
	$View/TempLabel.set_text(value)
