// afterimage.shader
shader_type canvas_item;

uniform float fade_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    COLOR = vec4(color.rgb, color.a * fade_amount);
}