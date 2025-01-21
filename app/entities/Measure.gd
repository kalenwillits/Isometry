extends Entity

var expression: String # Dice

func _ready() -> void:
	tag(Group.MEASURE_ENTITY)
