shader_type canvas_item;

uniform vec4 color : source_color = vec4(1.0);
uniform float width : hint_range(0, 10) = 2.0;
uniform int pattern : hint_range(0, 2) = 1; // diamond, circle, square
uniform bool inside = false;
uniform bool add_margins = true;

// Glow effect parameters
uniform float glow_strength : hint_range(0.0, 2.0) = 0.6;
uniform float glow_falloff : hint_range(0.1, 4.0) = 2.2;
uniform int glow_samples : hint_range(1, 8) = 3;

varying flat vec4 modulate;

void vertex() {
	modulate = COLOR;

	if (add_margins) {
		VERTEX += (UV * 2.0 - 1.0) * width;
	}
}

bool hasContraryNeighbourAtDistance(vec2 uv, vec2 texture_pixel_size, sampler2D texture, float check_width) {
	for (float i = -ceil(check_width); i <= ceil(check_width); i++) {
		float x = abs(i) > check_width ? check_width * sign(i) : i;
		float offset;

		if (pattern == 0) {
			offset = check_width - abs(x);
		} else if (pattern == 1) {
			offset = floor(sqrt(pow(check_width + 0.5, 2) - x * x));
		} else if (pattern == 2) {
			offset = check_width;
		}

		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			vec2 xy = uv + texture_pixel_size * vec2(x, y);

			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a <= 0.0) == inside) {
				return true;
			}
		}
	}

	return false;
}

void fragment() {
	vec2 uv = UV;

	if (add_margins) {
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(width * 2.0));

		uv = (uv - texture_pixel_size * width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;

		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR.a = 0.0;
		} else {
			COLOR = texture(TEXTURE, uv) * modulate;
		}
	} else {
		COLOR = texture(TEXTURE, uv) * modulate;
	}

	// Check if current pixel is part of sprite or transparent background
	bool is_sprite_pixel = COLOR.a > 0.0;
	float effect_alpha = 0.0;

	// Multi-ring sampling for both tint (sprite pixels) and outline (transparent pixels)
	for (int ring = 1; ring <= glow_samples; ring++) {
		float ring_distance = width * (float(ring) / float(glow_samples));

		// Check if this ring distance has contrary neighbors
		// For sprite pixels: looks for transparent neighbors
		// For transparent pixels: looks for sprite neighbors
		if (hasContraryNeighbourAtDistance(uv, TEXTURE_PIXEL_SIZE, TEXTURE, ring_distance)) {
			// Calculate normalized distance (0.0 at edge, 1.0 at max width)
			float normalized_dist = float(ring) / float(glow_samples);

			// Apply exponential falloff curve for smooth fade
			float ring_alpha = pow(1.0 - normalized_dist, glow_falloff) * glow_strength;

			// Anti-aliasing: interpolate between rings for smoothness
			if (ring > 1) {
				float ring_blend = fract(ring_distance);
				ring_alpha = mix(ring_alpha, ring_alpha * 0.8, ring_blend * 0.3);
			}

			// Accumulate maximum alpha (brightest ring wins)
			effect_alpha = max(effect_alpha, ring_alpha);
		}
	}

	// Apply the appropriate effect based on pixel type
	if (effect_alpha > 0.0) {
		float final_alpha = color.a * effect_alpha * modulate.a;

		if (is_sprite_pixel) {
			// INTERIOR TINT: Blend color into sprite (keeps current tint behavior)
			COLOR.rgb = mix(COLOR.rgb, color.rgb, final_alpha);
			// Keep original sprite alpha (maintains sprite shape)
		} else {
			// EXTERIOR OUTLINE: Draw outline on transparent pixels
			COLOR.rgb = color.rgb;
			COLOR.a = final_alpha;
		}
	}
}
