## Measure Entity
## A calculated value based on dice expressions, associated with an actor.
##
extends Entity

## Dice expression to calculate value (e.g., "2d6+3").
var expression: String
## Icon path for UI display.
var icon: String
## If true, measure is shown on target focus plate when other actors view this actor.
var public: bool
## If true, measure is shown on own data plate.
var private: bool
## Visibility threshold. Measure only visible when value >= reveal. 0 = always visible.
var reveal: int
## Menu entity for interaction options.
var menu: KeyRef # Menu

func _ready() -> void:
	tag(Group.MEASURE_ENTITY)
