extends Node

enum Level {
	NONE,
	INFO,
	DEBUG, 
	WARN,
	ERROR
}

var _data: Array[LogLine] = []

var _level: Level = Level.NONE

class LogLine:
	var level: Level
	var message: String	
	var timestamp: float
	
	class LogLineBuilder:
		var obj: LogLine = LogLine.new()
		
		func level(value: Level) -> LogLineBuilder:
			obj.level = value
			return self
		
		func message(value: String) -> LogLineBuilder:
			obj.message = value
			return self
			
		func build() -> LogLine:
			obj.timestamp = Time.get_unix_time_from_system()
			if OS.is_debug_build() and (Level.size() - Logger.get_level()) >= obj.level:
				match obj.level:
					Level.NONE:
						print(obj.timestamp, " ", obj.level, " ", obj.message)
					Level.INFO:
						print(obj.timestamp, " ", obj.level, " ", obj.message)
					Level.DEBUG:
						print_debug(obj.timestamp, " ", obj.level, " ", obj.message)
					Level.WARN:
						push_warning(obj.timestamp, " ", obj.level, " ", obj.message)
					Level.ERROR:
						push_error(obj.timestamp, " ", obj.level, " ", obj.message)
			return obj

	
	static func builder() -> LogLineBuilder:
		return LogLineBuilder.new()

func set_level(value: Level) -> void:
	_level = value
	
func get_level() -> Level:
	return _level

func info(message: String) -> void:
	_data.append(LogLine
	.builder()
	.level(Level.INFO)
	.message(message)
	.build())

func debug(message: String) -> void:
	_data.append(LogLine
	.builder()
	.level(Level.DEBUG)
	.message(message)
	.build())
	
func warn(message: String) -> void:
	_data.append(LogLine
	.builder()
	.level(Level.WARN)
	.message(message)
	.build())
	
func error(message: String) -> void:
	_data.append(LogLine
	.builder()
	.level(Level.ERROR)
	.message(message)
	.build())
