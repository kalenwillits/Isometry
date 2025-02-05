extends Entity

var N: Array = []
var NE: Array = []
var E: Array = []
var SE: Array = []
var S: Array = []
var SW: Array = []
var W: Array = []
var NW: Array = []

var sound: KeyRef # sound
var loop: bool

func _ready() -> void:
	tag(Group.KEYFRAME_ENTITY)
