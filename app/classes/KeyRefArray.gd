extends Object
class_name KeyRefArray

var _keys: Array

func keys() -> Array:
	return _keys
	
func lookup() -> Array:
	var result = []
	for key in keys():
		result.append(Repo.select(key))
	return result
	
static func create(named_keys: Array) -> KeyRefArray:
	var key_ref = KeyRefArray.new()
	key_ref._keys = named_keys
	return key_ref
	
	
