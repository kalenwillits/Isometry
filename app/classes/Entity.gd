extends Node
class_name Entity

const KEY_ALIASES: Dictionary = {
	"name": "name_",
	"min": "min_",
	"max": "max_",
	"if": "if_", 
	"else": "else_",
	"range": "range_",
}

var _type: String
var _key: String
var _data: Dictionary
var _tags: Array[String] = []

enum FieldType {
	STANDARD,
	KEYREF,
	KEYREF_ARRAY,
}

class EntityBuilder:
	var obj := Entity.new()

	func type(value: String) -> EntityBuilder:
		obj._type = value
		return self
		
	func key(value: String) -> EntityBuilder:
		obj._key = value
		return self
		
	func data(value: Dictionary) -> EntityBuilder:
		obj._data = value
		return self

	func build() -> Entity:
		for objkey in obj.data()[obj.key()].keys():
			match obj.property_type_map(objkey):
				FieldType.STANDARD:
					obj.set(objkey, obj.data()[obj.key()])
				FieldType.KEYREF:
					obj.set(objkey, KeyRef.create(obj.data()[objkey]))
				FieldType.KEYREF_ARRAY:
					obj.set(objkey, KeyRefArray.create(obj.data()[objkey]))
				_:
					Logger.error("Failed to ingest key to repository %s:%s:%s" % [obj.type(), obj.key(), obj[obj.key()].data()])
		return obj
		
static func builder() -> EntityBuilder:
	return EntityBuilder.new()
	
func _enter_tree() -> void:
	name = unique_node_name()
	tag(key())
	tag(Group.ENTITY)
	
func property_type_map(property_name: String) -> FieldType:
	var properties = get_property_list()
	for property in properties:
		if property.name == property_name:
			if property.class_name == "KeyRef":
				return FieldType.KEYREF
			elif property.class_name == "KeyRefArray":
				return FieldType.KEYREF_ARRAY
	return FieldType.STANDARD

func key() -> String:
	return _key
	
func type() -> String:
	return _type
	
func data():
	return _data

func unique_node_name() -> String:
	return "%s_%s_%s" % [type(), key(), data()[key()].size()]
	
class FitParams:
	var type: String
	var key: String
	var data: Dictionary
	
func fit(params: FitParams) -> void:
	_type = params.type
	_key = params.key
	_data = params.data
	for objkey in data()[key()].keys():
		var alias: String = KEY_ALIASES.get(objkey, objkey)
		match property_type_map(alias):
			FieldType.STANDARD:
				var val = data()[key()][objkey]
				if typeof(val) == TYPE_ARRAY:
					val = val.duplicate(true)
				set(alias, val)
			FieldType.KEYREF:
				set(alias, KeyRef.create(data()[key()][objkey]))
			FieldType.KEYREF_ARRAY:
				set(alias, KeyRefArray.create(data()[key()][objkey]))
			_:
				Logger.error("Failed to ingest key to repository %s:%s:%s" % [type(), key(), data()[key()]])

func tag(value: String) -> void:
	_tags.append(value)
	add_to_group(value)

func has_tag(value: String) -> bool:
	return value in _tags
