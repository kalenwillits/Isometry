extends Node

# System
var cliargs: Dictionary = _parse_command_line_args()

# Launcher fields
var uri: String = "localhost"
var port: int = 5000
var delay: int = 0

# Runtime storage
var network: Network.Mode = cliargs.get("network", "0").to_int()
var archive: String = ""
var dir: String = ""
var textures: Dictionary  # Storage of already loaded textures
var camera_zoom: int = 3

func _parse_command_line_args() -> Dictionary:
	var args = OS.get_cmdline_args()  # Get the command line arguments
	var result = Dictionary()

	for i in range(args.size()):
		var arg = args[i]
		
		if arg.begins_with("--"):  # Handle long-form arguments
			var key = arg.substr(2)  # Remove the "--"
			var value = ""
			# Check for equals sign
			if key.find("=") != -1:
				var parts = key.split("=")
				key = parts[0]
				value = parts[1]
			elif i + 1 < args.size() and not args[i + 1].begins_with("--"):
				value = args[i + 1]
				# Skip the next argument since it’s the value for the current key
				i += 1

			result[key] = value

		elif arg.begins_with("-"):  # Handle single dash arguments
			var key = arg.substr(1)
			result[key] = true  # Treat single dash flags as boolean

	return result
