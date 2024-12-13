extends Entity

var N: Array[int] = []
var NE: Array[int] = []
var E: Array = []
var SE: Array = []
var S: Array = []
var SW: Array = []
var W: Array = []
var NW: Array = []

func _ready() -> void:
	tag(Group.KEYFRAME_ENTITY)
