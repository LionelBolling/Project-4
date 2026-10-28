shader_type sky;

uniform vec4 top_color : source_color = vec4(1.0, 0.97, 0.985, 1.0);
uniform vec4 middle_color : source_color = vec4(1.0, 0.84, 0.9, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.92, 0.31, 0.5, 1.0);

void sky() {
	float height = clamp((EYEDIR.y + 1.0) * 0.5, 0.0, 1.0);
	float lower_blend = smoothstep(0.0, 0.6, height);
	float upper_blend = smoothstep(0.4, 1.0, height);
	vec3 lower_to_middle = mix(bottom_color.rgb, middle_color.rgb, lower_blend);
	COLOR = mix(lower_to_middle, top_color.rgb, upper_blend);
}
