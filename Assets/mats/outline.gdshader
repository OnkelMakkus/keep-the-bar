shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 color : source_color = vec4(1.0, 1.0, 0.2, 0.4); // Weiß
uniform float thickness : hint_range(0.0, 0.05, 0.01) = 0.01;

void vertex() {
    VERTEX += NORMAL * thickness;
}

void fragment() {
    ALBEDO = color.rgb;
    ALPHA = color.a;
}
