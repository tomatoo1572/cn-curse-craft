shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;

uniform sampler2D atlas_tex : source_color, filter_nearest;
uniform vec2 atlas_tiles = vec2(8.0, 8.0);
uniform vec2 atlas_size_px = vec2(256.0, 256.0);
uniform float padding_px = 3.0;

void fragment() {
    // Repeat once per block on greedy quads.
    vec2 local_uv = UV - floor(UV); // same as fract(UV) but often behaves nicer

    vec2 tile = UV2; // (tx, ty) – NO Y flip

    vec2 tile_size = 1.0 / atlas_tiles;

    // Pixel padding to avoid bleeding from neighbors/black space
    vec2 pad_uv = vec2(padding_px) / atlas_size_px;

    vec2 uv_in_tile = mix(pad_uv, tile_size - pad_uv, local_uv);
    vec2 uv = tile * tile_size + uv_in_tile;

    // IMPORTANT:
    // Sample LOD 0 explicitly so derivatives from local_uv don't create seams.
    vec4 c = textureLod(atlas_tex, uv, 0.0);

    ALBEDO = c.rgb;
    ALPHA  = c.a;
}
