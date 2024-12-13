extends Object
class_name KeyRef

var _key: String

func key() -> String:
	return _key
	
func lookup() -> Entity:
	return Repo.query([key()]).pop_front()
	
static func create(named_key: String) -> KeyRef:
	var key_ref = KeyRef.new()
	key_ref._key = named_key
	return key_ref
