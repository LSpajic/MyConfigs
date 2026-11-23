#version 330
// picom window shader: makes i3's border follow picom's rounded corners.
//
// picom only clips the outside of a rounded window, so i3's square 2px border
// gets thin at each corner and disappears. This shader redraws the border as
// a band that follows the rounded corners, in the window's own border colour
// (read from i3's border on that window), so focused windows keep orange and
// unfocused ones grey.
// No focus-dependent rules are needed.

in vec2 texcoord;
uniform sampler2D tex;
uniform float corner_radius;
uniform float dim;

vec4 default_post_processing(vec4 c);

// must match i3's `default_border pixel 2`
const float BORDER = 2.0;

bool same(vec4 a, vec4 b) {
    return all(lessThan(abs(a - b), vec4(0.02)));
}

vec4 window_shader() {
    ivec2 sz = textureSize(tex, 0);
    vec2 size = vec2(sz);
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    float r = corner_radius;

    if (r > BORDER) {
        ivec2 mid = sz / 2;
        vec4 bl = texelFetch(tex, ivec2(0, mid.y), 0);
        vec4 br = texelFetch(tex, ivec2(sz.x - 1, mid.y), 0);
        vec4 bt = texelFetch(tex, ivec2(mid.x, 0), 0);
        vec4 bi = texelFetch(tex, ivec2(int(BORDER) - 1, mid.y), 0);
        // only when i3 actually drew a border (same colour left, top and right);
        // skips borderless windows, e.g. a lone window with hide_edge_borders.
        // The bottom isn't checked: Firefox paints over i3's bottom border.
        bool bordered = same(bl, br) && same(bl, bt) && same(bl, bi);

        if (bordered) {
            // distance from the rounded outer edge, then redraw the whole
            // BORDER-wide band (straight sides too) in the border colour
            vec2 q = min(texcoord, size - texcoord);
            float e = (q.x < r && q.y < r) ? r - length(vec2(r) - q) : min(q.x, q.y);
            float t = 1.0 - smoothstep(BORDER - 0.5, BORDER + 0.5, e);
            c = mix(c, bl, t);
        }
    }

    c = default_post_processing(c);
    // custom shaders don't get picom's inactive-dim automatically
    c.rgb *= 1.0 - dim;
    return c;
}
