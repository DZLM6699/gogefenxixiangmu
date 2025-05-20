shader_type canvas_item;

const float PI = 3.14159265358979323846;

uniform float hue : hint_range(0.0, 1.0);
uniform float alpha : hint_range(0.0, 1.0);
uniform float desaturation : hint_range(0.0, 1.0) = 0.0;

void fragment()
{
    vec4 sprite_color = texture(TEXTURE, UV);
    const vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float radians_hue = 2.0 * PI * hue;
    float cosAngle = cos(radians_hue);
    sprite_color.rgb = vec3(sprite_color.rgb * cosAngle + cross(k, sprite_color.rgb) * sin(radians_hue) + k * dot(k, sprite_color.rgb) * (1.0 - cosAngle));
	
    sprite_color.a *= alpha;
	COLOR = sprite_color;
	
	float grayscale = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(grayscale), desaturation);
}
