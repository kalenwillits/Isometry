## Animation Entity
## 8-directional sprite animation with frame data for each direction.
##
extends Entity

## Frame array for north (0°) direction. Default empty.
var N: Array = []
## Frame array for northeast (45°) direction. Default empty.
var NE: Array = []
## Frame array for east (90°) direction. Default empty.
var E: Array = []
## Frame array for southeast (135°) direction. Default empty.
var SE: Array = []
## Frame array for south (180°) direction. Default empty.
var S: Array = []
## Frame array for southwest (225°) direction. Default empty.
var SW: Array = []
## Frame array for west (270°) direction. Default empty.
var W: Array = []
## Frame array for northwest (315°) direction. Default empty.
var NW: Array = []

## Sound entity to play with this animation.
var sound: KeyRef # Sound
## If true, animation repeats continuously.
var loop: bool

func _ready() -> void:
	tag(Group.ANIMATION_ENTITY)
