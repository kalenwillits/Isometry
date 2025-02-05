extends Node

const UNIQUE_KEY_CHAR_SET: String = "abcdefghijklmnopqrstuvwxyz0123456789"

enum RADIALS {
	W,
	NW,
	N,
	NE,
	E,
	SE,
	S,
	SW,
}

class SelfDestructingTimer extends Timer:
	var target: Callable
	
	func arm(lambda: Callable, seconds: float):
		connect("timeout", lambda)
		set("target", target)
		wait_time = seconds
		one_shot = true
		autostart = true

	func trigger():
		target.call()
		queue_free()

func enum_name(enum_type: Object, value: int) -> String:
	return enum_type.get_string_list()[value]

func unique_id() -> String:
	randomize()
	var id = ""
	for n in [8, 4, 4, 4, 12]:
		for _j in range(n):
			id += UNIQUE_KEY_CHAR_SET[randi() % len(UNIQUE_KEY_CHAR_SET)]
		if n != 12:
			id += "-"
	return id

	
func get_region(index: int, columns: int, size: Vector2i) -> Rect2i:
		return Rect2i(Vector2i((index % columns) * size.x, (index / columns) * size.y), size) 
	
func vec2i_from(value) -> Vector2i:
	var vec: Vector2i = Vector2i()
	match typeof(value):
		TYPE_ARRAY:
			if value.size() >= 1:
				if typeof(value[0]) == TYPE_INT or typeof(value[0]) == TYPE_FLOAT:
					vec.x = int(value[0])
			if value.size() >= 2:
				if typeof(value[1]) == TYPE_INT or typeof(value[1]) == TYPE_FLOAT:
					vec.y = int(value[1])
		TYPE_DICTIONARY:
			var x = value.get("x")
			var y = value.get("y")
			if typeof(x) == TYPE_INT or typeof(x) == TYPE_FLOAT:
				vec.x = int(x)
			if typeof(y) == TYPE_INT or typeof(y) == TYPE_FLOAT:
				vec.y = int(y)
	return vec
	
func vec2_from(value) -> Vector2:
	var vec: Vector2 = Vector2()
	match typeof(value):
		TYPE_ARRAY:
			if value.size() >= 1:
				if typeof(value[0]) == TYPE_INT or typeof(value[0]) == TYPE_FLOAT:
					vec.x = float(value[0])
			if value.size() >= 2:
				if typeof(value[1]) == TYPE_INT or typeof(value[1]) == TYPE_FLOAT:
					vec.y = float(value[1])
		TYPE_DICTIONARY:
			var x = value.get("x")
			var y = value.get("y")
			if typeof(x) == TYPE_INT or typeof(x) == TYPE_FLOAT:
				vec.x = float(x)
			if typeof(y) == TYPE_INT or typeof(y) == TYPE_FLOAT:
				vec.y = float(y)
	return vec

func delay(lambda: Callable, seconds: float):
	var timer = SelfDestructingTimer.new()
	timer.arm(lambda, seconds) 
	add_child(timer)
	
func coalesce(arg1=null, arg2=null, arg3=null, arg4=null, arg5=null):
	if arg1 != null:
		return arg1
	elif arg2 != null:
		return arg2
	elif arg3 != null:
		return arg3
	elif arg4 != null:
		return arg4
	elif arg5 != null:
		return arg5
	return null
	
	
func mean(data: Array) -> float:
	var sum: float = 0.0
	var length: float = data.size()
	if length > 0.0:
		for item in data:
			sum += item
		return sum / data.size()
	return 0.0
	
	
func stdev(data: Array) -> float: 
	var length: float = data.size()
	if length > 0:
		var mn: float = mean(data)
		var deviations: Array = []
		for item in data:
			deviations.append(pow(item - mn, 2))
		var sum: float = 0.0
		for item in deviations:
			sum += item
		return sum / length
	return 0.0
	
	
func combine_dicts(dicts: Array) -> Dictionary:
	var result: Dictionary = {}
	for dict in dicts:
		result.merge(dict)
	return result

func is_class_inherited(classname: String, parentclassname: String) -> bool:
	return ClassDB.class_exists(classname) and ClassDB.is_parent_class(classname, parentclassname)

func path(parts: Array[String]) -> String:
	return "/".join(parts.map(func(p): return p.strip_edges("/")))

const NORTH_RADIANS: float = PI / 2.0
const ISOMETRIC_RATIO: float = 2.0

func isometric_factor(radians: float) -> float:
	radians = abs(radians)
	if radians > NORTH_RADIANS:
		radians = NORTH_RADIANS - (radians - NORTH_RADIANS)
	return 1.0 - ((radians / (NORTH_RADIANS) / ISOMETRIC_RATIO))
	
func intersect(array1: Array, array2: Array) -> Array:
	var intersection: Array = []
	for node1 in array1:
		if node1 in array2:
			intersection.append(node1)
	return intersection
	
func is_host_or_server() -> bool:
	return (Cache.network == Network.Mode.HOST) or (Cache.network == Network.Mode.SERVER)
