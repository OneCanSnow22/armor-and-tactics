shader_type canvas_item;
render_mode blend_mix;

uniform vec4 deep_color : source_color = vec4(0.15, 0.3, 0.65, 1.0);    // 深蓝（暗部）
uniform vec4 mid_color : source_color = vec4(0.3, 0.55, 0.9, 1.0);      // 中蓝（主体）
uniform vec4 bright_color : source_color = vec4(0.6, 0.85, 1.0, 1.0);    // 亮蓝白（高光涌动）
uniform float flow_speed : hint_range(0.2, 3.0, 0.1) = 0.8;
uniform float flow_scale : hint_range(1.0, 8.0, 0.5) = 4.0;
uniform float heartbeat_speed : hint_range(0.4, 2.5, 0.1) = 1.0;
uniform float heart_intensity : hint_range(0.1, 0.8, 0.05) = 0.4;

// 伪随机
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 值噪声
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// FBM 多层噪声
float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	for (int i = 0; i < 5; i++) {
		val += amp * noise(p * freq);
		freq *= 2.1;
		amp *= 0.45;
	}
	return val;
}

// 心跳：双峰曲线，返回 0~1 的调制值
float heartbeat_modulation(float t) {
	float phase = fract(t * heartbeat_speed);
	// 第一峰（重）：周期前 25%
	float beat1 = exp(-phase * 12.0) * 2.0;
	// 第二峰（轻）：延迟 18%
	float beat2 = 0.0;
	if (phase > 0.18) {
		beat2 = exp(-(phase - 0.18) * 14.0) * 1.0;
	}
	return clamp(max(beat1, beat2), 0.0, 1.0);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// 心跳调制：控制颜色融合的"推力"
	float hb = heartbeat_modulation(t);
	float push = 0.5 + hb * heart_intensity; // 0.5~0.9 之间跳动

	// 三层不同速度/方向的流动噪声
	vec2 flow_a = vec2(t * flow_speed * 0.25, t * flow_speed * 0.08);
	vec2 flow_b = vec2(-t * flow_speed * 0.15, t * flow_speed * 0.12);
	vec2 flow_c = vec2(t * flow_speed * 0.05, -t * flow_speed * 0.18);

	float n_a = fbm(uv * flow_scale + flow_a);
	float n_b = fbm(uv * flow_scale * 1.7 + flow_b);
	float n_c = fbm(uv * flow_scale * 0.6 + flow_c);

	// 心跳时噪声位移更大，静息时位移小 → 颜色边界"涨退"
	n_a = fbm((uv + vec2(n_a, n_b) * push * 0.15) * flow_scale + flow_a);

	// 用 n_a 做主色融合，n_b 做副色融合，n_c 控制随机亮斑
	float blend = n_a * (0.7 + n_b * 0.3);

	// 三色融合：深蓝 → 中蓝 → 亮蓝白
	vec4 color;
	if (blend < 0.45) {
		color = mix(deep_color, mid_color, blend / 0.45);
	} else {
		color = mix(mid_color, bright_color, (blend - 0.45) / 0.55);
	}

	// 随机亮斑：某些区域突然闪亮
	float sparkle = smoothstep(0.62, 0.68, n_c);
	color = mix(color, bright_color * 1.2, sparkle * push * 0.4);

	// 从左到右的微妙渐变（左深右浅），增加横向色彩差异
	color = mix(color, color * 1.15, uv.x * 0.3);

	// 保留原始纹理透明度
	float tex_alpha = texture(TEXTURE, uv).a;

	COLOR = vec4(color.rgb, tex_alpha);
}
