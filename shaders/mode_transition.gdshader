shader_type canvas_item;
render_mode blend_mix;

/// 翻转切换 shader：Y轴翻转，中间切换到目标图
/// transition 0=原图，1=目标图

uniform sampler2D target_texture : hint_default_white, filter_linear, repeat_disable;
uniform float transition : hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	vec2 uv = UV;

	// 翻转：UV.x 根据 transition 做余弦压缩
	// 0→0.5：cos 从 1→0（面向观众→侧面消失）
	// 0.5→1：cos 从 0→-1（背面→翻回来）
	float flip = cos(transition * PI);

	vec2 new_uv = uv;
	new_uv.x = (uv.x - 0.5) * abs(flip) + 0.5;

	if (transition < 0.5) {
		// 前半段：显示原图，逐渐压扁
		COLOR = texture(TEXTURE, new_uv);
	} else {
		// 后半段：显示目标图，逐渐展开
		COLOR = texture(target_texture, new_uv);
	}
}
