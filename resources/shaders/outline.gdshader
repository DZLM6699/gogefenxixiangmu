shader_type canvas_item;
render_mode unshaded;

uniform float width : hint_range(0.0, 16.0) = 3.0;
uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;
uniform vec2 texture_size = vec2(0.0, 0.0);

// uniform arrays are not supported in Godot 3. Shader needs to be adapted for additional outlines
uniform vec4 outline_color_0 : hint_color = vec4(0.0);
uniform vec4 outline_color_1 : hint_color = vec4(0.0);
uniform vec4 outline_color_2 : hint_color = vec4(0.0);
uniform vec4 outline_color_3 : hint_color = vec4(0.0);


float get_neighboring_alpha(sampler2D texture, vec2 uv, vec2 size) {
    vec4 sprite_color = texture(texture, uv);
    float a = sprite_color.a;
	a += texture(texture, uv + vec2(0, size.y)).a;
	a += texture(texture, uv + vec2(size.x, 0)).a;
	a += texture(texture, uv + vec2(0, -size.y)).a;
	a += texture(texture, uv + vec2(-size.x, size.y)).a;
	a += texture(texture, uv + vec2(-size.x, size.y * 0.5)).a;
    a += texture(texture, uv + vec2(-size.x * 0.5, size.y)).a;
	a += texture(texture, uv + vec2(size.x * 0.5, size.y)).a;
	a += texture(texture, uv + vec2(-size.x, -size.y)).a;
	a += texture(texture, uv + vec2(-size.x, -size.y * 0.5)).a;
    a += texture(texture, uv + vec2(-size.x * 0.5, -size.y)).a;
	a += texture(texture, uv + vec2(size.x, -size.y)).a;
	a += texture(texture, uv + vec2(size.x, -size.y * 0.5)).a;
    a += texture(texture, uv + vec2(size.x * 0.5, -size.y)).a;
    a = clamp(a, 0.0, 1.0);
    return a;
}


void draw_outline(int outline_number, vec4 outline_color, sampler2D texture, vec2 uv, inout vec4 color) {
    vec2 size = vec2(width * float(outline_number)) / texture_size;
    float a = get_neighboring_alpha(texture, uv, size);
    vec3 mixed_color = mix(outline_color.rgb, color.rgb, color.a);
    color = vec4(mixed_color, a);
}

void fragment()
{
    vec4 sprite_color = texture(TEXTURE, UV);
    COLOR = sprite_color;
    if (outline_color_0.a > 0.0) {
        draw_outline(1, outline_color_0, TEXTURE, UV, COLOR);
    }
    if (outline_color_1.a > 0.0) {
        draw_outline(2, outline_color_1, TEXTURE, UV, COLOR);
    }
    if (outline_color_2.a > 0.0) {
        draw_outline(3, outline_color_2, TEXTURE, UV, COLOR);
    }
    if (outline_color_3.a > 0.0) {
        draw_outline(4, outline_color_3, TEXTURE, UV, COLOR);
    }

	float grayscale = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(grayscale), desaturation);

	COLOR.a *= alpha;
}