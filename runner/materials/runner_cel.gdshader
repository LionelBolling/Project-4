shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;

uniform vec4 paint_color : source_color = vec4(1.0);
uniform sampler2D paint_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform bool use_paint_texture = false;
uniform bool flat_painted_detail = false;
uniform float shadow_level : hint_range(0.0, 1.0) = 0.34;
uniform float mid_level : hint_range(0.0, 1.0) = 0.67;
uniform float mid_threshold : hint_range(0.0, 1.0) = 0.40;
uniform float light_threshold : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	vec3 paint = paint_color.rgb;
	if (use_paint_texture) {
		paint *= texture(paint_texture, UV).rgb;
	}
	ALBEDO = paint;
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	EMISSION = paint * (flat_painted_detail ? 1.0 : shadow_level);
}

void light() {
	if (!flat_painted_detail) {
		float illumination = max(dot(NORMAL, LIGHT), 0.0) * ATTENUATION;
		float level = illumination < mid_threshold ? shadow_level : (illumination < light_threshold ? mid_level : 1.0);
		DIFFUSE_LIGHT += max(level - shadow_level, 0.0) * LIGHT_COLOR / PI;
	}
}
