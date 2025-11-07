extends Entity

var name_: String
var floor_: KeyRefArray # Floor
var tilemap: KeyRef # TileMap
var spawn: KeyRef # Vertex
var deployments: KeyRefArray # Deployment
var background: KeyRefArray # Parallax
var audio: KeyRefArray # Sound

func _ready() -> void:
	tag(Group.MAP_ENTITY)
