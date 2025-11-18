extends Node

enum Level {
	NONE,
	FATAL,
	ERROR,
	WARN,
	INFO,
	DEBUG,
	TRACE
}

static var LEVEL_NAMES = {
	Level.NONE: "NONE",
	Level.FATAL: "FATAL",
	Level.ERROR: "ERROR", 
	Level.WARN: "WARN",
	Level.INFO: "INFO",
	Level.DEBUG: "DEBUG",
	Level.TRACE: "TRACE"
}

var _level: Level = Level.NONE
var _log_buffer: Array = []  # Array[LogEntry]
var _file_handle: FileAccess = null
var _log_file_path: String = ""
var _initialized: bool = false
var _write_timer: Timer

class LogEntry:
	var level: Level
	var message: String
	var timestamp: float

	func _init(p_level: Level, p_message: String):
		level = p_level
		message = p_message
		timestamp = Time.get_unix_time_from_system()

func _ready():
	_initialize()

func _initialize():
	if _initialized:
		return

	# Parse command line arguments for log level
	var args = Cache.cliargs
	if args.has("log-level"):
		var level_str = args["log-level"].to_upper()
		for level in LEVEL_NAMES:
			if LEVEL_NAMES[level] == level_str:
				_level = level
				break

	# Set up log file path using io.get_dir()
	_log_file_path = io.get_dir() + "/log.log"

	# Open log file for writing (append mode)
	_file_handle = FileAccess.open(_log_file_path, FileAccess.WRITE)
	if _file_handle == null:
		push_error("Failed to open log file: %s" % _log_file_path)
		return

	_file_handle.store_line("=== Log Started at %s ===" % Time.get_datetime_string_from_system())

	# Set up periodic write timer
	_write_timer = Timer.new()
	_write_timer.wait_time = 1.0  # Write every second during idle
	_write_timer.timeout.connect(_flush_buffer)
	_write_timer.autostart = true
	add_child(_write_timer)

	_initialized = true

	# Logger initialized silently

func _should_log(level: Level) -> bool:
	return _level != Level.NONE and level <= _level

func _log(level: Level, message: String) -> void:
	if not _should_log(level):
		return

	if not _initialized:
		_initialize()

	# Create log entry and add to buffer
	var entry = LogEntry.new(level, message)
	_log_buffer.append(entry)

	# Log only to file, no console output

func _flush_buffer() -> void:
	if _log_buffer.is_empty():
		return

	if _file_handle == null:
		return

	# Write all buffered entries
	for entry in _log_buffer:
		var log_line = "[%s][%s] %s" % [
			Time.get_time_string_from_unix_time(entry.timestamp),
			LEVEL_NAMES[entry.level],
			entry.message
		]
		_file_handle.store_line(log_line)

	_file_handle.flush()
	_log_buffer.clear()

func _exit_tree():
	# Flush all remaining logs and close file
	_flush_buffer()

	if _file_handle != null:
		_file_handle.store_line("=== Log Ended at %s ===" % Time.get_datetime_string_from_system())
		_file_handle.close()
		_file_handle = null

# Public API methods
func set_level(level: Level) -> void:
	_level = level

func get_level() -> Level:
	return _level

func fatal(message: String) -> void:
	_log(Level.FATAL, message)

func error(message: String) -> void:
	_log(Level.ERROR, message)

func warn(message: String) -> void:
	_log(Level.WARN, message)

func info(message: String) -> void:
	_log(Level.INFO, message)

func debug(message: String) -> void:
	_log(Level.DEBUG, message)

func trace(message: String) -> void:
	_log(Level.TRACE, message)
