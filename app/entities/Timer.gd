extends Entity

var total: String # Dice
var interval: String # Dice
var action: KeyRef # Action

func _ready() -> void:
	tag(Group.TIMER_ENTITY)
