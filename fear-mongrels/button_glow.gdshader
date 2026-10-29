shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.396, 0.875, 0.486, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);

    if (strength <= 0.001) {
        COLOR = original;
    } else {
        float close_glow = 0.0;
        float medium_glow = 0.0;
        float far_glow = 0.0;

        for (int i = 0; i < 24; i++) {
            float angle = float(i) * 6.2831853 / 24.0;
            vec2 dir = vec2(cos(angle), sin(angle));

            close_glow = max(
                close_glow,
                texture(TEXTURE, UV + dir * TEXTURE_PIXEL_SIZE * 3.0).a
            );

            medium_glow = max(
                medium_glow,
                texture(TEXTURE, UV + dir * TEXTURE_PIXEL_SIZE * 10.0).a
            );

            far_glow = max(
                far_glow,
                texture(TEXTURE, UV + dir * TEXTURE_PIXEL_SIZE * 24.0).a
            );
        }

        float glow = max(
            close_glow * 0.95,
            max(medium_glow * 0.65, far_glow * 0.3)
        );

        float glow_alpha = max(glow - original.a, 0.0) * strength;

        vec3 final_color = mix(
            glow_color.rgb,
            original.rgb,
            original.a
        );

        float final_alpha = original.a +
            glow_alpha * (1.0 - original.a);

        COLOR = vec4(final_color, final_alpha);
    }
}