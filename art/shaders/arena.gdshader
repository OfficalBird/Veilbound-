shader_type canvas_item;
render_mode unshaded;

uniform vec4 mist_color : source_color = vec4(0.35, 0.61, 0.86, 1.0);
uniform float drift = 0.0;
varying vec4 tint;

void vertex() {
    tint = COLOR;
}

void fragment() {
    vec2 uv = UV;
    vec3 stone = texture(TEXTURE, uv).rgb * tint.rgb;
    float edges = smoothstep(0.20, 0.76, length((uv - vec2(0.5, 0.48)) * vec2(1.22, 0.93)));
    float waves = 0.50 + 0.22 * sin(uv.x * 14.0 + drift * 0.35)
                      + 0.19 * sin(uv.x * 31.0 - drift * 0.22);
    float distance_to_mist = (uv.y - 0.67 + 0.025 * sin(uv.x * 8.0 - drift * 0.3)) * 16.0;
    float band = exp(-distance_to_mist * distance_to_mist);
    float mist = band * waves * 0.18;
    vec3 graded = mix(stone * (1.05 - 0.42 * edges), mist_color.rgb, mist);
    COLOR = vec4(graded, 1.0);
}
