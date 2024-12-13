extends Object
class_name Path

const DELIM: String = "/"

var parts: Array[String] = []
var extension: String = ""
var root: String = ""

class Builder:
	var obj := Path.new()
	
	func root() -> Builder:
		obj.root = DELIM
		return self
	
	func part(value: String) -> Builder:
		if value == null:
			Logger.warn("Building Path with null part [%s]" % value)
		obj.parts.append(value.lstrip(DELIM).rstrip(DELIM))
		return self
		
	func extension(value: String) -> Builder:
		obj.extension = value.lstrip(".")
		return self

	func build() -> Path:
		return obj
		
static func builder() -> Builder:
	return Builder.new()
	
func render() -> String:
	return ("%s%s.%s" % [root, DELIM.join(parts), extension]).rstrip(".")
