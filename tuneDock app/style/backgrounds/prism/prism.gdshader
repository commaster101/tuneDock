//based on shader by evesira on shadertoys https://www.shadertoy.com/view/tffSDr

shader_type canvas_item;
uniform float time_scale = 0.5;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

vec3 palette(float t) {
	vec3 a = vec3(0.5);
	vec3 b = vec3(0.5);
	vec3 c = vec3(1.0);
	vec3 d = vec3(0.1, 0.4, 0.5);

	return a + b * cos(2.0 * PI * (c * t + d));
}

vec4 wave(
	vec2 uv,
	vec4 color,
	float amp,
	float freq,
	float phase,
	float thick,
	vec3 hue
) {
	float x = uv.x - phase;
	float y = uv.y + amp * sin(freq * x);

	float bright = smoothstep(
		0.0,
		1.0,
		1.0 - abs(y) / thick
	);

	return vec4(vec3(bright) * hue, 1.0);
}

void fragment() {
	vec2 coord = FRAGCOORD.xy;

	vec2 uv = (
		2.0 * coord - (1.0/SCREEN_PIXEL_SIZE)
	) / (1.0/SCREEN_PIXEL_SIZE.y);
	
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	if (screen_size.y > screen_size.x) {
		uv = vec2(-uv.y, uv.x);
	}
	vec4 color = vec4(0.0, 0.0, 0.0, 1.0);

	for (float layer = 0.0; layer < 1.0; layer += 0.1) {
		float amp =
			0.25 +
			0.25 * sin((TIME*time_scale) + layer) *
			(1.0 - layer);

		float freq = 2.0;

		float phase =
			(TIME*time_scale) *
			(1.0 - layer);

		float thick =
			0.01 +
			0.001 * pow(abs(uv.x), 8.0);

		vec3 hue = palette(
			0.5 * uv.x +
			1.0 * layer -
			0.5 * (TIME*time_scale)
		);

		color += wave(
			uv,
			color,
			amp,
			freq,
			phase,
			thick,
			hue
		);
	}

	COLOR = color;
}