shader_type canvas_item;
render_mode blend_add;

// ============================================================
// 宝箱面板边缘光晕 shader
// 用法：ColorRect 节点尺寸与 treasure_list 一致，锚点对齐
// 冷蓝电光沿矩形边缘流动 + 边框发光
// ============================================================

// 光晕参数
uniform float glow_width   : hint_range(4.0, 40.0) = 16.0;  // 光晕宽度（像素）
uniform float glow_intensity: hint_range(0.0, 3.0) = 1.2;   // 光晕强度
uniform float flow_speed   : hint_range(0.0, 3.0) = 1.0;    // 电光流动速度
uniform float pulse_speed  : hint_range(0.5, 5.0) = 1.5;    // 脉动频率

// 颜色（冷蓝/青色系，匹配背景）
uniform vec4 color_outer : source_color = vec4(0.1, 0.6, 1.0, 1.0);  // 外檐冷蓝
uniform vec4 color_inner : source_color = vec4(0.3, 0.9, 1.0, 1.0);  // 内檐亮青
uniform vec4 color_arc   : source_color = vec4(0.7, 0.95, 1.0, 1.0); // 电光闪白


void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// 矩形边缘距离场：到四条边的距离最小值
	float edge_left   = uv.x;
	float edge_right  = 1.0 - uv.x;
	float edge_top    = uv.y;
	float edge_bottom = 1.0 - uv.y;
	float dist_to_edge = min(min(edge_left, edge_right), min(edge_top, edge_bottom));

	// 光晕：边缘向外渐变
	float glow = 1.0 - smoothstep(0.0, glow_width / 1024.0, dist_to_edge);
	glow = pow(glow, 1.5);

	// 沿边缘流动的电光：用 UV 坐标的线性组合 + TIME 做条纹
	float flow = 0.0;
	// 上边
	if (uv.y < glow_width / 1024.0 / 2.0) {
		flow = sin((uv.x + uv.y) * 40.0 + t * flow_speed * 3.0) * 0.5 + 0.5;
	}
	// 下边
	if (uv.y > 1.0 - glow_width / 1024.0 / 2.0) {
		flow = sin((uv.x - uv.y) * 40.0 + t * flow_speed * 3.0) * 0.5 + 0.5;
	}
	// 左边
	if (uv.x < glow_width / 1024.0 / 2.0) {
		flow = sin((uv.y - uv.x) * 40.0 + t * flow_speed * 3.0) * 0.5 + 0.5;
	}
	// 右边
	if (uv.x > 1.0 - glow_width / 1024.0 / 2.0) {
		flow = sin((uv.y + uv.x) * 40.0 + t * flow_speed * 3.0) * 0.5 + 0.5;
	}
	flow = pow(flow, 3.0);  // 尖锐化

	// 脉动
	float pulse = sin(t * pulse_speed) * 0.3 + 0.7;

	// 颜色混合：边缘用冷蓝，电光用亮青/白
	vec3 glow_color = mix(color_outer.rgb, color_inner.rgb, flow);
	vec3 arc_color  = color_arc.rgb * flow * 0.7;

	// 合成
	vec3 final_color = glow_color * glow * glow_intensity * pulse + arc_color * glow * pulse;
	float alpha = clamp(glow * glow_intensity * pulse + flow * glow * 0.5, 0.0, 0.95);

	COLOR = vec4(final_color, alpha);
}
