shader_type spatial;
render_mode unshaded, blend_mix, cull_back;   // transparent → blend_mix


uniform float dissolve : hint_range(0.0,1.0) = 1.0;
uniform float edge_size : hint_range(0.0,0.4) = 0.08;
uniform vec4  edge_color    = vec4(0.3,0.7,1.0,1.0);
uniform vec4  inner_color   = vec4(0.9,0.9,1.0,0.35);

void fragment() {
	// v = 1 at top, 0 at bottom  (assuming cylinder UV v‐axis)
	float v = UV.y;
	float diff = v - dissolve;          // wie hoch wurde schon “aufgelöst”?
	if (diff < 0.0) discard;            // unterer Teil nicht mehr sichtbar

	ALBEDO  = inner_color.rgb;
	ALPHA   = inner_color.a;

	float rim = smoothstep(0.0, edge_size, diff);
	EMISSION = edge_color.rgb * (1.0 - rim) * 3.0;
}