uniform float ellipse_center_x : hint_range(0.0, 1.0) = 0.5; // Ellipse center X (normalized)
uniform float ellipse_center_y : hint_range(0.0, 1.0) = 0.5; // Ellipse center Y (normalized)
uniform float ellipse_width : hint_range(0.0, 1.0) = 0.4; // Ellipse width (normalized)
uniform float ellipse_height : hint_range(0.0, 1.0) = 0.2; // Ellipse height (normalized)
uniform float max_darkness : hint_range(0.0, 1.0) = 0.8; // Maximum darkness outside ellipse
uniform float smoothness : hint_range(0.0, 1.0) = 0.2; // Smoothness of the transition
uniform float gradient_size : hint_range(0.0, 1.0) = 0.1; // Controls the width of the gradient

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE; // Normalize pixel coordinates

    // Shift the coordinates so the ellipse is centered at (ellipse_center_x, ellipse_center_y)
    uv = uv - vec2(ellipse_center_x, ellipse_center_y);

    // Ellipse equation: (x / a)^2 + (y / b)^2 = 1, scaled by width and height
    float dist = pow(uv.x / ellipse_width, 2.0) + pow(uv.y / ellipse_height, 2.0);

    // Calculate the transition (gradient effect)
    // We want the transition to be smooth and we use the gradient_size parameter to control its width.
    float darkness = smoothstep(1.0 - gradient_size, 1.0 + smoothness, dist);

    // Mix between white (inside ellipse) and darkened color (outside ellipse)
    vec3 color = mix(vec3(1.0), vec3(1.0 - max_darkness), darkness);

	float outerRadius = 0.5;
    // Apply the color to the screen
	float x = abs(UV.x-.5)*2.0;
    float y = abs(UV.y-.5)*2.0;
    float v = (sqrt((x*x)+(y*y))/outerRadius);
    COLOR = vec4(0,0,0,v*max_darkness);
}