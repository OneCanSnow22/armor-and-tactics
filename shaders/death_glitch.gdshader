// 死亡雪花屏 shader — intensity 控制噪点密度 (0=完全透明, 1=满屏雪花)
// 用法：给 ColorRect 全屏覆盖，tween material.shader_parameter/intensity 从 0 到 1
shader_type canvas_item;
render_mode unshaded;

// === 噪点密度 (0.0 ~ 1.0) ===
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

// === 噪点缩放 (越小噪点颗粒越大) ===
uniform float noise_scale : hint_range(1.0, 800.0) = 300.0;

// === 闪烁速度 ===
uniform float flicker_speed : hint_range(0.0, 30.0) = 12.0;

// === 最终白屏程度 ===
uniform float whiteout : hint_range(0.0, 1.0) = 0.0;

// 伪随机
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	// 基础噪点
	vec2 uv = UV * noise_scale;
	float noise = hash(uv + fract(TIME * flicker_speed));

	// 大块色块：用低频噪点做不规则色带
	float block = hash(floor(UV * noise_scale * 0.15) + floor(TIME * flicker_speed * 0.3));
	block = step(0.85, block); // 只有15%的区域出现大块

	// 水平线条干扰
	float line = step(0.95, hash(vec2(floor(UV.y * 60.0), floor(TIME * flicker_speed * 0.5))));

	// 合成噪点层
	float glitch = max(noise * intensity, max(block * intensity * 0.7, line * intensity * 0.8));

	// 颜色：黑白噪点 + 偶尔彩色条纹
	vec3 color = vec3(glitch);
	// 彩色条纹
	float color_stripe = hash(vec2(floor(UV.y * 20.0), floor(TIME * 3.0)));
	if (color_stripe > 0.92 && intensity > 0.3) {
		color = vec3(noise * intensity, noise * intensity * 0.3, noise * intensity * 0.8);
	}

	// 白屏：最终阶段整体变白
	color = mix(color, vec3(whiteout), whiteout * 0.8);

	// alpha：噪点存在的地方才有颜色
	float alpha = glitch * (0.6 + 0.4 * intensity);

	COLOR = vec4(color, alpha);
}
