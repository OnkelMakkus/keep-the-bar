shader_type spatial;

render_mode cull_front, unshaded, depth_draw_opaque;

uniform float thickness : hint_range(0.0, 0.1) = 0.03;
uniform vec4 outline_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);

void vertex() {
    VERTEX += NORMAL * thickness;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a;
}
