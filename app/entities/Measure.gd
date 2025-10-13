extends Entity

var expression: String # Dice
var icon: String
var public: bool
var private: bool
var reveal: int
var menu: KeyRef # Menu

func _ready() -> void:
	tag(Group.MEASURE_ENTITY)
