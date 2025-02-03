extends Entity

var name_: String
var tilemap: KeyRef # TileMap
var spawns: KeyRefArray # Vertex
var deployments: KeyRefArray # Deployment
var background: KeyRefArray # Parallax
var audio: KeyRefArray # Sound

func _ready() -> void:
	tag(Group.MAP_ENTITY)
