extends Object
class_name ArgParse

static func parse() -> void:
	var args := parse_command_line_args()
	for arg in [
		"uri", 
		"port", 
		"archive", 
		"delay", 
		"network", 
		"dir"
		]:
		Cache.set(arg, args.get(arg))


static func parse_command_line_args() -> Dictionary:
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
