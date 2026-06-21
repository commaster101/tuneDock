//By LJ (Toast) Hood

shader_type canvas_item;
uniform sampler2D noise1 : repeat_enable;
uniform sampler2D noise2 : repeat_enable;
uniform sampler2D noise3 : repeat_enable;
uniform vec2 direction1;
uniform vec2 direction2;
uniform vec2 direction3;

void fragment() {
	vec4 tex1 = texture(noise1,mod(tan(UV)+(TIME*direction1),vec2(1.0)));
	vec4 tex2 = texture(noise2,mod(tan(UV)+(TIME*direction2),vec2(1.0)));
	vec4 tex3 = texture(noise3,mod(tan(UV)+(TIME*direction3),vec2(1.0)));
	COLOR = (tex1*tex2*tex3)*1.2;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
