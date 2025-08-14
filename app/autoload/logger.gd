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
var _log_buffers: Dictionary = {}  # node_path -> Array[LogEntry]
var _file_handles: Dictionary = {}  # node_path -> FileAccess
var _last_log_entries: Dictionary = {}  # node_path -> String (for deduplication)
var _repeat_counts: Dictionary = {}  # node_path -> int
var _session_dir: String = ""
var _logs_dir: String = ""
var _initialized: bool = false
var _write_timer: Timer

class LogEntry:
	var level: Level
	var message: String
	var timestamp: float
	var node_path: String
	
	func _init(p_level: Level, p_message: String, p_node_path: String = ""):
		level = p_level
		message = p_message
		node_path = p_node_path
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
	
	# Create logs directory structure
	_logs_dir = OS.get_executable_path().get_base_dir() + "/logs/"
	if !DirAccess.dir_exists_absolute(_logs_dir):
		DirAccess.make_dir_recursive_absolute(_logs_dir)
	
	# Create session directory
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	_session_dir = _logs_dir + "session-" + timestamp + "/"
	DirAccess.make_dir_recursive_absolute(_session_dir)
	
	# Set up periodic write timer
	_write_timer = Timer.new()
	_write_timer.wait_time = 1.0  # Write every second during idle
	_write_timer.timeout.connect(_flush_all_buffers)
	_write_timer.autostart = true
	add_child(_write_timer)
	
	_initialized = true
	
	# Logger initialized silently

func _should_log(level: Level) -> bool:
	return _level != Level.NONE and level <= _level

func _clean_node_path(node_path: String) -> String:
	if node_path.begins_with("/root/"):
		return node_path.substr(6)  # Remove "/root/" prefix
	return node_path


func _log(level: Level, message: String, node_path: String = "") -> void:
	if not _should_log(level):
		return
		
	if not _initialized:
		_initialize()
	
	# Use provided node path or fallback to script filename
	var caller_path = node_path
	if caller_path == "":
		var stack = get_stack()
		if stack.size() > 1:
			caller_path = stack[1].get("source", "Unknown").get_file().get_basename()
	
	# Create log entry and add to buffer with full message including node path
	var full_message = "[%s] %s" % [caller_path, message]
	var entry = LogEntry.new(level, full_message, caller_path)
	
	if not _log_buffers.has(caller_path):
		_log_buffers[caller_path] = []
	
	_log_buffers[caller_path].append(entry)
	
	# Log only to file, no console output

func _get_log_filename(node_path: String) -> String:
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	return _session_dir + timestamp + ".log"

func _flush_buffer(node_path: String) -> void:
	if not _log_buffers.has(node_path) or _log_buffers[node_path].is_empty():
		return
	
	var filename = _get_log_filename(node_path)
	var file_handle: FileAccess
	
	# Get or create file handle
	if _file_handles.has(node_path):
		file_handle = _file_handles[node_path]
	else:
		file_handle = FileAccess.open(filename, FileAccess.WRITE)
		if file_handle == null:
			push_error("Failed to open log file: %s" % filename)
			return
		_file_handles[node_path] = file_handle
		file_handle.store_line("=== Log Started at %s ===" % Time.get_datetime_string_from_system())
	
	# Process buffer with deduplication
	var buffer = _log_buffers[node_path]
	for entry in buffer:
		var log_line = "[%s][%s] %s" % [
			Time.get_time_string_from_unix_time(entry.timestamp),
			LEVEL_NAMES[entry.level], 
			entry.message
		]
		
		# Handle deduplication
		var last_key = node_path + "_last"
		var count_key = node_path + "_count"
		
		if _last_log_entries.has(last_key) and _last_log_entries[last_key] == log_line:
			_repeat_counts[count_key] = _repeat_counts.get(count_key, 1) + 1
		else:
			# Write any pending repeat count
			if _repeat_counts.has(count_key) and _repeat_counts[count_key] > 1:
				file_handle.store_line("^^^ Previous line repeated %d times" % _repeat_counts[count_key])
				_repeat_counts.erase(count_key)
			
			# Write the new line
			file_handle.store_line(log_line)
			_last_log_entries[last_key] = log_line
	
	file_handle.flush()
	_log_buffers[node_path].clear()

func _flush_all_buffers() -> void:
	for node_path in _log_buffers.keys():
		_flush_buffer(node_path)

func _exit_tree():
	# Flush all remaining logs and close files
	_flush_all_buffers()
	
	for node_path in _file_handles.keys():
		var count_key = node_path + "_count"
		if _repeat_counts.has(count_key) and _repeat_counts[count_key] > 1:
			_file_handles[node_path].store_line("^^^ Previous line repeated %d times" % _repeat_counts[count_key])
		
		_file_handles[node_path].store_line("=== Log Ended at %s ===" % Time.get_datetime_string_from_system())
		_file_handles[node_path].close()
	
	_file_handles.clear()

# Public API methods
func set_level(level: Level) -> void:
	_level = level

func get_level() -> Level:
	return _level

func fatal(message: String, calling_node: Node = null) -> void:
	var node_path = _clean_node_path(calling_node.get_path()) if calling_node else ""
	_log(Level.FATAL, message, node_path)

func error(message: String, calling_node: Node = null) -> void:
	var node_path = _clean_node_path(calling_node.get_path()) if calling_node else ""
	_log(Level.ERROR, message, node_path)

func warn(message: String, calling_node: Node = null) -> void:
	var node_path = _clean_node_path(calling_node.get_path()) if calling_node else ""
	_log(Level.WARN, message, node_path)

func info(message: String, calling_node: Node = null) -> void:
	var node_path = _clean_node_path(calling_node.get_path()) if calling_node else ""
	_log(Level.INFO, message, node_path)

func debug(message: String, calling_node: Node = null) -> void:
	var node_path = _clean_node_path(calling_node.get_path()) if calling_node else ""
	_log(Level.DEBUG, message, node_path)

func trace(message: String, calling_node: Node = null) -> void:
	var node_path = _clean_node_path(calling_node.get_path()) if calling_node else ""
	_log(Level.TRACE, message, node_path)
