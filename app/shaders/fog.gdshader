shader_type canvas_item;

// Actor position and view settings
uniform vec2 actor_position = vec2(0.0, 0.0);
uniform float view_radius : hint_range(0.0, 1000.0) = 100.0;
uniform float fade_distance : hint_range(0.0, 100.0) = 20.0;

// Fog of war tint values (matching Style.gd constants)
uniform float visible_tint : hint_range(0.0, 1.0) = 1.0;      // Style.VISIBLE_TILE_TINT
uniform float discovered_tint : hint_range(0.0, 1.0) = 0.6;   // Style.DISCOVERED_TILE_TINT  
uniform float undiscovered_tint : hint_range(0.0, 1.0) = 0.0; // Style.UNDISCOVERED_TILE_TINT

// Optional: Texture for persistent discovered areas
uniform bool use_discovery_texture = false;
uniform sampler2D discovery_texture : hint_default_black;

// Isometric factor calculation (matches std.gd isometric_factor function)
float isometric_factor(float angle) {
	float abs_angle = abs(angle);
	if (abs_angle <= PI * 0.25 || abs_angle >= PI * 0.75) {
		return 1.0; // East/West movement
	} else {
		return 0.5; // North/South movement (isometric perspective)
	}
}

void fragment() {
	// Get world position of current pixel
	vec2 world_pos = (UV - 0.5) * 2.0 * view_radius + actor_position;
	
	// Calculate distance from actor to this pixel
	vec2 diff = world_pos - actor_position;
	float angle = atan(diff.y, diff.x);
	float raw_distance = length(diff);
	
	// Apply isometric factor to distance calculation
	float distance = raw_distance * isometric_factor(angle);
	
	// Determine visibility state
	bool is_in_view = distance <= view_radius;
	bool is_discovered = false;
	
	// Check discovery texture if enabled
	if (use_discovery_texture) {
		vec4 discovery_sample = texture(discovery_texture, UV);
		is_discovered = discovery_sample.r > 0.5; // Use red channel for discovered state
	}
	
	// Calculate tint based on visibility state
	float tint;
	if (is_in_view) {
		tint = visible_tint;
		// Mark as discovered in current view
		is_discovered = true;
	} else if (is_discovered) {
		tint = discovered_tint;
	} else {
		tint = undiscovered_tint;
	}
	
	// Apply smooth fade at view radius edge
	if (is_in_view && fade_distance > 0.0) {
		float fade_start = view_radius - fade_distance;
		float fade_factor = smoothstep(view_radius, fade_start, distance);
		tint = mix(discovered_tint, visible_tint, fade_factor);
	}
	
	// Apply tint to the original texture
	COLOR = texture(TEXTURE, UV);
	COLOR.rgb *= tint;
	
	// Optional: Write back to discovery texture (requires render target setup)
	// This would need to be handled by the application code
}