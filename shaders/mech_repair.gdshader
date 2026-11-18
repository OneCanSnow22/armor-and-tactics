shader_type canvas_item;
render_mode blend_mix;

// ============================================================
// 机甲维修背景 shader
// 主题：电路数据流 + 扫描线 + 冷蓝色调
// ============================================================

// 颜色调色板
uniform vec4 color_cold : source_color = vec4(0.05, 0.18, 0.38, 1.0);   // 深军工蓝
uniform vec4 color_arc  : source_color = vec4(0.2,  0.7,  1.0,  1.0);   // 电弧亮蓝

// 动画参数
uniform float speed         : hint_range(0.1, 3.0)  = 0.8;   // 整体速度
uniform float scan_density  : hint_range(2.0, 30.0) = 10.0;  // 扫描线密度
uniform float scan_speed    : hint_range(0.1, 5.0)  = 1.2;   // 扫描线速度
uniform float circuit_scale : hint_range(1.0, 10.0) = 4.0;   // 电路纹路缩放


// ------ 哈希噪点函数 ------
float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// ------ 2D 值噪点 ------
float value_noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	vec2 u = f * f * (3.0 - 2.0 * f); // smoothstep

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// ------ FBM（分形布朗运动）用于电路纹路 ------
float fbm(vec2 uv) {
	float v = 0.0;
	float amp = 0.5;
	vec2 shift = vec2(100.0);
	for (int i = 0; i < 4; i++) {
		v += amp * value_noise(uv);
		uv = uv * 2.0 + shift;
		amp *= 0.5;
	}
	return v;
}

// ------ 电路线条：对 FBM 取导数模拟走线感 ------
float circuit_lines(vec2 uv, float t) {
	vec2 drift = vec2(t * 0.15, -t * 0.08); // 数据流缓慢漂移
	float n1 = fbm(uv + drift);
	float n2 = fbm(uv + drift + vec2(0.4, 0.7));
	// 两层噪点相减，边缘形成线条感
	float edge = abs(n1 - n2);
	return smoothstep(0.15, 0.0, edge); // 细线
}

// ------ 扫描线 ------
float scan_line(vec2 uv, float t) {
	float scan = sin((uv.y - t * scan_speed) * scan_density * PI * 2.0);
	return scan * 0.5 + 0.5;
}


void fragment() {
	float t = TIME * speed;
	vec2 uv = UV;

	// ---- 1. 基础背景：深蓝渐变 ----
	float vignette = 1.0 - smoothstep(0.3, 0.9, length(uv - vec2(0.5)));
	vec3 base = color_cold.rgb * (0.6 + 0.4 * vignette);

	// ---- 2. 电路纹路层（冷蓝细线） ----
	float circuit = circuit_lines(uv * circuit_scale, t);
	vec3 circuit_color = color_arc.rgb * circuit * 0.4;

	// ---- 3. 扫描线层 ----
	float scan = scan_line(uv, t);
	float scan_fine = scan * 0.06;
	float scan_coarse = sin(uv.y * 3.0 * PI - t * 0.5) * 0.5 + 0.5;
	scan_coarse *= 0.08;

	// ---- 4. 色彩融合 ----
	vec3 final_color = base;
	final_color += circuit_color;
	final_color += vec3(scan_fine + scan_coarse);

	// 整体颜色调制：让冷蓝色随时间轻微脉动
	float color_wave = sin(t * 0.4) * 0.5 + 0.5;
	final_color = mix(final_color, final_color * vec3(0.8, 0.9, 1.2), color_wave * 0.2);

	// 亮度上限保护（避免过曝）
	final_color = clamp(final_color, vec3(0.0), vec3(1.0));

	COLOR = vec4(final_color, 1.0);
}
