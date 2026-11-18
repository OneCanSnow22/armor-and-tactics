// 右侧淡出虚化 shader — 只影响 PanelContainer 自身背景，不影响子节点
// 用法：挂到 PanelContainer 的 Material 属性，调整 fade_width 控制虚化宽度
shader_type canvas_item;

// 虚化宽度（像素），越大淡出区域越宽
uniform float fade_width : hint_range(0.0, 200.0) = 60.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    // 右侧 alpha 渐变：UV.x 接近 1 时淡出
    float alpha = 1.0 - smoothstep(
        1.0 - fade_width * TEXTURE_PIXEL_SIZE.x,
        1.0,
        UV.x
    );
    COLOR = vec4(color.rgb, color.a * alpha);
}
