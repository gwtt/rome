shader_type canvas_item;


void fragment() {
	vec4 textColor = texture(TEXTURE, UV);
	COLOR.rgba = vec4(1.0, 1.0, 1.0, textColor.a);
}
