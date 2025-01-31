shader_type canvas_item;

uniform float vignette_radius : hint_range(0.0, 1.0) = 0.5;  // Normalized radius of the vignette
uniform float vignette_scale  = 2.0;  // Horizontal scale (x-axis stretch)
uniform float max_darkness : hint_range(0.0, 1.0) = 0.5; // Maximum darkness outside the vignette
uniform float vignette_strength : hint_range(0.0, 1.0) = 1.0; // Strength of the vignette

void fragment() {
    // Get the normalized UV coordinates (from 0 to 1)
    vec2 uv = UV;

    // Calculate the offset from the center of the screen (centered at (0.5, 0.5))
    vec2 offset = (uv - vec2(0.5, 0.5));

    // Scale the offset by the custom x and y scales (keeping a 2:1 aspect ratio or whatever is set)
    vec2 scaled_offset = offset * vec2(vignette_scale, vignette_scale * 2.0);

    // Calculate the elliptical distance (scaled for ellipse aspect ratio)
    float ellipse_factor = dot(scaled_offset, scaled_offset);

    // Calculate the vignette effect with smoothstep for a soft edge
    float vignette = smoothstep(vignette_radius, vignette_radius + 0.05, ellipse_factor);

    // Set the final color with the vignette strength and max darkness
    COLOR = vec4(0.0, 0.0, 0.0, vignette * max_darkness * vignette_strength);
}
