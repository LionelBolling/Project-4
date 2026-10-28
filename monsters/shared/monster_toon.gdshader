shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;
uniform vec4 paint_color : source_color = vec4(1.0);
uniform bool flat_painted_detail = false;

void fragment() {
	ALBEDO = paint_color.rgb;
	EMISSION = paint_color.rgb * (flat_painted_detail ? 1.0 : 0.38);
}

void light() {
	if (!flat_painted_detail) {
		float value = max(dot(NORMAL, LIGHT), 0.0) * ATTENUATION;
		float band = value < 0.38 ? 0.38 : (value < 0.80 ? 0.72 : 1.0);
		DIFFUSE_LIGHT += (band - 0.38) * LIGHT_COLOR / PI;
	}
}
