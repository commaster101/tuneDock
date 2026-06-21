//based on shader by ejonghyuck on shadertoys https://www.shadertoy.com/view/Xtt3R4
//which itself is based on the ps3 waves background

shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.318, 0.831, 1.0, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.094, 0.141, 0.424, 1.0);
uniform vec4 wave_color : source_color = vec4(0.3, 0.3, 0.3, 1.0);

uniform float width_factor : hint_range(0.1, 5.0) = 1.5;
uniform float speed_multiplier : hint_range(0.0, 5.0) = 1.0;

vec3 calc_sine(
	vec2 uv,
	float speed,
	float frequency,
	float amplitude,
	float shift,
	float offset,
	vec3 color,
	float width,
	float exponent,
	bool dir
) {
	float angle =
		TIME * speed_multiplier * speed * frequency * -1.0 +
		(shift + uv.x) * 2.0;

	float y = sin(angle) * amplitude + offset;
	float diff_y = y - uv.y;

	float dist_y = abs(diff_y);

	if (dir && diff_y > 0.0) {
		dist_y *= 4.0;
	}
	else if (!dir && diff_y < 0.0) {
		dist_y *= 4.0;
	}

	float scale = pow(
		smoothstep(width * width_factor, 0.0, dist_y),
		exponent
	);

	return min(color * scale, color);
}

void fragment() {
	vec2 uv = UV;

	vec3 color = mix(
		bottom_color.rgb,
		top_color.rgb,
		uv.y
	);

	color += calc_sine(
		uv,
		0.2, 0.20, 0.2,
		0.0, 0.5,
		wave_color.rgb,
		0.1, 15.0,
		false
	);

	color += calc_sine(
		uv,
		0.4, 0.40, 0.15,
		0.0, 0.5,
		wave_color.rgb,
		0.1, 17.0,
		false
	);

	color += calc_sine(
		uv,
		0.3, 0.60, 0.15,
		0.0, 0.5,
		wave_color.rgb,
		0.05, 23.0,
		false
	);

	color += calc_sine(
		uv,
		0.1, 0.26, 0.07,
		0.0, 0.3,
		wave_color.rgb,
		0.1, 17.0,
		true
	);

	color += calc_sine(
		uv,
		0.3, 0.36, 0.07,
		0.0, 0.3,
		wave_color.rgb,
		0.1, 17.0,
		true
	);

	color += calc_sine(
		uv,
		0.5, 0.46, 0.07,
		0.0, 0.3,
		wave_color.rgb,
		0.05, 23.0,
		true
	);

	color += calc_sine(
		uv,
		0.2, 0.58, 0.05,
		0.0, 0.3,
		wave_color.rgb,
		0.2, 15.0,
		true
	);

	COLOR = vec4(color, 1.0);
}