shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque;

uniform sampler2D noise_tex : source_color;  // z.B. Perlin oder GodotNoise512.png
uniform float teleport_t : hint_range(0.0, 1.0) = 0.0; // 0 = da, 1 = weg
uniform float edge_width : hint_range(0.0, 0.5) = 0.08;
uniform vec4 edge_color : source_color = vec4(1.0, 0.7, 0.2, 1.0);
uniform float uv_scale = 3.0;
uniform float scroll_speed = 0.4;

void fragment() {
    vec2 uv = UV * uv_scale + vec2(0.0, TIME * scroll_speed);
    float n = texture(noise_tex, uv).r;

    // Übergangsbereich
    float edge_start = teleport_t - edge_width * 0.5;
    float edge_end   = teleport_t + edge_width * 0.5;
    float mask = smoothstep(edge_start, edge_end, n);

    // Randfarbe (glüht)
    float edge = smoothstep(edge_start, teleport_t, n) - smoothstep(teleport_t, edge_end, n);
    vec3 glow = edge_color.rgb * edge;

    // Sichtbarkeit
    if (n < teleport_t) {
        discard;
    }

    ALBEDO = glow;
    ALPHA = 1.0;
}
