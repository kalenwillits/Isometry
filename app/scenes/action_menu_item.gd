extends Button
class_name ActionMenuItem

signal item_clicked(index: int)

var action_entity: Entity
var list_index: int = 0

const ITEM_SIZE: Vector2i = Vector2(256, 24)

func _ready() -> void:
	custom_minimum_size = ITEM_SIZE
	button_up.connect(_on_button_up)

	# Apply setup if data was set before _ready
	if action_entity:
		_apply_setup()

func setup(action_ent: Entity, index: int) -> void:
	action_entity = action_ent
	list_index = index

	set_meta("action_key", action_ent.key())
	set_meta("list_index", index)

	# Apply setup if nodes are ready
	if is_node_ready():
		_apply_setup()

func _apply_setup() -> void:
	text = action_entity.name_

func _on_button_up() -> void:
	item_clicked.emit(list_index)
