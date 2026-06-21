//based on Church motion graphics magnetic array pack, https://shop.churchmotiongraphics.com/pack/mp-magnetic-array

shader_type canvas_item;
uniform vec3 dash_color:source_color;
// Wave settings
uniform vec2 wave_dir = vec2(1.0, 1.0);
uniform float scroll_speed = 1.0;
uniform float wave_count = 2.0;
uniform float aspect = 0.5625;
// Grid settings
uniform float cells_x = 50.0;

// Dash settings
uniform float thickness = 0.2;
uniform float visibility_threshold = 0.1;
uniform float overlap = 0.75;

float dash_shape(vec2 p, float length) {
	vec2 q = abs(p);

	float inside_x = 1.0 - step(length, q.x);
	float inside_y = 1.0 - step(thickness * length, q.y);

	return inside_x * inside_y;
}

float sample_value(vec2 cell, vec2 grid_size, float frequency) {
	vec2 sample_uv = (cell + 0.5) / grid_size;

	float dir = dot(sample_uv, normalize(wave_dir));

	float value = sin(dir * frequency - TIME * scroll_speed);

	value = (value + 1.0) * 0.5;
	value = max(visibility_threshold, value);

	return pow(value, 0.5);
}

void fragment() {
	vec2 grid_size = vec2(
		cells_x,
		cells_x * aspect
	);

	float frequency = wave_count * PI;

	vec2 grid_uv = UV * grid_size;

	vec2 cell = floor(grid_uv);

	// Position in grid-space.
	// Whole numbers correspond to cell boundaries.
	vec2 grid_pos = grid_uv;

	float dash = 0.0;

	// Determine which quadrant of the current cell we're in
	vec2 f = fract(grid_uv);

	int ox0 = (f.x < 0.5) ? -1 : 0;
	int ox1 = ox0 + 1;

	int oy0 = (f.y < 0.5) ? -1 : 0;
	int oy1 = oy0 + 1;

	for (int iy = 0; iy < 2; iy++) {
		for (int ix = 0; ix < 2; ix++) {

			int ox = (ix == 0) ? ox0 : ox1;
			int oy = (iy == 0) ? oy0 : oy1;

			vec2 other_cell = cell + vec2(float(ox), float(oy));

			float value = sample_value(
				other_cell,
				grid_size,
				frequency
			);

			float angle = value * PI * 0.4;

			mat2 rot = mat2(
				vec2(cos(angle), -sin(angle)),
				vec2(sin(angle),  cos(angle))
			);

			// Position relative to this cell center
			vec2 local = grid_pos - (other_cell + 0.5);

			vec2 p = rot * local;

			dash = max(
				dash,
				dash_shape(p, value * overlap)
			);
		}
	}

	COLOR = vec4(vec3(dash)*dash_color, 1.0);
}