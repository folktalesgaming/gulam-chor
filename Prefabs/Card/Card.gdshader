shader_type canvas_item;

uniform sampler2D n;
uniform float intensity = 0.0f;
uniform float speed = 1.0f;

void fragment() {
	vec4 tx = texture(TEXTURE, UV);
	vec4 noise = texture(n, UV - TIME / (1.f + speed));
	COLOR.a = clamp(tx.r * noise.r * intensity, 0.f, 1.f);
	COLOR.a = pow(COLOR.a, 2);
}