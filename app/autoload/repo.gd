extends Node

func _ready():
	pass 

# TODO - sort
const _entities: Dictionary = {
	"Main": preload("res://entities/Main.gd"),
	"Action": preload("res://entities/Action.gd"),
	"Actor": preload("res://entities/Actor.gd"),
	"Deployment": preload("res://entities/Deployment.gd"),
	"Polygon": preload("res://entities/Polygon.gd"),
	"Sprite": preload("res://entities/Sprite.gd"),
	"TileSet": preload("res://entities/TileSet.gd"),
	"Layer": preload("res://entities/Layer.gd"),
	"Resource": preload("res://entities/Resource.gd"),
	"Tile": preload("res://entities/Tile.gd"),
	"Vertex": preload("res://entities/Vertex.gd"),
	"Animation": preload("res://entities/Animation.gd"),
	"Map": preload("res://entities/Map.gd"),
	"TileMap": preload("res://entities/TileMap.gd"),
	"KeyFrame": preload("res://entities/KeyFrame.gd"),
	"Parameter": preload("res://entities/Parameter.gd"),
	"Condition": preload("res://entities/Condition.gd"),
	"Group": preload("res://entities/Group.gd"),
	"Trigger": preload("res://entities/Trigger.gd"),
	"Timer": preload("res://entities/Timer.gd"),
	"Strategy": preload("res://entities/Strategy.gd"),
	"Skill": preload("res://entities/Skill.gd"),
	"Behavior": preload("res://entities/Behavior.gd"),
	"Measure": preload("res://entities/Measure.gd"),
	"Parallax": preload("res://entities/Parallax.gd"),
	"Sound": preload("res://entities/Sound.gd"),
}

signal load_complete
signal load_failure

func query(tags: Array) -> Array:
	var query_tags: Array = [Group.ENTITY]
	query_tags.append_array(tags)
	var results = Finder.query(query_tags)
	Logger.trace("Repo query for tags %s returned %s results" % [tags, results.size()], self)
	return results
	
func select(key: String) -> Entity:
	var results = query([key])
	if results.size() != 1:
		Logger.warn("Repo select tag: [%s] yielded %s results..." % [key, results.size()], self)
	return results.pop_front()
	
func extract_single_key_from_dict(dict: Dictionary, key_to_keep: String) -> Dictionary:
	var copy := dict.duplicate(true)
	var keys = copy.keys()
	for key in keys:
		if key != key_to_keep:
			copy.erase(key)
	return copy
	
func add_asset_as_entities_to_tree(asset: Dictionary):
	for objtype in asset.keys(): # Loop through named types in asset
		if objtype in _entities.keys(): # Becuase this is user generated content, ensure the type is valid
			for objkey in asset[objtype].keys():
				var objdata: Dictionary = asset[objtype]
				var entity = _entities[objtype].new()
				var params := Entity.FitParams.new()
				params.type = objtype
				params.key = objkey
				params.data = extract_single_key_from_dict(objdata, objkey)
				entity.fit(params)
				if !has_node(entity.unique_node_name()):
					Logger.info("Successfully created Entity: %s" % entity.unique_node_name(), self)
					add_child(entity)
				else:
					Logger.warn("Naming conflict detected in archive: [%s], resolve this or the map will contain missing data on load." % entity.unique_node_name(), self)
		else:
			Logger.warn("Type [%s] is not recognized as a valid type and will be skipped, options are [%s]." % [objtype, _entities.keys()], self)

func load_archive():
	var archive: ZIPReader = ZIPReader.new()
	var path: String = Path.builder()\
		.root()\
		.part(io.get_dir())\
		.part(Cache.dir)\
		.part(Cache.campaign)\
		.extension(".zip")\
		.build()\
		.render()
	if archive.open(path) == OK:	
		var all_assets: Array = archive.get_files()
		archive.close()
		Logger.info("Loading [%s] assets from campaign [%s]..." % [all_assets.size(), path], self)
		for asset_filename in all_assets:
			if asset_filename.ends_with(".json"):
				var asset_key: String = asset_filename.split("/", true, 1)[-1]
				var asset: Dictionary = AssetLoader.builder()\
				.archive(Cache.campaign)\
				.key(asset_key)\
				.type(AssetLoader.Type.OBJECT)\
				.build()\
				.pull()
				add_asset_as_entities_to_tree(asset)
		load_complete.emit.call_deferred()
		return OK
	load_failure.emit()
	return FAILED
