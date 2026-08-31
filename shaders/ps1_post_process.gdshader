shader_type canvas_item;

// PS1-style color quantization + ordered dithering.
// Applied as a fullscreen pass over the rendered scene.
//
// Note: SCREEN_TEXTURE is sampled with NEAREST filtering. The scene is rendered
// at a low resolution (320x240) and upscaled later; linear filtering between the
// low-res texels makes the pixels soft and causes the image to shimmer as the
// camera moves, so nearest is used to keep each low-res texel crisp and stable.

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float color_levels : hint_range(2.0, 64.0, 1.0) = 24.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.04;
uniform float saturation : hint_range(0.0, 2.0) = 1.15;

// Bayer 4x4 dither matrix (normalized to -0.5..0.5 range).
float bayer4x4(vec2 pos) {
	// 4x4 Bayer matrix values (0-15), normalized to -0.5..+0.5
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int index = x + y * 4;

	// Bayer matrix
	int m0  = 0;  int m1  = 8;  int m2  = 2;  int m3  = 10;
	int m4  = 12; int m5  = 4;  int m6  = 14; int m7  = 6;
	int m8  = 3;  int m9  = 11; int m10 = 1;  int m11 = 9;
	int m12 = 15; int m13 = 7;  int m14 = 13; int m15 = 5;

	int val = m0;
	if (index == 0) val = m0;
	else if (index == 1) val = m1;
	else if (index == 2) val = m2;
	else if (index == 3) val = m3;
	else if (index == 4) val = m4;
	else if (index == 5) val = m5;
	else if (index == 6) val = m6;
	else if (index == 7) val = m7;
	else if (index == 8) val = m8;
	else if (index == 9) val = m9;
	else if (index == 10) val = m10;
	else if (index == 11) val = m11;
	else if (index == 12) val = m12;
	else if (index == 13) val = m13;
	else if (index == 14) val = m14;
	else if (index == 15) val = m15;

	return (float(val) / 15.0) - 0.5;
}

void fragment() {
	vec4 col = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);

	// Gentle saturation lift so colors read richer/warmer while staying natural.
	float luma = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(vec3(luma), col.rgb, saturation);

	// Ordered dithering before quantization for smoother banding. The dither grid
	// is aligned to the LOW-RES scene texels (not the fixed screen grid), so it
	// moves WITH the scene and does not shimmer independently of it.
	vec2 lowres = vec2(textureSize(SCREEN_TEXTURE, 0));
	vec2 scene_px = SCREEN_UV * lowres;
	float dither = bayer4x4(scene_px) * dither_strength;
	col.rgb += dither;

	// Quantize color channels.
	col.rgb = floor(col.rgb * color_levels + 0.5) / color_levels;

	COLOR = col;
}
