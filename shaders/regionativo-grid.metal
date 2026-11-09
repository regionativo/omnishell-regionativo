// Regionativo bar background: a drafting sheet. Paper, faint column grid,
// a strong rule along the bottom edge, and fine ticks along it.
// values: x grid strength (0-1), y column width (pt), z rule weight (pt), w tick strength (0-1).
// Ships at fps 0: drawn once, no ongoing cost.

float4 shade(float2 uv, constant OmniShader& shader) {
    float2 size = max(shader.size, float2(1.0));
    float2 p = uv * size;
    float strength = clamp(shader.values.x, 0.0, 1.0);
    float column = clamp(shader.values.y, 40.0, 240.0);
    float rule = clamp(shader.values.z, 0.0, 3.0);
    float ticks = clamp(shader.values.w, 0.0, 1.0);

    float3 paper = shader.colors[omni_background].rgb;
    float3 ink = shader.colors[omni_foreground].rgb;
    float3 line = shader.colors[omni_border].rgb;
    float3 color = paper;

    // column grid (like the site's A..L columns)
    float gx = step(fmod(p.x, column), 1.0);
    color = mix(color, ink, gx * 0.07 * strength);

    // fine ticks every 8 pt rising from the bottom rule, taller at column lines
    float fromBottom = size.y - p.y;
    float minor = step(fmod(p.x, 8.0), 1.0) * step(fromBottom, rule + 3.0);
    float major = gx * step(fromBottom, rule + 7.0);
    color = mix(color, ink, max(minor * 0.10, major * 0.22) * ticks);

    // the rule
    color = mix(color, line, step(fromBottom, rule));
    return float4(color, 1.0);
}
