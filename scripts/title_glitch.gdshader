shader_type canvas_item;
uniform sampler2D neon_texture : filter_linear;
uniform float neon_amount = 0.0;
uniform float glitch = 0.0;
uniform float elapsed = 0.0;

float noise(float p) { return fract(sin(p * 127.1) * 43758.5453); }

void fragment() {
	float tick = floor(elapsed * 30.0);
	float band = floor(UV.y * 32.0);
	float tear = (noise(band + tick) - 0.5) * step(0.72, noise(band * 3.0 + tick));
	vec2 uv = clamp(UV + vec2(tear * 0.16 * glitch, 0.0), vec2(0.0), vec2(1.0));
	vec2 split = vec2(0.006 * glitch, 0.0);
	vec3 room = texture(TEXTURE, uv).rgb;
	vec3 neon = texture(neon_texture, uv).rgb;
	vec3 color = mix(room, neon, neon_amount);
	color.r = mix(texture(TEXTURE, uv + split).r, texture(neon_texture, uv + split).r, neon_amount);
	color.b = mix(texture(TEXTURE, uv - split).b, texture(neon_texture, uv - split).b, neon_amount);
	color *= 1.0 - glitch * 0.14 * (0.5 + 0.5 * sin(UV.y * 900.0));
	color += vec3(0.06, 0.12, 0.15) * tear * glitch;
	COLOR = vec4(color, 1.0);
}
